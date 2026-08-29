;; teamtype.scm — a Teamtype client for Helix's Steel plugin system.
;;
;; Teamtype (https://github.com/teamtype/teamtype) is peer-to-peer collaborative
;; editing of local files. The daemon (`teamtype share` / `teamtype join`) owns
;; synchronization; editors talk to it over JSON-RPC via `teamtype client`, which
;; forwards Content-Length framed messages to the daemon's unix socket.
;;
;; Protocol reference:
;;   https://teamtype.github.io/teamtype/editor-plugin-dev-guide.html
;;
;; Scope: exactly one document is `open` with the daemon at a time — the focused
;; one. Switching buffers sends `close` then `open`; the daemon reconciles any
;; divergence by sending edits back, so this stays correct rather than merely
;; convenient. Files you are not looking at remain daemon-owned and are updated
;; on disk.

(require-builtin steel/process)
(require-builtin steel/filesystem)
(require-builtin steel/json)
(require "steel/result")
(require-builtin helix/core/text)

(require "helix/editor.scm")
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/misc.scm")
(require "picker.scm")

(provide teamtype-connect
         teamtype-disconnect
         teamtype-status
         teamtype-peers
         teamtype-share
         teamtype-join
         teamtype-tick-interval!
         teamtype-autoconnect!
         teamtype-follow-disk!
         teamtype-debug!
         teamtype-dump-log)

;;;; ---------------------------------------------------------------- state

(define *tt-child* #f)      ;; ChildProcess for `teamtype client`
(define *tt-stdin* #f)      ;; output port -> client stdin
(define *tt-out-port* #f)   ;; input port  <- file the client's stdout is spooled to
(define *tt-out-path* #f)
(define *tt-buf* (bytes))   ;; unparsed bytes of the incoming frame stream

(define *tt-root* #f)       ;; directory containing .teamtype
(define *tt-doc* #f)        ;; doc id currently open with the daemon
(define *tt-uri* #f)        ;; its file:// uri
(define *tt-path* #f)       ;; and its path on disk
(define *tt-shadow* "")     ;; text the daemon and we last agreed on

(define *tt-editor-rev* 0)  ;; edits we have made
(define *tt-daemon-rev* 0)  ;; edits we have received

(define *tt-peers* (hash))  ;; userid -> (hash "name" "uri" "line" "character")
(define *tt-hint-id* #f)      ;; id of the inlay hint snapshot we own, if any
(define *tt-hints-dirty* #f)  ;; peers or buffer moved; hints need recomputing
(define *tt-hints-ok* #t)     ;; cleared only after repeated failures
(define *tt-hint-fails* 0)
(define TT-HINT-MAX-FAILS 10)

(define *tt-running* #f)
(define *tt-interval* 60)   ;; tick period, milliseconds
(define *tt-next-id* 0)
(define *tt-pending* (hash)) ;; request id -> (lambda (ok? payload) ...)
(define *tt-last-cursor* #f)
(define *tt-last-status* "")
(define *tt-autoconnect* #f)
(define *tt-follow-disk* #t)
(define *tt-debug* #f)          ;; in-memory trace, written out by :teamtype-dump-log
(define *tt-debug-lines* '())
(define *tt-debug-count* 0)
(define TT-DEBUG-CAP 600)
(define *tt-resync-ticks* -1)  ;; ticks until the next saved-state resync, -1 = idle
(define *tt-resync-tries* 0)
(define TT-RESYNC-DELAY 5)     ;; ~300ms of quiet before resyncing
(define TT-RESYNC-TRIES 6)

(define (teamtype-tick-interval! ms)
  (set! *tt-interval* ms))

;; Off by default: opening a file should never spawn a process you did not ask
;; for. Turn it on from init.scm with (teamtype-autoconnect! #t).
(define (teamtype-autoconnect! on)
  (set! *tt-autoconnect* on))

;; See `tt-resync-saved-state!`. Turn this off to keep stock Helix behaviour,
;; where the buffer stays marked modified and `:w` needs to be `:w!`.
(define (teamtype-follow-disk! on)
  (set! *tt-follow-disk* on))

;; Kept in memory rather than appended per tick: this traces every hint refresh,
;; so writing it out as it happens would mean file IO inside the tick loop.
(define (teamtype-debug! on)
  (set! *tt-debug* on)
  (set! *tt-debug-lines* '())
  (set! *tt-debug-count* 0)
  (set-status! (if on "teamtype: tracing on" "teamtype: tracing off")))

(define (tt-take lst n)
  (if (or (null? lst) (<= n 0))
      '()
      (cons (car lst) (tt-take (cdr lst) (- n 1)))))

;; Takes a thunk, not a string: with tracing off nothing is built at all, so a
;; trace line can never throw on the hot path. Learned the hard way — a
;; `to-string` inside a trace argument took the whole feature down.
(define (tt-debug! make-line)
  (when *tt-debug*
    (set! *tt-debug-lines* (cons (make-line) *tt-debug-lines*))
    (set! *tt-debug-count* (+ *tt-debug-count* 1))
    (when (> *tt-debug-count* (* 2 TT-DEBUG-CAP))
      (set! *tt-debug-lines* (tt-take *tt-debug-lines* TT-DEBUG-CAP))
      (set! *tt-debug-count* TT-DEBUG-CAP))))

;;;; ---------------------------------------------------------------- utils

(define (tt-log msg)
  (log::info! (string-append "[teamtype] " msg)))

(define (tt-try thunk fallback)
  (with-handler (lambda (err)
                  (tt-log (to-string err))
                  fallback)
                (thunk)))

;; JSON objects decode with *symbol* keys and *float* numbers, while the hashes
;; we build ourselves use string keys. Accept either so position hashes can be
;; passed to the same accessors regardless of where they came from.
(define (tt-get obj key)
  (define (lookup k)
    (if (with-handler (lambda (e) #f) (hash-contains? obj k)) (hash-ref obj k) #f))
  (define found (lookup (string->symbol key)))
  (if found found (lookup key)))

(define (tt-read-file path)
  (tt-try (lambda ()
            (define port (open-input-file path))
            (define contents (read-port-to-string port))
            (close-input-port port)
            contents)
          #f))

(define (tt-schedule-resync!)
  (set! *tt-resync-ticks* TT-RESYNC-DELAY)
  (set! *tt-resync-tries* TT-RESYNC-TRIES))

(define (tt-int x)
  (if (number? x) (exact (round x)) 0))

(define (tt-string x)
  (if (string? x) x ""))

;;;; ------------------------------------------------------------ bytevectors

(define TT-HDR (string->bytes "Content-Length: "))

(define (tt-bytes-slice buf start end)
  (define out (bytes))
  (let loop ([i start])
    (if (< i end)
        (begin
          (bytes-push! out (bytes-ref buf i))
          (loop (+ i 1)))
        out)))

(define (tt-bytes-match? buf at pat)
  (define plen (bytes-length pat))
  (if (> (+ at plen) (bytes-length buf))
      #f
      (let loop ([j 0])
        (cond
          [(= j plen) #t]
          [(= (bytes-ref buf (+ at j)) (bytes-ref pat j)) (loop (+ j 1))]
          [else #f]))))

(define (tt-bytes-index-of buf pat start)
  (define limit (- (bytes-length buf) (bytes-length pat)))
  (let loop ([i start])
    (cond
      [(> i limit) #f]
      [(tt-bytes-match? buf i pat) i]
      [else (loop (+ i 1))])))

;; The header/body separator is CRLFCRLF, but teamtype's own decoder also accepts
;; a bare LFLF to ease manual testing, so accept both. Returns (list end len).
(define (tt-find-separator buf start)
  (define len (bytes-length buf))
  (let loop ([i start])
    (cond
      [(>= i len) #f]
      [(and (< (+ i 3) len)
            (= (bytes-ref buf i) 13)
            (= (bytes-ref buf (+ i 1)) 10)
            (= (bytes-ref buf (+ i 2)) 13)
            (= (bytes-ref buf (+ i 3)) 10))
       (list i 4)]
      [(and (< (+ i 1) len)
            (= (bytes-ref buf i) 10)
            (= (bytes-ref buf (+ i 1)) 10))
       (list i 2)]
      [else (loop (+ i 1))])))

;; Pull one complete frame off *tt-buf*, or #f if none is available yet.
;; Anything before the header is junk and gets discarded, matching how
;; teamtype's own ContentLengthCodec behaves.
(define (tt-take-frame!)
  (define buf *tt-buf*)
  (define hdr (tt-bytes-index-of buf TT-HDR 0))
  (if (not hdr)
      #f
      (let* ([num-start (+ hdr (bytes-length TT-HDR))]
             [sep (tt-find-separator buf num-start)])
        (if (not sep)
            #f
            (let* ([digits-end (list-ref sep 0)]
                   [body-start (+ digits-end (list-ref sep 1))]
                   [n (string->number
                       (bytes->string/utf8 (tt-bytes-slice buf num-start digits-end)))])
              (cond
                [(not n)
                 ;; Unparseable length: drop the bogus header and resynchronize.
                 (set! *tt-buf* (tt-bytes-slice buf body-start (bytes-length buf)))
                 #f]
                [(< (bytes-length buf) (+ body-start n)) #f]
                [else
                 (define body
                   (bytes->string/utf8 (tt-bytes-slice buf body-start (+ body-start n))))
                 (set! *tt-buf*
                       (tt-bytes-slice buf (+ body-start n) (bytes-length buf)))
                 body]))))))

;;;; ------------------------------------------------------------- transport

(define (tt-write-frame! body)
  (when *tt-stdin*
    (define payload (string->bytes body))
    (define header
      (string->bytes
       (string-append "Content-Length: " (number->string (bytes-length payload)) "\r\n\r\n")))
    (write-bytes (bytes-append header payload) *tt-stdin*)
    (flush-output-port *tt-stdin*)))

(define (tt-notify! method params)
  (tt-try (lambda ()
            (tt-write-frame!
             (value->jsexpr-string (hash "jsonrpc" "2.0" "method" method "params" params))))
          void))

;; Requests carry an id so the daemon can report why an `open` was refused
;; (ignored file, outside the share, ...) instead of failing silently.
(define (tt-request! method params callback)
  (define id *tt-next-id*)
  (set! *tt-next-id* (+ id 1))
  (set! *tt-pending* (hash-insert *tt-pending* id callback))
  (tt-try (lambda ()
            (tt-write-frame!
             (value->jsexpr-string
              (hash "jsonrpc" "2.0" "id" id "method" method "params" params))))
          void))

;;;; -------------------------------------------------------------- document

(define (tt-focused-doc)
  (tt-try (lambda () (editor->doc-id (editor-focus))) #f))

(define (tt-doc-text doc-id)
  (rope->string (editor->text doc-id)))

(define (tt-doc-rope doc-id)
  (editor->text doc-id))

(define (tt-encode-path path)
  (~> path
      (string-replace "%" "%25")
      (string-replace " " "%20")
      (string-replace "#" "%23")
      (string-replace "?" "%3F")))

(define (tt-path->uri path)
  (string-append "file://" (tt-encode-path path)))

;; Walk up looking for a .teamtype directory, the way git finds .git.
(define (tt-find-root path)
  (let loop ([dir (tt-try (lambda () (parent-name path)) #f)] [depth 0])
    (cond
      [(> depth 64) #f]
      [(or (not dir) (equal? dir "")) #f]
      [(tt-try (lambda () (is-dir? (string-append dir "/.teamtype"))) #f) dir]
      [else
       (define parent (tt-try (lambda () (parent-name dir)) #f))
       (if (or (not parent) (equal? parent dir)) #f (loop parent (+ depth 1)))])))

(define (tt-doc-path doc-id)
  (tt-try (lambda () (editor-document->path doc-id)) #f))

(define (tt-shared? path)
  (and path *tt-root* (starts-with? path (string-append *tt-root* "/"))))

;;;; -------------------------------------------------------------- positions

(define (tt-char->pos rope idx)
  (define line (rope-char->line rope idx))
  (hash "line" line "character" (- idx (rope-line->char rope line))))

;; `character` must be clamped to the *line*, not just to the document.
;;
;; Cursor notifications and text edits reach us on different channels — cursors
;; are ephemeral state broadcast straight to editors, edits go through the CRDT
;; — so a peer's cursor routinely arrives before the text that made room for it.
;; Clamping only against the document length lets the surplus spill into the
;; following lines: a cursor at (5, 25) reported while our line 5 still holds 14
;; characters lands ten characters into line 6, and creeps back up line 6 as
;; line 5 fills in. Clamping to the line pins it to the peer's own line until
;; the edits catch up.
(define (tt-pos->char rope pos)
  (define nlines (rope-len-lines rope))
  (define line (min (tt-int (tt-get pos "line")) (max 0 (- nlines 1))))
  (define ch (tt-int (tt-get pos "character")))
  (define start (rope-line->char rope line))
  (define line-end
    (if (< (+ line 1) nlines)
        ;; start of the next line, less its newline
        (max start (- (rope-line->char rope (+ line 1)) 1))
        (rope-len-chars rope)))
  (min line-end (+ start ch)))

;;;; --------------------------------------------------- outgoing: text edits

(define (tt-common-prefix a b)
  (define lim (min (string-length a) (string-length b)))
  (let loop ([i 0])
    (if (and (< i lim) (char=? (string-ref a i) (string-ref b i)))
        (loop (+ i 1))
        i)))

(define (tt-common-suffix a b lim)
  (define la (string-length a))
  (define lb (string-length b))
  (let loop ([i 0])
    (if (and (< i lim)
             (char=? (string-ref a (- la i 1)) (string-ref b (- lb i 1))))
        (loop (+ i 1))
        i)))

;; Diff the shadow copy against the live buffer and send the difference as a
;; single-item delta. Deriving edits from a shadow copy rather than from Helix's
;; change events is what keeps our own applied remote edits from echoing back:
;; we refresh the shadow before returning, so the next diff is empty.
(define (tt-flush-outgoing!)
  (when (and *tt-uri* *tt-doc*)
    (define new (tt-try (lambda () (tt-doc-text *tt-doc*)) #f))
    (when (and (string? new) (not (equal? new *tt-shadow*)))
      (define old *tt-shadow*)
      (define lo (string-length old))
      (define ln (string-length new))
      (define p (tt-common-prefix old new))
      (define s (tt-common-suffix old new (min (- lo p) (- ln p))))
      (define old-rope (string->rope old))
      (tt-notify! "edit"
                  (hash "uri" *tt-uri*
                        "revision" *tt-daemon-rev*
                        "delta"
                        (list (hash "range"
                                    (hash "start" (tt-char->pos old-rope p)
                                          "end" (tt-char->pos old-rope (- lo s)))
                                    "replacement" (substring new p (- ln s))))))
      (tt-debug! (lambda ()
                   (string-append "local-edit prefix=" (to-string p)
                                  " suffix=" (to-string s)
                                  " oldlen=" (to-string lo)
                                  " newlen=" (to-string ln))))
      (set! *tt-editor-rev* (+ *tt-editor-rev* 1))
      (set! *tt-shadow* new)
      (tt-schedule-resync!)
      (tt-invalidate-hints!))))

;;;; ----------------------------------------------------- outgoing: cursors

(define (tt-selection-ranges rope)
  (tt-try
   (lambda ()
     (map (lambda (r)
            (hash "start" (tt-char->pos rope (helix.static.range-anchor r))
                  "end" (tt-char->pos rope (helix.static.range-head r))))
          (helix.static.selection->ranges (helix.static.current-selection-object))))
   '()))

(define (tt-flush-cursor!)
  (when (and *tt-uri* *tt-doc*)
    (define ranges (tt-selection-ranges (tt-doc-rope *tt-doc*)))
    (unless (equal? ranges *tt-last-cursor*)
      (set! *tt-last-cursor* ranges)
      (tt-notify! "cursor" (hash "uri" *tt-uri* "ranges" ranges)))))

;;;; ----------------------------------------------------- incoming: dispatch

(define (tt-handle-message! body)
  (define msg (tt-try (lambda () (string->jsexpr body)) #f))
  (when msg
    (define method (tt-get msg "method"))
    (cond
      [(equal? method "edit") (tt-apply-remote-edit! (tt-get msg "params"))]
      [(equal? method "cursor") (tt-handle-remote-cursor! (tt-get msg "params"))]
      [method void]
      [else (tt-handle-response! msg)])))

(define (tt-handle-response! msg)
  (define id (tt-get msg "id"))
  (define err (tt-get msg "error"))
  (when (number? id)
    (define key (tt-int id))
    (when (hash-contains? *tt-pending* key)
      (define cb (hash-ref *tt-pending* key))
      (set! *tt-pending* (hash-remove *tt-pending* key))
      (cb (not err) (if err err (tt-get msg "result")))))
  ;; A parse failure on the daemon side comes back with a null id, so it can
  ;; never be matched to a request. Surface it rather than dropping it.
  (when (and err (not (number? id)))
    (set-error! (string-append "teamtype: " (tt-string (tt-get err "message"))))))

;;;; -------------------------------------------------- incoming: text edits

;; Insertion sort, descending by start offset. Delta ranges all refer to the
;; pre-edit content, so applying them back-to-front keeps earlier offsets valid.
(define (tt-sort-desc items)
  (define (insert x sorted)
    (cond
      [(null? sorted) (list x)]
      [(> (list-ref x 0) (list-ref (car sorted) 0)) (cons x sorted)]
      [else (cons (car sorted) (insert x (cdr sorted)))]))
  (let loop ([rest items] [acc '()])
    (if (null? rest) acc (loop (cdr rest) (insert (car rest) acc)))))

(define (tt-apply-one! start end replacement)
  (helix.static.set-current-selection-object!
   (helix.static.range->selection (helix.static.range start end)))
  (if (= start end)
      ;; replace-selection-with on a zero-width range is not a reliable insert,
      ;; so go through insert_string for the pure-insertion case.
      (unless (equal? replacement "")
        (helix.static.insert_string replacement))
      (helix.static.replace-selection-with replacement)))

;; Map a pre-edit character offset onto its post-edit position.
;;
;; Applying a remote edit means driving Helix's selection to each edit range in
;; turn, which destroys wherever the user's cursor was. Putting the saved
;; selection back verbatim is wrong: it holds absolute offsets from before the
;; edit, so text inserted above the cursor leaves it pointing at the same index
;; into longer text — the cursor slides backwards while someone else types.
;;
;; Delta ranges are non-overlapping and expressed against the pre-edit text, so
;; each one either sits entirely before the offset (shifting it by the change in
;; length), entirely after it (no effect), or contains it (the text under the
;; cursor was replaced, so keep the cursor inside the replacement).
(define (tt-map-offset items x)
  (define container #f)
  (define shift
    (let loop ([rest items] [acc 0])
      (if (null? rest)
          acc
          (let* ([it (car rest)]
                 [s (list-ref it 0)]
                 [e (list-ref it 1)]
                 [r (string-length (list-ref it 2))])
            (cond
              [(<= e x) (loop (cdr rest) (+ acc (- r (- e s))))]
              [(<= x s) (loop (cdr rest) acc)]
              [else
               (set! container (list s r))
               (loop (cdr rest) acc)])))))
  (if container
      (+ (list-ref container 0)
         shift
         (min (- x (list-ref container 0)) (list-ref container 1)))
      (+ x shift)))

;; Selections are captured as plain anchor/head integers rather than as a
;; Selection object, because the object is only meaningful against the text it
;; was taken from.
(define (tt-capture-selection)
  (tt-try (lambda ()
            (define sel (helix.static.current-selection-object))
            (list (map (lambda (r)
                         (list (helix.static.range-anchor r) (helix.static.range-head r)))
                       (helix.static.selection->ranges sel))
                  (helix.static.selection->primary-index sel)))
          #f))

(define (tt-restore-selection! captured items limit)
  (when (and captured (list? (list-ref captured 0)) (not (null? (list-ref captured 0))))
    (tt-try
     (lambda ()
       (define (remap r)
         (helix.static.range (min limit (tt-map-offset items (list-ref r 0)))
                             (min limit (tt-map-offset items (list-ref r 1)))))
       (define ranges (list-ref captured 0))
       (helix.static.set-current-selection-object!
        (helix.static.range->selection (remap (car ranges))))
       (for-each (lambda (r) (helix.static.push-range-to-selection! (remap r)))
                 (cdr ranges))
       (helix.static.set-current-selection-primary-index! (list-ref captured 1)))
     void)))

(define (tt-apply-remote-edit! params)
  (when params
    (define uri (tt-get params "uri"))
    (define revision (tt-int (tt-get params "revision")))
    (cond
      ;; The revision the daemon built this edit against is not the one we are
      ;; on; per the protocol we drop it and wait for the daemon to resend.
      [(not (= revision *tt-editor-rev*))
       (tt-log (string-append "dropping edit for revision "
                              (number->string revision)
                              ", editor is at "
                              (number->string *tt-editor-rev*)))]
      [(not (equal? uri *tt-uri*))
       (tt-log (string-append "dropping edit for unfocused uri " (tt-string uri)))]
      [else
       (define rope (tt-doc-rope *tt-doc*))
       (define delta (tt-get params "delta"))
       (define items
         (tt-sort-desc
          (map (lambda (item)
                 (define range (tt-get item "range"))
                 (list (tt-pos->char rope (tt-get range "start"))
                       (tt-pos->char rope (tt-get range "end"))
                       (tt-string (tt-get item "replacement"))))
               (if (list? delta) delta '()))))
       (define saved (tt-capture-selection))
       (tt-try
        (lambda ()
          (for-each (lambda (item)
                      (tt-apply-one! (list-ref item 0) (list-ref item 1) (list-ref item 2)))
                    items))
        void)
       (tt-restore-selection! saved items (rope-len-chars (tt-doc-rope *tt-doc*)))
       (tt-debug! (lambda ()
                    (string-append "remote-edit items=" (to-string (length items)))))
       (set! *tt-daemon-rev* (+ *tt-daemon-rev* 1))
       ;; Adopt the buffer as the new agreed-upon text so the outgoing diff on
       ;; the next tick does not bounce this edit straight back.
       (set! *tt-shadow* (tt-doc-text *tt-doc*))
       (set! *tt-last-cursor* #f)
       (tt-schedule-resync!)
       (tt-invalidate-hints!)])))

;;;; ---------------------------------------------------- incoming: cursors

(define (tt-relative path)
  (if (and *tt-root* (starts-with? path (string-append *tt-root* "/")))
      (substring path (+ 1 (string-length *tt-root*)))
      path))

(define (tt-uri->path uri)
  (if (starts-with? uri "file://")
      (~> (substring uri 7 (string-length uri))
          (string-replace "%20" " ")
          (string-replace "%23" "#")
          (string-replace "%3F" "?")
          (string-replace "%25" "%"))
      uri))

(define (tt-handle-remote-cursor! params)
  (when params
    (define userid (tt-string (tt-get params "userid")))
    (define name (let ([n (tt-get params "name")]) (if (string? n) n userid)))
    (define uri (tt-string (tt-get params "uri")))
    (define ranges (tt-get params "ranges"))
    (define head (if (and (list? ranges) (not (null? ranges)))
                     (tt-get (car ranges) "end")
                     #f))
    (set! *tt-peers*
          (hash-insert *tt-peers*
                       userid
                       (hash "name" name
                             "uri" uri
                             "line" (if head (tt-int (tt-get head "line")) 0)
                             "character" (if head (tt-int (tt-get head "character")) 0))))
    (define peer (hash-ref *tt-peers* userid))
    (tt-debug! (lambda ()
                 (string-append "cursor peer=" name
                                " line=" (to-string (tt-get peer "line"))
                                " char=" (to-string (tt-get peer "character")))))
    (define status
      (string-append name
                     " — "
                     (tt-relative (tt-uri->path uri))
                     ":"
                     (number->string (+ 1 (tt-get peer "line")))))
    (unless (equal? status *tt-last-status*)
      (set! *tt-last-status* status)
      (set-status! status))
    (tt-invalidate-hints!)))

;;;; ------------------------------------------------------------ inlay hints

;; add-inlay-hint is documented as experimental and slated for removal. Treat a
;; throw as "this build no longer has it" and fall back to the statusline,
;; rather than letting it take text synchronization down with it.
;; A hint is an `InlineAnnotation` pinned to an absolute character index. Helix
;; does remap those through each changeset, but that anchors a hint to a piece
;; of *text*, which is not what a cursor is: a peer's position is (line,
;; character), and the only authoritative source for where that lands is the
;; buffer as it stands right now. Any edit — including one of ours, on a
;; completely different line — makes the previously computed index a guess. So
;; every hint gets recomputed from the peer's line/character rather than left to
;; drift.
(define (tt-invalidate-hints!)
  (set! *tt-hints-dirty* #t))

;; All hints added between two clears share one snapshot id, and clearing
;; installs a fresh empty snapshot with a new id, so a single id is all there is
;; to track. Removal only takes effect while the id still matches the snapshot
;; Helix currently holds.
;; A single throw used to disable hints for the rest of the session, which meant
;; one transient error — a redraw with no focused view, say — silently cost the
;; feature entirely. Tolerate failures and only give up if they keep coming.
(define (tt-hints-failed! err)
  (set! *tt-hint-fails* (+ *tt-hint-fails* 1))
  (tt-log (string-append "inlay hint error ("
                         (to-string *tt-hint-fails*)
                         "): "
                         (to-string err)))
  (when (>= *tt-hint-fails* TT-HINT-MAX-FAILS)
    (set! *tt-hints-ok* #f)
    (tt-log "inlay hints disabled after repeated errors")))

(define (tt-clear-hints!)
  (when (and *tt-hints-ok* *tt-hint-id*)
    (with-handler tt-hints-failed!
                  ;; Its own statement: this has to run whether or not tracing
                  ;; is on, so it must not live inside a trace argument.
                  (remove-inlay-hint-by-id (list-ref *tt-hint-id* 0)
                                           (list-ref *tt-hint-id* 1))
                  (tt-debug! (lambda () (string-append "clear id=" (to-string *tt-hint-id*))))))
  (set! *tt-hint-id* #f))

(define (tt-refresh-hints!)
  (tt-clear-hints!)
  (when (and *tt-hints-ok* *tt-doc* *tt-uri*)
    (with-handler
     tt-hints-failed!
     (let ([rope (tt-doc-rope *tt-doc*)])
       (for-each
        (lambda (userid)
          (define peer (hash-ref *tt-peers* userid))
          (when (equal? (tt-get peer "uri") *tt-uri*)
            (define idx
              (tt-pos->char rope
                            (hash "line" (tt-get peer "line")
                                  "character" (tt-get peer "character"))))
            (define id (add-inlay-hint idx (string-append "▏" (tt-get peer "name"))))
            (tt-debug! (lambda ()
                         (string-append "add peer=" (to-string (tt-get peer "name"))
                                        " line=" (to-string (tt-get peer "line"))
                                        " char=" (to-string (tt-get peer "character"))
                                        " idx=" (to-string idx)
                                        " doclen=" (to-string (rope-len-chars rope))
                                        " id=" (to-string id))))
            ;; Keep the newest id: it is the one that still matches the snapshot.
            (when (list? id) (set! *tt-hint-id* id))))
        (hash-keys->list *tt-peers*))
       ;; Only a refresh that ran to completion clears the failure count.
       (set! *tt-hint-fails* 0)))))

;; Coalesced to once per tick. A burst of cursor notifications, or a fast typist,
;; would otherwise tear down and rebuild the snapshot several times per frame.
(define (tt-tick-hints!)
  (when *tt-hints-dirty*
    (set! *tt-hints-dirty* #f)
    (tt-debug! (lambda ()
                 (string-append "refresh peers=" (to-string (hash-length *tt-peers*))
                                " hints-ok=" (to-string *tt-hints-ok*))))
    (tt-refresh-hints!)))

;;;; ------------------------------------------------- saved-state resync

;; Teamtype's daemon writes the file on *every* edit, whether or not an editor
;; has it open: `ensure_file_has_bytes` in daemon.rs has no ownership check,
;; despite what the file-saving decision record describes. So the file on disk
;; changes under Helix continuously while you type.
;;
;; Helix notices two things and neither is wrong: the buffer is modified
;; relative to its last save, so it shows [+]; and the file's mtime is newer
;; than `last_saved_time`, so `:w` refuses with "file modified by an external
;; process, use :w! to overwrite".
;;
;; But the bytes on disk are exactly what we typed — the daemon wrote our own
;; content back. So once the two agree, `Document::reload` is the right repair:
;; it diffs buffer against disk (an empty transaction, leaving the cursor and
;; the text alone), then calls `reset_modified` and `pickup_last_saved_time`.
;; That clears [+] and lets `:w` work again.
;;
;; Deliberately debounced rather than run every tick: reload re-reads the file,
;; re-detects indentation, and recomputes the git diff base, which is far too
;; much work to do per keystroke.
(define (tt-resync-saved-state!)
  (when (and *tt-follow-disk* *tt-doc* *tt-path*)
    (define on-disk (tt-read-file *tt-path*))
    (define in-buffer (tt-try (lambda () (tt-doc-text *tt-doc*)) #f))
    (cond
      ;; Disk and buffer agree: adopt disk's timestamp and drop the dirty flag.
      [(and (string? on-disk) (equal? on-disk in-buffer))
       (when (tt-try (lambda () (editor-document-dirty? *tt-doc*)) #f)
         (tt-try (lambda () (editor-document-reload *tt-doc*)) void))
       (set! *tt-resync-ticks* -1)]
      ;; Still catching up — the daemon may not have written yet, or there are
      ;; edits in flight. Look again shortly, but do not retry forever.
      [(> *tt-resync-tries* 0)
       (set! *tt-resync-tries* (- *tt-resync-tries* 1))
       (set! *tt-resync-ticks* TT-RESYNC-DELAY)]
      [else (set! *tt-resync-ticks* -1)])))

(define (tt-tick-resync!)
  (when (>= *tt-resync-ticks* 0)
    (set! *tt-resync-ticks* (- *tt-resync-ticks* 1))
    (when (= *tt-resync-ticks* -1)
      (tt-resync-saved-state!))))

;;;; --------------------------------------------------------- open / close

(define (tt-close-current!)
  (when *tt-uri*
    (tt-notify! "close" (hash "uri" *tt-uri*)))
  (tt-clear-hints!)
  (set! *tt-doc* #f)
  (set! *tt-uri* #f)
  (set! *tt-path* #f)
  (set! *tt-shadow* "")
  (set! *tt-last-cursor* #f)
  (set! *tt-resync-ticks* -1))

(define (tt-open! doc-id path)
  ;; The daemon has been writing to this file while it owned it, so start from
  ;; disk unless there is unsaved work to preserve.
  (unless (tt-try (lambda () (editor-document-dirty? doc-id)) #t)
    (tt-try (lambda () (editor-document-reload doc-id)) void))
  (define content (tt-doc-text doc-id))
  (define uri (tt-path->uri path))
  (set! *tt-doc* doc-id)
  (set! *tt-uri* uri)
  (set! *tt-path* path)
  (set! *tt-shadow* content)
  (set! *tt-editor-rev* 0)
  (set! *tt-daemon-rev* 0)
  (set! *tt-last-cursor* #f)
  (tt-request! "open"
               (hash "uri" uri "content" content)
               (lambda (ok? payload)
                 (if ok?
                     (tt-log (string-append "opened " (tt-relative path)))
                     (begin
                       (set-warning!
                        (string-append "teamtype: "
                                       (tt-string (tt-get payload "message"))))
                       (when (equal? *tt-uri* uri) (tt-close-current!)))))))

(define (tt-track-focus!)
  (define doc (tt-focused-doc))
  (unless (equal? doc *tt-doc*)
    ;; Send anything typed since the last tick before giving up ownership,
    ;; otherwise the final keystrokes before a buffer switch are lost.
    (tt-flush-outgoing!)
    (tt-close-current!)
    (define path (and doc (tt-doc-path doc)))
    (when (tt-shared? path)
      (tt-open! doc path))))

;;;; -------------------------------------------------------------- the tick

(define TT-CHUNK 65536)

;; Reads on a regular file never block: at end of file `read-bytes` returns the
;; eof object, and a later read picks up whatever the client has appended since.
;; That is the whole reason the client's stdout is spooled to a file instead of
;; a pipe — a pipe read would stall the editor's main thread.
(define (tt-read-available!)
  (let loop ()
    (define chunk (tt-try (lambda () (read-bytes TT-CHUNK *tt-out-port*)) #f))
    (when (and chunk (bytes? chunk) (> (bytes-length chunk) 0))
      (set! *tt-buf* (bytes-append *tt-buf* chunk))
      (when (= (bytes-length chunk) TT-CHUNK) (loop)))))

(define (tt-drain-incoming!)
  (when *tt-out-port*
    (tt-read-available!)
    (let loop ()
      (define body (tt-take-frame!))
      (when body
        (tt-handle-message! body)
        (loop)))))

;; Everything runs on the main thread inside one callback, so no user input can
;; interleave. Outgoing flushes come first: a local edit must reach the daemon
;; before we fold in a remote one, otherwise adopting the post-apply buffer as
;; the shadow would silently swallow what the user just typed.
(define (tt-tick)
  (when *tt-running*
    (tt-try (lambda ()
              (tt-track-focus!)
              (tt-flush-outgoing!)
              (tt-flush-cursor!)
              (tt-drain-incoming!)
              (tt-tick-hints!)
              (tt-tick-resync!))
            void)
    (enqueue-thread-local-callback-with-delay *tt-interval* tt-tick)))

;;;; -------------------------------------------------------------- commands

;;@doc
;; Connect to the Teamtype daemon sharing the directory the current file lives in.
(define (teamtype-connect)
  (if *tt-running*
      (set-status! "teamtype: already connected")
      (let* ([doc (tt-focused-doc)]
             [path (and doc (tt-doc-path doc))]
             [root (and path (tt-find-root path))])
        (cond
          [(not path) (set-error! "teamtype: no file in the focused view")]
          [(not root)
           (set-error! "teamtype: no .teamtype directory above this file — run `teamtype share` first")]
          [else (tt-start! root)]))))

(define (tt-start! root)
  (define spool (string-append root "/.teamtype/helix-rpc.jsonl"))
  (with-handler
   (lambda (err)
     (set-error! (string-append "teamtype: could not start client: " (to-string err)))
     (tt-stop!))
   (define sink (open-output-file spool))
   ;; stderr must go somewhere other than the terminal, or the client's log
   ;; output paints straight over the TUI.
   (define errsink (open-output-file (string-append root "/.teamtype/helix-client.log")))
   (define child
     (~> (command "teamtype" (list "client"))
         (with-current-dir root)
         with-stdin-piped
         (with-stdout sink)
         (with-stderr errsink)
         spawn-process
         unwrap-ok))
   (set! *tt-root* root)
   (set! *tt-child* child)
   (set! *tt-stdin* (child-stdin child))
   (set! *tt-out-path* spool)
   (set! *tt-out-port* (open-input-file spool))
   (set! *tt-buf* (bytes))
   (set! *tt-peers* (hash))
   (set! *tt-pending* (hash))
   (set! *tt-last-status* "")
   (set! *tt-hints-ok* #t)
   (set! *tt-hint-fails* 0)
   (set! *tt-running* #t)
   (tt-log (string-append "connected to " root))
   (set-status! (string-append "teamtype: connected to " root))
   (enqueue-thread-local-callback-with-delay *tt-interval* tt-tick)))

(define (tt-stop!)
  (set! *tt-running* #f)
  (tt-close-current!)
  ;; Closing stdin is the client's own shutdown path — the forwarder exits when
  ;; its stdin closes — so there is nothing to kill.
  (when *tt-stdin*
    (tt-try (lambda () (close-output-port *tt-stdin*)) void))
  (when *tt-out-port*
    (tt-try (lambda () (close-input-port *tt-out-port*)) void))
  (when *tt-out-path*
    (tt-try (lambda () (delete-file! *tt-out-path*)) void))
  (set! *tt-child* #f)
  (set! *tt-stdin* #f)
  (set! *tt-out-port* #f)
  (set! *tt-out-path* #f)
  (set! *tt-buf* (bytes))
  (set! *tt-peers* (hash))
  (set! *tt-pending* (hash))
  (set! *tt-root* #f))

;;@doc
;; Disconnect from the Teamtype daemon and stop syncing.
(define (teamtype-disconnect)
  (if *tt-running*
      (begin (tt-stop!) (set-status! "teamtype: disconnected"))
      (set-status! "teamtype: not connected")))

(define (teamtype-dump-log)
  (if (null? *tt-debug-lines*)
      (set-status! "teamtype: no trace collected — run :teamtype-debug! first")
      (let ([path (string-append (if *tt-root* *tt-root* "/tmp") "/.teamtype/helix-plugin.log")])
        (with-handler
         (lambda (err) (set-error! (string-append "teamtype: " (to-string err))))
         (define port (open-output-file path))
         ;; Stored newest-first while collecting; write it out in time order.
         (for-each (lambda (line) (display (string-append line "\n") port))
                   (reverse *tt-debug-lines*))
         (flush-output-port port)
         (close-output-port port)
         (set-status! (string-append "teamtype: trace written to " path))))))

;;@doc
;; Show the current Teamtype connection state.
(define (teamtype-status)
  (set-status!
   (if *tt-running*
       (string-append "teamtype: "
                      *tt-root*
                      " | "
                      (if *tt-uri* (tt-relative (tt-uri->path *tt-uri*)) "no shared file focused")
                      " | peers: "
                      (number->string (hash-length *tt-peers*))
                      " | rev "
                      (number->string *tt-editor-rev*)
                      "/"
                      (number->string *tt-daemon-rev*))
       "teamtype: not connected")))

;;@doc
;; List the peers in this session and where their cursors are.
(define (teamtype-peers)
  (define rows
    (map (lambda (userid)
           (define peer (hash-ref *tt-peers* userid))
           (string-append (tt-get peer "name")
                          " — "
                          (tt-relative (tt-uri->path (tt-get peer "uri")))
                          ":"
                          (number->string (+ 1 (tt-get peer "line")))))
         (hash-keys->list *tt-peers*)))
  (if (null? rows)
      (set-status! "teamtype: no peers")
      (push-component! (picker-selection rows (lambda (_) void)))))

;;;; ------------------------------------------------- daemon convenience

;; Running the daemon in its own terminal is the supported path; these just save
;; you a window. Output is spooled to .teamtype/daemon.log so the join code can
;; be surfaced in the statusline once the daemon has printed it.
(define (tt-spawn-daemon! root args label)
  (define log (string-append root "/.teamtype/daemon.log"))
  (with-handler
   (lambda (err) (set-error! (string-append "teamtype: " (to-string err))))
   (create-directory! (string-append root "/.teamtype"))
   (define sink (open-output-file log))
   (~> (command "teamtype" args)
       (with-current-dir root)
       (with-stdout sink)
       (with-stderr sink)
       spawn-process
       unwrap-ok)
   (set-status! (string-append "teamtype: " label " — watching " log))
   (tt-watch-daemon-log! log 0)))

(define (tt-watch-daemon-log! log attempts)
  (when (< attempts 40)
    (enqueue-thread-local-callback-with-delay
     500
     (lambda ()
       (define text (let ([c (tt-read-file log)]) (if c c "")))
       (define code (tt-find-join-code text))
       (if code
           (set-status! (string-append "teamtype join code: " code))
           (tt-watch-daemon-log! log (+ attempts 1)))))))

;; The daemon prints the wormhole code on a line of its own; it is the
;; number-dash-word-dash-word shape that magic-wormhole uses.
(define (tt-find-join-code text)
  (define lines (split-many text "\n"))
  (let loop ([rest lines])
    (cond
      [(null? rest) #f]
      [else
       (define candidate (trim (car rest)))
       (define parts (split-many candidate "-"))
       (if (and (= (length parts) 3)
                (string->number (car parts))
                (> (string-length candidate) 4)
                (not (string-contains? candidate " ")))
           candidate
           (loop (cdr rest)))])))

;;@doc
;; Start `teamtype share` for the current workspace and surface the join code.
(define (teamtype-share)
  (define root (helix-find-workspace))
  (if root
      (tt-spawn-daemon! root (list "share") "sharing")
      (set-error! "teamtype: could not determine the workspace directory")))

;;@doc
;; Start `teamtype join <code>` for the current workspace.
(define (teamtype-join . args)
  (define root (helix-find-workspace))
  (cond
    [(not root) (set-error! "teamtype: could not determine the workspace directory")]
    [(null? args) (set-error! "teamtype: usage — :teamtype-join <join-code>")]
    [else (tt-spawn-daemon! root (list "join" (car args)) "joining")]))

;;;; ----------------------------------------------------------- lifecycle

(register-hook 'document-closed
               (lambda (event)
                 (when (and *tt-doc* (equal? (doc-closed-id event) *tt-doc*))
                   (tt-close-current!))))

(register-hook 'document-opened
               (lambda (doc-id)
                 (when (and *tt-autoconnect* (not *tt-running*))
                   (define root (tt-try (lambda ()
                                          (let ([path (tt-doc-path doc-id)])
                                            (and path (tt-find-root path))))
                                        #f))
                   (when root (tt-start! root)))))
