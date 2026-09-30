;;; init.el -*- lexical-binding: t; -*-
;;
;; Doom Emacs module list. Each entry enables a language, a tool or a UI
;; feature, and some take +flags (e.g. (web +lsp)).
;;
;; A name that does not resolve is skipped SILENTLY — no error, no warning, just
;; a missing feature. Doom's warnings there are not to be trusted, so verify a
;; module exists before adding it.
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
       csharp
       data
       emacs-lisp
       go
       java
       (javascript +lsp)
       json
       kotlin
       lua
       markdown
       nix
       ocaml
       org
       python
       rust
       sh
       (web +lsp)
       yaml
       zig

       :config
       (default +bindings +smartparens))
