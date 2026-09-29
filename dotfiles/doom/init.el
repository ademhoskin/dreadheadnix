;;; init.el -*- lexical-binding: t; -*-
;;
;; Doom Emacs module list — this is the direct equivalent of the
;; `dotspacemacs-configuration-layers` block in the old .spacemacs.
;; Spacemacs "layers" and Doom "modules" are the same idea under two names.
;;
;;   Spacemacs layer        ->  Doom module
;;   helm                  ->  completion/vertico
;;   auto-completion       ->  completion/company
;;   treemacs              ->  ui/treemacs
;;   themes-megapack       ->  ui/doom (doom-themes ships in core)
;;   version-control       ->  ui/vc-gutter + tools/magit
;;   lsp                   ->  tools/lsp
;;   dap                   ->  tools/debugger
;;   syntax-checking       ->  checkers/syntax-checker
;;   prettier              ->  editor/format (apheleia)
;;   bash                  ->  lang/sh
;;   c-c++                 ->  lang/cc
;;   css + html + tailwind ->  lang/web
;;   d                     ->  (none — dropped in 1f99704)
;;
;; After editing this file run:  ~/.config/emacs/bin/doom sync

(doom! :input
       ;;chinese
       ;;japanese
       ;;layout

       :completion
       company
       vertico

       :ui
       doom
       dashboard
       ;; no hl-line module exists; config.el enables global-hl-line-mode
       ;; directly, which is the same effect.
       indent-guides
       modeline
       ophints
       (popup +defaults)
       treemacs
       vc-gutter
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       multiple-cursors
       snippets

       :emacs
       dired
       electric
       ibuffer
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       ;; no tools/aws module exists; use awscli2 from home.packages instead
       debugger
       direnv
       docker
       editorconfig
       lookup
       lsp
       magit
       make
       tree-sitter

       :os
       tty

       :lang
       ;; no lang/cmake and no lang/sql module exists. CMake files are handled
       ;; by lang/cc, and sql.el ships with Emacs itself, so both still work —
       ;; they just are not modules you can enable.
       cc
       data
       emacs-lisp
       go
       java
       (javascript +lsp)
       json
       kotlin
       markdown
       nix
       org
       python
       rust
       sh
       (web +lsp)
       yaml
       zig

       :config
       (default +bindings +smartparens))
