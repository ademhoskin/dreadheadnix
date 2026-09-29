;;; config.el -*- lexical-binding: t; -*-
;;
;; Port of the `dotspacemacs/user-config` block from the old .spacemacs.
;; Evil mode, the SPC leader, which-key and evil-collection are all Doom
;; defaults, so unlike Spacemacs they need no configuration here.

;; --- Identity ---
(setq user-full-name "Adem Hoskin"
      user-mail-address "ademjhoskin@gmail.com")

;; --- Fonts (Spacemacs defaulted to JetBrainsMono Nerd Font 12) ---
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 12)
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 12)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 18))

;; --- Theme (was dotspacemacs-themes '(doom-one)) ---
(setq doom-theme 'doom-one)

;; --- Editing defaults, straight from the Spacemacs user-config ---
(setq-default
 indent-tabs-mode nil
 tab-width 4
 c-basic-offset 4
 evil-shift-width 4
 fill-column 100)

(setq display-line-numbers-type 'relative)  ; was dotspacemacs-line-numbers 'relative

;; was dotspacemacs-maximized-at-startup t
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; was dotspacemacs-smooth-scrolling t
(setq scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t
      hscroll-margin 2
      hscroll-step 1)

;; --- Backups and auto-saves -> ~/.cache (was dotspacemacs-auto-save-file-location 'cache) ---
(setq backup-directory-alist
      `(("." . ,(expand-file-name "emacs/backups/" "~/.cache")))
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "emacs/auto-saves/" "~/.cache") t)))

;; --- Projectile search paths (was projectile-project-search-path) ---
(setq projectile-project-search-path '("~/src" "~/workspace" "~/projects"))

;; --- LSP: same watch limits the Spacemacs config set ---
(setq lsp-file-watch-threshold 20000)
(setq lsp-enable-file-watchers nil)

;; --- Misc from the Spacemacs user-config ---
(setq org-src-fontify-natively t)
(setq whitespace-style '(face trailing tabs))
(global-display-line-numbers-mode t)
(global-hl-line-mode t)

;; was `dotspacemacs-enable-server t`
(add-hook 'after-init-hook #'server-start)

;; was `(setq gc-cons-threshold 100000000)` in dotspacemacs/user-init.
;; Doom already raises this during startup and restores it afterwards, so this
;; only covers the steady state.
(setq gc-cons-threshold 100000000)
