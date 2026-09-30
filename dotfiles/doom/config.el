;;; config.el -*- lexical-binding: t; -*-
;;
;; Evil mode, the SPC leader, which-key and evil-collection are all Doom
;; defaults, so none of them need configuring here.

;; --- Identity ---
(setq user-full-name "Adem Hoskin"
      user-mail-address "ademjhoskin@gmail.com")

;; --- Fonts ---
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 12)
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 12)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 18))

(setq doom-theme 'doom-one)

;; --- Editing defaults ---
(setq-default
 indent-tabs-mode nil
 tab-width 4
 c-basic-offset 4
 evil-shift-width 4
 fill-column 100)

(setq display-line-numbers-type 'relative)

(add-to-list 'default-frame-alist '(fullscreen . maximized))

(setq scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t
      hscroll-margin 2
      hscroll-step 1)

;; --- Backups and auto-saves, kept out of the working tree ---
(setq backup-directory-alist
      `(("." . ,(expand-file-name "emacs/backups/" "~/.cache")))
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "emacs/auto-saves/" "~/.cache") t)))

;; --- Projectile search paths ---
(setq projectile-project-search-path '("~/src" "~/workspace" "~/projects"))

;; --- LSP watch limits, raised because these trees are large ---
(setq lsp-file-watch-threshold 20000)
(setq lsp-enable-file-watchers nil)

;; --- Misc ---
(setq org-src-fontify-natively t)

;; whitespace-style alone does nothing — nothing enables whitespace-mode or
;; reads these variables unless it is on, so this pair has to stay together.
(setq whitespace-style '(face trailing tabs))
(global-whitespace-mode +1)

(global-display-line-numbers-mode t)
(global-hl-line-mode t)

;; Doom starts a server for GUI frames but not for a terminal Emacs, so this is
;; the only thing making emacsclient work from a tty.
(add-hook 'after-init-hook #'server-start)

;; Doom already raises this during startup and restores it afterwards, so this
;; only covers the steady state.
(setq gc-cons-threshold 100000000)
