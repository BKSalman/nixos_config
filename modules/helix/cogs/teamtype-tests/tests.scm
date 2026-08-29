
(define failures 0)
(define (check name actual expected)
  (if (equal? actual expected)
      (displayln (string-append "  ok   " name))
      (begin
        (set! failures (+ failures 1))
        (displayln (string-append "  FAIL " name
                                  "\n         got:      " (to-string actual)
                                  "\n         expected: " (to-string expected))))))

(displayln "-- bytevector helpers --")
(check "slice" (bytes->string/utf8 (tt-bytes-slice (string->bytes "hello world") 6 11)) "world")
(check "index-of hit" (tt-bytes-index-of (string->bytes "xxContent-Length: 4") TT-HDR 0) 2)
(check "index-of miss" (tt-bytes-index-of (string->bytes "nope") TT-HDR 0) #f)
(check "separator crlf" (tt-find-separator (string->bytes "12\r\n\r\nbody") 0) '(2 4))
(check "separator lf" (tt-find-separator (string->bytes "12\n\nbody") 0) '(2 2))

(displayln "-- frame parsing --")
(define (frame body) (string-append "Content-Length: "
                                    (number->string (bytes-length (string->bytes body)))
                                    "\r\n\r\n" body))
(set! *tt-buf* (string->bytes (frame "{\"a\":1}")))
(check "single frame" (tt-take-frame!) "{\"a\":1}")
(check "buffer drained" (bytes-length *tt-buf*) 0)

(set! *tt-buf* (string->bytes (string-append (frame "{\"a\":1}") (frame "{\"b\":2}"))))
(check "back-to-back 1" (tt-take-frame!) "{\"a\":1}")
(check "back-to-back 2" (tt-take-frame!) "{\"b\":2}")
(check "back-to-back 3" (tt-take-frame!) #f)

;; A frame split across two reads must not be consumed until it is whole.
(define whole (frame "{\"c\":3}"))
(set! *tt-buf* (string->bytes (substring whole 0 (- (string-length whole) 3))))
(check "partial withheld" (tt-take-frame!) #f)
(set! *tt-buf* (bytes-append *tt-buf* (string->bytes (substring whole (- (string-length whole) 3)))))
(check "partial completed" (tt-take-frame!) "{\"c\":3}")

;; Multi-byte bodies: Content-Length is bytes, our slicing must agree.
(set! *tt-buf* (string->bytes (frame "{\"s\":\"héllo → ü\"}")))
(check "utf8 body" (tt-take-frame!) "{\"s\":\"héllo → ü\"}")

(displayln "-- json decoding conventions --")
(define msg (string->jsexpr "{\"method\":\"edit\",\"params\":{\"revision\":7,\"uri\":\"file:///x\"}}"))
(check "symbol keys" (tt-get msg "method") "edit")
(check "nested" (tt-get (tt-get msg "params") "uri") "file:///x")
(check "float->int" (tt-int (tt-get (tt-get msg "params") "revision")) 7)
(check "missing key" (tt-get msg "nope") #f)

(displayln "-- outgoing json shape --")
(check "int stays int"
       (value->jsexpr-string (hash "uri" "file:///x" "revision" 3))
       "{\"revision\":3,\"uri\":\"file:///x\"}")

(displayln "-- diffing --")
(check "prefix" (tt-common-prefix "abcdef" "abcXef") 3)
(check "suffix" (tt-common-suffix "abcdef" "abcXef" 3) 2)
(check "pure append prefix" (tt-common-prefix "abc" "abcdef") 3)
(check "pure append suffix" (tt-common-suffix "abc" "abcdef" 0) 0)
(check "identical prefix" (tt-common-prefix "abc" "abc") 3)

(displayln "-- position math --")
(define r "one\ntwo\nthree")
(check "char->pos l0" (tt-char->pos r 1) (hash "line" 0 "character" 1))
(check "char->pos l1" (tt-char->pos r 5) (hash "line" 1 "character" 1))
(check "char->pos l2" (tt-char->pos r 10) (hash "line" 2 "character" 2))
;; JSON-decoded positions carry symbol keys...
(check "pos->char roundtrip l1" (tt-pos->char r (hash 'line 1 'character 1)) 5)
(check "pos->char roundtrip l2" (tt-pos->char r (hash 'line 2 'character 2)) 10)
(check "pos->char clamps line" (tt-pos->char r (hash 'line 99 'character 0)) 8)
;; ...positions we build ourselves (tt-char->pos, the inlay hint path) carry
;; string keys, and must round trip through the same accessors.
(check "pos->char string keys" (tt-pos->char r (hash "line" 1 "character" 1)) 5)
(check "char->pos feeds pos->char"
       (tt-pos->char r (tt-char->pos r 10)) 10)

(displayln "-- delta ordering --")
(check "descending by start"
       (map (lambda (x) (list-ref x 0))
            (tt-sort-desc (list (list 3 4 "a") (list 10 12 "b") (list 0 1 "c"))))
       '(10 3 0))

(displayln "-- uri round trip --")
(check "encode" (tt-path->uri "/tmp/a b/c#d.txt") "file:///tmp/a%20b/c%23d.txt")
(check "decode" (tt-uri->path "file:///tmp/a%20b/c%23d.txt") "/tmp/a b/c#d.txt")

(displayln "-- join code detection --")
(check "finds code" (tt-find-join-code "starting\n7-crossover-clockwork\nwaiting") "7-crossover-clockwork")
(check "ignores prose" (tt-find-join-code "hello there\nno code here") #f)

(displayln "-- outgoing edit, on the wire --")
(define sent '())
(set! tt-write-frame! (lambda (body) (set! sent (cons body sent))))
(set! *tt-uri* "file:///w/f.txt")
(set! *tt-doc* 0)
(set! *tt-daemon-rev* 4)
(set! *tt-editor-rev* 0)
(set! *tt-shadow* "hello\nworld\n")
(set! editor->text (lambda (d) "hello\nbrave world\n"))
(tt-flush-outgoing!)
(check "one message sent" (length sent) 1)
(check "edit payload"
       (car sent)
       (string-append
        "{\"jsonrpc\":\"2.0\",\"method\":\"edit\",\"params\":{"
        "\"delta\":[{\"range\":{\"end\":{\"character\":0,\"line\":1},"
        "\"start\":{\"character\":0,\"line\":1}},\"replacement\":\"brave \"}],"
        "\"revision\":4,\"uri\":\"file:///w/f.txt\"}}"))
(check "editor revision advanced" *tt-editor-rev* 1)
(check "shadow adopted" *tt-shadow* "hello\nbrave world\n")

(set! sent '())
(tt-flush-outgoing!)
(check "no-op when unchanged" (length sent) 0)

;; A deletion, to confirm the suffix side of the diff.
(set! *tt-shadow* "abc def ghi")
(set! editor->text (lambda (d) "abc ghi"))
(set! sent '())
(tt-flush-outgoing!)
(check "deletion payload"
       (car sent)
       (string-append
        "{\"jsonrpc\":\"2.0\",\"method\":\"edit\",\"params\":{"
        "\"delta\":[{\"range\":{\"end\":{\"character\":8,\"line\":0},"
        "\"start\":{\"character\":4,\"line\":0}},\"replacement\":\"\"}],"
        "\"revision\":4,\"uri\":\"file:///w/f.txt\"}}"))

(displayln "-- incoming edit, applied to the buffer --")
(define applied '())
(set! helix.static.set-current-selection-object!
      (lambda (s) (set! *sel* s) (set! applied (cons (list "select" (sel-range)) applied))))
(set! helix.static.replace-selection-with
      (lambda (s) (set! applied (cons (list "replace" s) applied))))
(set! helix.static.insert_string
      (lambda (s) (set! applied (cons (list "insert" s) applied))))
(set-cursor! 5 5)

(set! editor->text (lambda (d) "one\ntwo\nthree"))
(set! *tt-editor-rev* 2)
(set! *tt-daemon-rev* 0)
(set! applied '())
(tt-apply-remote-edit!
 (string->jsexpr
  (string-append
   "{\"uri\":\"file:///w/f.txt\",\"revision\":2,\"delta\":["
   "{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":3}},\"replacement\":\"1\"},"
   "{\"range\":{\"start\":{\"line\":2,\"character\":0},\"end\":{\"line\":2,\"character\":5}},\"replacement\":\"3\"}]}")))
;; Ranges refer to the pre-edit text, so the later one must be applied first.
(check "applied back to front"
       (reverse applied)
       (list (list "select" (list 8 13))
             (list "replace" "3")
             (list "select" (list 0 3))
             (list "replace" "1")
             ;; the user's cursor, mapped through the edit rather than restored
             ;; to its stale offset: it sat at 5, and "one" -> "1" above it
             ;; shortens the text by two.
             (list "select" (list 3 3))))
(check "daemon revision advanced" *tt-daemon-rev* 1)

;; A pure insertion has a zero-width range; replace-selection-with is not a
;; reliable insert there, so it must route through insert_string.
(set! applied '())
(set! *tt-editor-rev* 2)
(set-cursor! 6 6)
(tt-apply-remote-edit!
 (string->jsexpr
  (string-append
   "{\"uri\":\"file:///w/f.txt\",\"revision\":2,\"delta\":["
   "{\"range\":{\"start\":{\"line\":1,\"character\":0},\"end\":{\"line\":1,\"character\":0}},\"replacement\":\"X\"}]}")))
;; The cursor sat at 6, one character was inserted at 4, so it must follow to 7.
(check "zero-width range inserts"
       (reverse applied)
       (list (list "select" (list 4 4)) (list "insert" "X") (list "select" (list 7 7))))

;; An edit built against a revision we are no longer on must be dropped; the
;; daemon resends against the current one.
(set! applied '())
(set! *tt-editor-rev* 9)
(define rev-before *tt-daemon-rev*)
(tt-apply-remote-edit!
 (string->jsexpr
  (string-append
   "{\"uri\":\"file:///w/f.txt\",\"revision\":2,\"delta\":["
   "{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":1}},\"replacement\":\"Z\"}]}")))
(check "stale revision dropped" applied '())
(check "stale revision does not advance daemon rev" *tt-daemon-rev* rev-before)

;; So must an edit for a document we do not currently own.
(set! applied '())
(set! *tt-editor-rev* 2)
(tt-apply-remote-edit!
 (string->jsexpr
  (string-append
   "{\"uri\":\"file:///w/other.txt\",\"revision\":2,\"delta\":["
   "{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":1}},\"replacement\":\"Z\"}]}")))
(check "edit for another uri dropped" applied '())

(displayln "-- peer cursors --")
(set! *tt-root* "/w")
(tt-handle-remote-cursor!
 (string->jsexpr
  (string-append
   "{\"userid\":\"u1\",\"name\":\"alice\",\"uri\":\"file:///w/f.txt\","
   "\"ranges\":[{\"start\":{\"line\":3,\"character\":1},\"end\":{\"line\":3,\"character\":4}}]}")))
(check "peer recorded" (hash-length *tt-peers*) 1)
(check "peer line is the moving end" (tt-get (hash-ref *tt-peers* "u1") "line") 3)
(check "peer name" (tt-get (hash-ref *tt-peers* "u1") "name") "alice")
(check "relative path" (tt-relative "/w/src/f.txt") "src/f.txt")



(displayln "-- replay of real daemon output --")
;; A text-mutating buffer double, so the delta is genuinely applied.
(define *buffer* "hello\nDIFFERENT TEXT\n")
(set! editor->text (lambda (d) *buffer*))
(set! helix.static.replace-selection-with
      (lambda (str)
        (set! *buffer* (string-append (substring *buffer* 0 (car (sel-range)))
                                      str
                                      (substring *buffer* (list-ref (sel-range) 1)
                                                 (string-length *buffer*))))))
(set! helix.static.insert_string
      (lambda (str)
        (set! *buffer* (string-append (substring *buffer* 0 (car (sel-range)))
                                      str
                                      (substring *buffer* (car (sel-range))
                                                 (string-length *buffer*))))))

(define open-result 'never-called)
(set! *tt-uri* "file:///tmp/ttpg/file.txt")
(set! *tt-doc* 0)
(set! *tt-editor-rev* 0)
(set! *tt-daemon-rev* 0)
(set! *tt-shadow* "hello\nDIFFERENT TEXT\n")
(set! *tt-pending* (hash 0 (lambda (ok? payload) (set! open-result ok?))))
(set! *tt-buf* captured-frames)

(let loop ()
  (define body (tt-take-frame!))
  (when body (tt-handle-message! body) (loop)))

(check "open acknowledged" open-result #t)
(check "pending request cleared" (hash-length *tt-pending*) 0)
(check "buffer reconciled to the daemon's text" *buffer* "hello\nbrave world\n")
(check "shadow adopted after apply" *tt-shadow* "hello\nbrave world\n")
(check "daemon revision advanced" *tt-daemon-rev* 1)
(check "all frames consumed" (bytes-length *tt-buf*) 0)

(displayln "-- saved-state resync --")
;; The daemon writes the file on every edit, so Helix's buffer goes stale
;; against a disk copy that holds byte-identical content.
(define reloads 0)
(define disk-contents "")
(define doc-dirty #t)
(set! editor-document-reload (lambda (d) (set! reloads (+ reloads 1)) (set! doc-dirty #f)))
(set! editor-document-dirty? (lambda (d) doc-dirty))
(set! tt-read-file (lambda (path) disk-contents))
(set! *tt-doc* 0)
(set! *tt-path* "/w/f.txt")
(set! editor->text (lambda (d) "typed text"))

;; An edit arms the debounce rather than reloading straight away.
(set! *tt-resync-ticks* -1)
(tt-schedule-resync!)
(check "edit arms the debounce" *tt-resync-ticks* TT-RESYNC-DELAY)
(tt-tick-resync!)
(check "does not fire early" reloads 0)

;; Disk has not caught up yet: retry, do not reload.
(set! disk-contents "stale text")
(let loop ([n TT-RESYNC-DELAY]) (when (> n 0) (tt-tick-resync!) (loop (- n 1))))
(check "no reload while disk disagrees" reloads 0)
(check "rearmed for another attempt" *tt-resync-ticks* TT-RESYNC-DELAY)

;; Daemon writes our content out; now the two agree.
(set! disk-contents "typed text")
(let loop ([n (+ 1 TT-RESYNC-DELAY)]) (when (> n 0) (tt-tick-resync!) (loop (- n 1))))
(check "reloads once disk agrees" reloads 1)
(check "debounce goes idle" *tt-resync-ticks* -1)

;; Already clean: nothing to repair, so no reload.
(set! doc-dirty #f)
(tt-schedule-resync!)
(let loop ([n (+ 1 TT-RESYNC-DELAY)]) (when (> n 0) (tt-tick-resync!) (loop (- n 1))))
(check "clean buffer is left alone" reloads 1)

;; Give up rather than reading the file forever when it never converges.
(set! doc-dirty #t)
(set! disk-contents "never matches")
(tt-schedule-resync!)
(let loop ([n (* 3 (* TT-RESYNC-TRIES (+ 1 TT-RESYNC-DELAY)))])
  (when (> n 0) (tt-tick-resync!) (loop (- n 1))))
(check "retries are bounded" *tt-resync-ticks* -1)
(check "still no bogus reload" reloads 1)

;; Opt out restores stock Helix behaviour.
(set! *tt-follow-disk* #f)
(set! disk-contents "typed text")
(tt-schedule-resync!)
(let loop ([n (+ 1 TT-RESYNC-DELAY)]) (when (> n 0) (tt-tick-resync!) (loop (- n 1))))
(check "follow-disk off means no reload" reloads 1)
(set! *tt-follow-disk* #t)

(displayln "-- inlay hint placement --")
(define hint-adds '())
(define hint-removes '())
(define next-hint-id '(10 20))
(set! add-inlay-hint
      (lambda (idx text) (set! hint-adds (cons (list idx text) hint-adds)) next-hint-id))
(set! remove-inlay-hint-by-id
      (lambda (a b) (set! hint-removes (cons (list a b) hint-removes))))
(set! *tt-hints-ok* #t)
(set! *tt-hint-id* #f)
(set! *tt-hints-dirty* #f)
(set! *tt-uri* "file:///w/f.txt")
(set! *tt-doc* 0)
(set! *tt-peers* (hash))

;; alice sits at line 2, character 0.
(tt-handle-remote-cursor!
 (string->jsexpr
  (string-append
   "{\"userid\":\"u1\",\"name\":\"alice\",\"uri\":\"file:///w/f.txt\","
   "\"ranges\":[{\"start\":{\"line\":2,\"character\":0},\"end\":{\"line\":2,\"character\":0}}]}")))
(check "cursor marks hints dirty" *tt-hints-dirty* #t)
(check "but does not refresh immediately" hint-adds '())

(set! editor->text (lambda (d) "a\nb\nPEER\n"))
(tt-tick-hints!)
(check "hint placed at line 2" hint-adds (list (list 4 "▏alice")))
(check "dirty flag cleared" *tt-hints-dirty* #f)
(check "snapshot id retained" *tt-hint-id* '(10 20))

;; Typing two characters on line 0 shifts line 2 along. Recomputing from the
;; peer's (line, character) has to follow it.
(set! hint-adds '())
(set! hint-removes '())
(set! *tt-shadow* "a\nb\nPEER\n")
(set! editor->text (lambda (d) "aXX\nb\nPEER\n"))
(tt-flush-outgoing!)
(check "local edit marks hints dirty" *tt-hints-dirty* #t)
(tt-tick-hints!)
(check "old snapshot removed first" hint-removes (list (list 10 20)))
(check "hint follows the peer's line" hint-adds (list (list 6 "▏alice")))

;; Several invalidations in one tick must collapse into a single rebuild.
(set! hint-adds '())
(tt-invalidate-hints!)
(tt-invalidate-hints!)
(tt-invalidate-hints!)
(tt-tick-hints!)
(check "invalidations coalesce" (length hint-adds) 1)
(set! hint-adds '())
(tt-tick-hints!)
(check "idle tick does no work" hint-adds '())

;; A peer in another file gets no hint here.
(set! hint-adds '())
(set! *tt-peers* (hash))
(tt-handle-remote-cursor!
 (string->jsexpr
  (string-append
   "{\"userid\":\"u2\",\"name\":\"bob\",\"uri\":\"file:///w/other.txt\","
   "\"ranges\":[{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":0}}]}")))
(tt-tick-hints!)
(check "peer in another file is not drawn" hint-adds '())

(displayln "-- debug trace --")
(teamtype-debug! #t)
(check "tracing starts empty" *tt-debug-lines* '())
(tt-debug! (lambda () "one"))
(tt-debug! (lambda () "two"))
(check "collects newest first" *tt-debug-lines* '("two" "one"))
(let loop ([n (* 3 TT-DEBUG-CAP)]) (when (> n 0) (tt-debug! (lambda () "x")) (loop (- n 1))))
(check "trace is bounded" (<= (length *tt-debug-lines*) (* 2 TT-DEBUG-CAP)) #t)
(teamtype-debug! #f)
(tt-debug! (lambda () "ignored"))
(check "off collects nothing" *tt-debug-lines* '())

(displayln "-- cursor ahead of its text (repro) --")
;; Reconstructed from /tmp/tt2/repro: a peer reports (line 5, character 25)
;; while our copy of line 5 is still short, because the cursor notification
;; overtook the edits. The offset must not spill onto line 6.
(define short "l0\nl1\nl2\nl3\nl4\nshortline\nSIXTH\nl7\n")
(define pos-5-25 (hash 'line 5 'character 25))
(define idx (tt-pos->char short pos-5-25))
(check "clamped onto line 5, not line 6" (rope-char->line short idx) 5)
(check "clamped to the end of line 5" idx (- (rope-line->char short 6) 1))

;; Once the text catches up, the same position resolves exactly.
(define full "l0\nl1\nl2\nl3\nl4\nshortline-now-long-enough-x\nSIXTH\nl7\n")
(define idx2 (tt-pos->char full pos-5-25))
(check "exact once the text arrives" (rope-char->line full idx2) 5)
(check "at character 25" (- idx2 (rope-line->char full 5)) 25)

;; The drift the recording showed: as line 5 grows, an unclamped offset walks
;; backwards through line 6. Clamped, the hint stays on line 5 throughout.
(check "no drift while line 5 fills in"
       (map (lambda (pad)
              (rope-char->line (string-append "l0\nl1\nl2\nl3\nl4\n"
                                              (make-string pad #\x)
                                              "\nSIXTH\nl7\n")
                               (tt-pos->char (string-append "l0\nl1\nl2\nl3\nl4\n"
                                                            (make-string pad #\x)
                                                            "\nSIXTH\nl7\n")
                                             pos-5-25)))
            '(5 10 15 20 25 30))
       '(5 5 5 5 5 5))

;; An empty line still resolves to that line.
(define blank "a\n\nc\n")
(check "empty line clamps to itself"
       (rope-char->line blank (tt-pos->char blank (hash 'line 1 'character 9))) 1)
;; And the last line clamps to the end of the document.
(check "last line clamps to document end"
       (tt-pos->char "a\nbb" (hash 'line 1 'character 99)) 4)

(displayln "-- local cursor survives a peer's edit --")
;; A pre-edit offset mapped through a delta. Items are (start end replacement)
;; against the pre-edit text.
(check "insertion above pushes the cursor down"
       (tt-map-offset (list (list 0 0 "hello")) 10) 15)
(check "insertion below leaves it alone"
       (tt-map-offset (list (list 20 20 "hello")) 10) 10)
(check "deletion above pulls it up"
       (tt-map-offset (list (list 0 5 "")) 10) 5)
(check "replacement above shifts by the net change"
       (tt-map-offset (list (list 0 5 "ab")) 10) 7)
;; Matches Helix's own Assoc::After mapping: a peer inserting at your cursor
;; leaves you after their text rather than in front of it.
(check "insertion exactly at the cursor pushes it"
       (tt-map-offset (list (list 10 10 "xy")) 10) 12)
(check "cursor inside a replaced range stays inside"
       (tt-map-offset (list (list 8 16 "abc")) 12) 11)
(check "cursor inside a shrinking range clamps to the replacement"
       (tt-map-offset (list (list 8 16 "a")) 15) 9)
(check "several items accumulate"
       (tt-map-offset (list (list 0 2 "xxxx") (list 5 6 "")) 20) 21)
(check "no items is identity" (tt-map-offset '() 42) 42)

;; End to end through tt-apply-remote-edit!: a peer types above our cursor.
(set! editor->text (lambda (d) "alpha\nbravo\ncharlie\n"))
(set! *tt-uri* "file:///w/f.txt")
(set! *tt-doc* 0)
(set! *tt-editor-rev* 3)
(set-cursor! 14 15)          ;; somewhere in "charlie"
(tt-apply-remote-edit!
 (string->jsexpr
  (string-append
   "{\"uri\":\"file:///w/f.txt\",\"revision\":3,\"delta\":["
   "{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":0}},"
   "\"replacement\":\"NEW\"}]}")))
(check "cursor follows a peer's insertion above it" (sel-range) (list 17 18))

;; Multiple selections and the primary index must survive too.
(set! *tt-editor-rev* 4)
(set! *sel* (list (list (list 2 3) (list 14 15)) 1))
(tt-apply-remote-edit!
 (string->jsexpr
  (string-append
   "{\"uri\":\"file:///w/f.txt\",\"revision\":4,\"delta\":["
   "{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":0}},"
   "\"replacement\":\"XX\"}]}")))
(check "every range is mapped" (list-ref *sel* 0) (list (list 4 5) (list 16 17)))
(check "primary index preserved" (list-ref *sel* 1) 1)

(displayln "-- hint errors are tolerated, not fatal --")
(set! *tt-hints-ok* #t)
(set! *tt-hint-fails* 0)
(set! *tt-hint-id* #f)
(set! *tt-peers* (hash))
(set! *tt-uri* "file:///w/f.txt")
(set! *tt-doc* 0)
(set! editor->text (lambda (d) "a\nb\nPEER\n"))
(tt-handle-remote-cursor!
 (string->jsexpr
  (string-append
   "{\"userid\":\"u1\",\"name\":\"alice\",\"uri\":\"file:///w/f.txt\","
   "\"ranges\":[{\"start\":{\"line\":2,\"character\":0},\"end\":{\"line\":2,\"character\":0}}]}")))

;; One transient failure must not cost the feature for the session.
(set! add-inlay-hint (lambda (idx text) (error "boom")))
(tt-invalidate-hints!)
(tt-tick-hints!)
(check "survives one failure" *tt-hints-ok* #t)
(check "failure counted" *tt-hint-fails* 1)

;; Recovery resets the count.
(set! add-inlay-hint (lambda (idx text) '(10 20)))
(tt-invalidate-hints!)
(tt-tick-hints!)
(check "recovers" *tt-hints-ok* #t)
(check "count reset after a clean refresh" *tt-hint-fails* 0)

;; Persistent failure eventually gives up rather than throwing every tick.
(set! add-inlay-hint (lambda (idx text) (error "boom")))
(let loop ([n TT-HINT-MAX-FAILS])
  (when (> n 0) (tt-invalidate-hints!) (tt-tick-hints!) (loop (- n 1))))
(check "disables after repeated failures" *tt-hints-ok* #f)
(set! add-inlay-hint (lambda (idx text) '(10 20)))
(set! *tt-hints-ok* #t)
(set! *tt-hint-fails* 0)

(displayln "")
(if (= failures 0)
    (displayln "ALL TESTS PASSED")
    (begin (displayln (string-append (number->string failures) " FAILURE(S)"))))
