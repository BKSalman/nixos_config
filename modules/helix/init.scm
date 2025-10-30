(require "helix/configuration.scm")
(require "helix/keymaps.scm")
(require (only-in "helix/ext.scm" evalp eval-buffer))

(define-lsp "steel-language-server" (command "steel-language-server") (args '()))
(define-language "scheme"
                 (language-servers '("steel-language-server")))

(keymap (global)
        (normal (C-u ":half-page-up") (C-d ":half-page-down")))
