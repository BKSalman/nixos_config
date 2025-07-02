;; Required imports for Helix Steel plugin functions
(require "helix/components.scm")
(require "helix/editor.scm")
(require "helix/static.scm") 
(require "helix/misc.scm")
(require "helix/commands.scm")

;; Rainbow Parentheses Implementation for Helix
;; This creates a component that overlays colored parentheses on the buffer

(require-builtin helix/core/text)

(define gutter-width 7)

(struct rainbow-paren (is-on))

;; Export functions for use in other modules
(provide activate-rainbow-parentheses
         toggle-rainbow-parentheses)

;; Define rainbow colors (cycling through these)
(define rainbow-colors
  (list Color/Red
        Color/Yellow
        Color/Green
        Color/Cyan
        Color/Blue
        Color/Magenta
        Color/LightRed
        Color/LightYellow
        Color/LightGreen
        Color/LightCyan
        Color/LightBlue
        Color/LightMagenta))

;; Get color by nesting depth
(define (get-rainbow-color depth)
  (list-ref rainbow-colors (modulo depth (length rainbow-colors))))

;; Check if character is an opening paren
(define (opening-paren? char)
  (or (char=? char #\()
      (char=? char #\[)
      (char=? char #\{)))

;; Check if character is a closing paren
(define (closing-paren? char)
  (or (char=? char #\))
      (char=? char #\])
      (char=? char #\})))

;; Check if character is any parenthesis
(define (paren? char)
  (or (opening-paren? char)
      (closing-paren? char)))

;; Get matching paren for a given paren
(define (matching-paren char)
  (cond
    [(char=? char #\() #\)]
    [(char=? char #\[) #\]]
    [(char=? char #\{) #\}]
    [(char=? char #\)) #\(]
    [(char=? char #\]) #\[]
    [(char=? char #\}) #\{]
    [else char]))

;; Find parentheses and their nesting levels in the visible buffer area
(define (find-parentheses-in-buffer rope buffer-rect)
  (let* ([buffer-width (area-width buffer-rect)]
         [buffer-height (area-height buffer-rect)]
         [buffer-x (area-x buffer-rect)]
         [buffer-y (area-y buffer-rect)]
         [rope-lines (rope-len-lines rope)]
         
         ;; Get current view position to determine what lines are actually visible
         [current-view (editor-focus)]
         [doc-id (editor->doc-id current-view)])
    
    (define paren-data '())
    (define depth-stack '())
    
    ;; We need to process the entire document to maintain correct nesting depth,
    ;; but only collect parentheses that are in the visible area
    (define (process-line line-idx)
      (when (< line-idx rope-lines)
        (let ([line-rope (rope->line rope line-idx)])
          (when line-rope
            (let ([line-str (rope->string line-rope)]
                  [line-len (rope-len-chars line-rope)])
              
              ;; Process each character in the line
              (define (process-char col-idx)
                (when (< col-idx line-len)
                  (let ([char (string-ref line-str col-idx)])
                    (when (paren? char)
                      (cond
                        [(opening-paren? char)
                         ;; Push current depth to stack
                         (let ([current-depth (length depth-stack)])
                           (set! depth-stack (cons char depth-stack))
                           ;; Only add to display list if visible in current view
                           (when (and (>= line-idx buffer-y)
                                     (< line-idx (+ buffer-y buffer-height)))
                             (set! paren-data (cons (list line-idx col-idx char current-depth) paren-data))))]
                        
                        [(closing-paren? char)
                         ;; Pop from stack if matches
                         (when (and (not (null? depth-stack))
                                   (char=? (matching-paren char) (car depth-stack)))
                           (set! depth-stack (cdr depth-stack)))
                         (let ([current-depth (length depth-stack)])
                           ;; Only add to display list if visible in current view  
                           (when (and (>= line-idx buffer-y)
                                     (< line-idx (+ buffer-y buffer-height)))
                             (set! paren-data (cons (list line-idx col-idx char current-depth) paren-data))))]))
                    
                    (process-char (+ col-idx 1)))))
              
              (process-char 0))))))
    
    ;; Process all lines to maintain correct depth tracking
    (define (process-lines line-idx)
      (when (< line-idx rope-lines)
        (process-line line-idx)
        (process-lines (+ line-idx 1))))
    
    (process-lines 0)
    (reverse paren-data)))

;; Convert buffer line/col to screen coordinates
;; Note: Buffer area includes line number gutter, so we need to account for that offset
(define (buffer-to-screen-pos line col buffer-rect)
  (let ([gutter-width 7]  ; Typical line number gutter width (adjust as needed)
        [screen-x (+ (area-x buffer-rect) gutter-width col)]
        [screen-y (+ (area-y buffer-rect) line)])
    (list screen-x screen-y)))

;; Enhanced version that tries to calculate gutter width dynamically
(define (buffer-to-screen-pos-dynamic line col buffer-rect rope)
  (let* ([total-lines (rope-len-lines rope)]
         [max-line-digits (string-length (number->string total-lines))]
         [gutter-width (+ max-line-digits 2)]  ; digits + some padding
         [screen-x (+ (area-x buffer-rect) gutter-width col)]
         [screen-y (+ (area-y buffer-rect) line)])
    (list screen-x screen-y)))

;; Render rainbow parentheses onto the buffer
(define (render-rainbow-parens state rect buffer)
  (let* ([current-view (editor-focus)]
         [doc-id (editor->doc-id current-view)]
         [rope (editor->text doc-id)]
         [buffer-rect (editor-focused-buffer-area)])
    
    (when (and rope buffer-rect)
      (let ([paren-data (find-parentheses-in-buffer rope buffer-rect)])
        
        ;; Render each parenthesis with its rainbow color
        (define (render-paren paren-info)
          (let* ([line (car paren-info)]
                 [col (cadr paren-info)]
                 [char (caddr paren-info)]
                 [depth (cadddr paren-info)]
                 [color (get-rainbow-color depth)]
                 [style (style-fg (theme->fg *helix.cx*) color)]
                 [screen-pos (buffer-to-screen-pos line col buffer-rect)]
                 [screen-x (car screen-pos)]
                 [screen-y (cadr screen-pos)])
            
            ;; Only render if within the component's rect
            (when (and (>= screen-x (area-x rect))
                      (< screen-x (+ (area-x rect) (area-width rect)))
                      (>= screen-y (area-y rect))
                      (< screen-y (+ (area-y rect) (area-height rect))))
              
              (frame-set-string! buffer screen-x screen-y (string char) style))))
        
        ;; Render all parentheses
        (for-each render-paren paren-data)))))

;; Component state (can be empty for this simple overlay)
(define rainbow-paren-state (rainbow-paren #true))

;; Event handler - just let all events pass through to Helix
;; The render function will be called each frame automatically
(define (handle-rainbow-event state event)
  event-result/ignore)

;; Function map for the component
(define rainbow-function-map
  (hash "handle_event" handle-rainbow-event
        "cursor" (lambda (state rect) #false))) ; No cursor needed

;; Create the rainbow parentheses component
(define (create-rainbow-parentheses-component)
  (new-component! "rainbow-parens"
                  rainbow-paren-state
                  render-rainbow-parens
                  rainbow-function-map))

;; Activate rainbow parentheses
(define (activate-rainbow-parentheses)
  "Activate rainbow parentheses overlay"
  (let ([component (create-rainbow-parentheses-component)])
    (push-component! component)
    (echo "Rainbow parentheses activated!")))

;; Convenience function to toggle rainbow parentheses
;; Note: This is a simple implementation - for a full toggle, 
;; you'd need to track component state and remove it
(define (toggle-rainbow-parentheses)
  "Toggle rainbow parentheses (currently just activates)"
  (activate-rainbow-parentheses))

;; Usage examples:
;; (activate-rainbow-parentheses)           ; Basic rainbow parentheses
;; (activate-enhanced-rainbow-parentheses)  ; With cursor highlighting
;; (toggle-rainbow-parentheses)             ; Quick activation
