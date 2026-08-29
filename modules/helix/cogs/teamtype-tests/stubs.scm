;; ---- test doubles for the helix-provided surface -------------------------
(define (log::info! . x) void)
(define (set-status! . x) void)
(define (set-error! . x) void)
(define (set-warning! . x) void)
(define (push-component! . x) void)
(define (picker-selection . x) void)
(define (add-inlay-hint . x) '(0 0))
(define (remove-inlay-hint-by-id . x) void)
(define (enqueue-thread-local-callback-with-delay . x) void)
(define (register-hook . x) void)
(define (doc-closed-id x) x)
(define (editor-focus) 0)
(define (editor->doc-id x) 0)
(define (editor->text x) "")
(define (editor-document->path x) #f)
(define (editor-document-dirty? x) #f)
(define (editor-document-reload x) void)
(define (helix-find-workspace) "/tmp")
;; A selection double, modelled the way Helix's is: a list of (anchor head)
;; ranges plus the index of the primary one.
(define *sel* (list (list (list 0 0)) 0))
(define (helix.static.range a b) (list a b))
(define (helix.static.range->selection r) (list (list r) 0))
(define (helix.static.current-selection-object) *sel*)
(define (helix.static.set-current-selection-object! s) (set! *sel* s))
(define (helix.static.selection->ranges s) (list-ref s 0))
(define (helix.static.selection->primary-index s) (list-ref s 1))
(define (helix.static.push-range-to-selection! r)
  (set! *sel* (list (append (list-ref *sel* 0) (list r)) (list-ref *sel* 1))))
(define (helix.static.set-current-selection-primary-index! i)
  (set! *sel* (list (list-ref *sel* 0) i)))
(define (helix.static.range-anchor r) (list-ref r 0))
(define (helix.static.range-head r) (list-ref r 1))
(define (helix.static.insert_string s) void)
(define (helix.static.replace-selection-with s) void)

;; Convenience for tests: the first range of the current selection.
(define (sel-range) (car (list-ref *sel* 0)))
(define (set-cursor! a h) (set! *sel* (list (list (list a h)) 0)))

;; A rope double: ropes are strings, indices are characters.
(define (string->rope s) s)
(define (rope->string s) s)
(define (rope-len-chars s) (string-length s))
(define (rope-char->line s idx)
  (let loop ([i 0] [line 0])
    (cond [(>= i idx) line]
          [(char=? (string-ref s i) #\newline) (loop (+ i 1) (+ line 1))]
          [else (loop (+ i 1) line)])))
(define (rope-line->char s line)
  (if (= line 0)
      0
      (let loop ([i 0] [seen 0])
        (cond [(>= i (string-length s)) (string-length s)]
              [(char=? (string-ref s i) #\newline)
               (if (= (+ seen 1) line) (+ i 1) (loop (+ i 1) (+ seen 1)))]
              [else (loop (+ i 1) seen)]))))
(define (rope-len-lines s)
  (+ 1 (let loop ([i 0] [n 0])
         (cond [(>= i (string-length s)) n]
               [(char=? (string-ref s i) #\newline) (loop (+ i 1) (+ n 1))]
               [else (loop (+ i 1) n)]))))
;; -------------------------------------------------------------------------
;; steel/process: these names exist in the steel revision Helix embeds, but not
;; in the standalone 0.7.0 used to run these tests, so they are stubbed here.
(define (command . x) 'builder)
(define (with-current-dir . x) 'builder)
(define (with-stdin-piped . x) 'builder)
(define (with-stdout . x) 'builder)
(define (with-stderr . x) 'builder)
(define (spawn-process . x) (Ok 'child))
(define (child-stdin . x) #f)
