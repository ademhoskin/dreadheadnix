;; -*- mode: emacs-lisp; lexical-binding: t -*-
;; Spacemacs config for dreadheadnix.
;; Evil mode is enabled intentionally.

(defconst doom-themes '(doom-one))

(setq-default
 dotspacemacs-distribution 'spacemacs
 dotspacemacs-editing-style 'vim
 dotspacemacs-startup-banner nil
 dotspacemacs-maximized-at-startup t
 dotspacemacs-smooth-scrolling t
 dotspacemacs-line-numbers 'relative
 dotspacemacs-auto-save-file-location 'cache
 dotspacemacs-which-key-delay 0.4
 dotspacemacs-which-key-position 'bottom
 dotspacemacs-default-font '(("JetBrainsMono Nerd Font" :size 12 :weight normal :width normal)
                             ("Noto Sans Mono" :size 12 :weight normal :width normal)
                             ("monospace" :size 12 :weight normal :width normal))
 dotspacemacs-themes '(doom-one)
 dotspacemacs-colorize-cursor-according-to-state t
 dotspacemacs-leader-key "SPC"
 dotspacemacs-emacs-leader-key "M-m"
 dotspacemacs-enable-server t)

(setq-default
 evil-want-C-u-scroll t
 evil-want-C-d-scroll t
 evil-want-integration t
 evil-want-keybinding nil
 evil-collection-mode t)

(defun dotspacemacs/user-config ()
  (setq-default
   indent-tabs-mode nil
   tab-width 4
   c-basic-offset 4
   evil-shift-width 4
   default-frame-alist '((fullscreen . maximized))
   fill-column 100)

  (setq org-src-fontify-natively t)
  (setq whitespace-style '(face trailing tabs))
  (global-display-line-numbers-mode t)
  (global-hl-line-mode t)
  (setq backup-directory-alist `(("." . ,(expand-file-name "~/.cache/emacs/backups"))))
  (setq auto-save-file-name-transforms `((".*" ,(expand-file-name "~/.cache/emacs/auto-saves/") t)))
  (setq projectile-project-search-path '("~/src" "~/workspace" "~/projects"))
  (setq lsp-file-watch-threshold 20000)
  (setq lsp-enable-file-watchers nil)
  (when (fboundp 'evil-set-leader)
    (evil-set-leader 'normal (kbd "SPC")))
  (when (fboundp 'evil-collection-init)
    (evil-collection-init 'dired 'ibuffer 'help 'magit))
  (when (fboundp 'lsp-enable-which-key-integration)
    (lsp-enable-which-key-integration)))

(defun dotspacemacs/user-init ()
  (setq gc-cons-threshold 100000000))

(defun dotspacemacs/user-load ()
  (setq-default projectile-project-search-path '("~/src" "~/workspace" "~/projects")))

(setq-default
 dotspacemacs-configuration-layers
 '(
   auto-completion
   aws
   bash
   better-defaults
   c-c++
   cmake
   css
   d
   dap
   docker
   emacs-lisp
   git
   go
   helm
   html
   java
   javascript
   json
   kotlin
   lsp
   markdown
   nix
   org
   prettier
   projectile
   python
   rust
   shell-syntax
   sql
   syntax-checking
   tailwind
   themes-megapack
   treemacs
   typescript
   version-control
   yaml
   zig
   )
 dotspacemacs-additional-packages '(nova-theme prettier-js prettier-yaml)
 dotspacemacs-excluded-packages '())

;; Keep Spacemacs in vim-ish evil mode for the daily workflow.
(setq-default evil-mode t)
