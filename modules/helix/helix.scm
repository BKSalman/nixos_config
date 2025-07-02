(require "helix/editor.scm")
(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require (prefix-in helix. "helix/components.scm"))
(require (prefix-in helix. "helix/misc.scm"))
(require "package.scm")
(require-builtin helix/core/text)

(load-package "cogs/rainbow-parens.scm")
(load-package "cogs/keymaps.scm")
(require (only-in "cogs/rainbow-parens.scm"
                  toggle-rainbow-parentheses))

(provide shell git-add open-helix-scm open-init-scm list-packages half-page-up half-page-down helix.set-status!)

;;@doc
;; Specialized shell implementation, where % is a wildcard for the current file
(define (shell . args)
  ;; Replace the % with the current file
  (define expanded (map (lambda (x) (if (equal? x "%") (current-path) x)) args))
  (apply helix.run-shell-command expanded))

;;@doc
;; Adds the current file to git
(define (git-add)
  (shell "git" "add" "%"))

(define (current-path)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor-document->path focus-doc-id)))


(define (editor-rope)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor->text focus-doc-id)))

;; @doc
;; Open the helix.scm file
(define (open-helix-scm)
  (helix.open (helix.static.get-helix-scm-path)))

;; @doc
;; Opens the init.scm file
(define (open-init-scm)
  (helix.open (helix.static.get-init-scm-path)))

;; @doc
;; Moves the cursor up by half a page
;; and centers the view on the cursor
; NOTE: This custom behavior is done to match the way vim does `Ctrl-u`
(define (half-page-up)
  (define rect (editor-focused-buffer-area))
  (define current-line (helix.static.get-current-line-number))
  (if rect
      (let ((total-height (- (helix.area-height rect) 1)))
          (define half-height (round (/ total-height 4)))
          (define target-line (max 0 (- current-line half-height 1)))
          (define char-offset (rope-line->char (editor-rope) target-line))
          (define new-selection (helix.static.range->selection (helix.static.range char-offset char-offset)))
          (helix.static.set-current-selection-object! new-selection)
          (helix.static.align_view_center)
          ))
  )

;; Moves the cursor down by half a page
;; and centers the view on the cursor
; NOTE: This custom behavior is done to match the way vim does `Ctrl-u`
(define (half-page-down)
  (define rect (editor-focused-buffer-area))
  (define current-line (helix.static.get-current-line-number))
  (if rect
      (let ((total-height (- (helix.area-height rect) 1)))
          (define half-height (round (/ total-height 4)))
          (define target-line (+ current-line half-height))
          (define editor-rope (editor-rope))
          (define char-offset (rope-line->char editor-rope (min target-line (rope-len-lines editor-rope))))
          (define new-selection (helix.static.range->selection (helix.static.range char-offset char-offset)))
          (helix.static.set-current-selection-object! new-selection)
          (helix.static.align_view_center)
          ))
  )
