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
       doom-dashboard
       hl-line
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
       syntax-checker

       :tools
       aws
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
       cc
       cmake
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
       sql
       (web +lsp)
       yaml
       zig

       :config
       (default +bindings +smartparens))
