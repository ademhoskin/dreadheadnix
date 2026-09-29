;;; packages.el -*- lexical-binding: t; -*-
;;
;; Extra packages beyond what the modules in init.el already pull in.
;; This is the equivalent of `dotspacemacs-additional-packages` in the old
;; .spacemacs, which held: nova-theme prettier-js prettier-yaml
;;
;; prettier-js / prettier-yaml are gone: Doom's editor/format module drives
;; prettier through apheleia for every language that needs it, so those two
;; are redundant here.

(package! nova-theme)
