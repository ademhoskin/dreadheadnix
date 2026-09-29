# dreadheadnix

NixOS flake for a Dell Inspiron 16 7630 2-in-1: flake + home-manager + disko,
Hyprland, Doom Emacs. See `README.md` for install steps and repo layout.

Code style, commenting, doc-comment and commit conventions live in the global
rules at `~/.claude/CLAUDE.md` (checked in here as `claude/CLAUDE.md`). They are
not repeated below.

## Repo-specific rules

- **This repo is public.** Never commit a secret, a password, a hash, or an API
  key. The account password is generated at install time into
  `/var/lib/nixos-secrets/passwd`, and the Claude credential is read at runtime
  from `~/.config/claude/env` — both outside the tree.
- **Nix**: prefer nixpkgs idioms — explicit options over magic, and don't
  duplicate what a module already provides. Check whether an option exists
  before hand-rolling a service.
- **`install.sh` is destructive.** It erases a whole disk. Any change to it
  keeps the typed confirmation step and the partition-label check.
- **`nixos/disko.nix` is not reversible.** There is no undo and no dual-boot
  support. Layout changes get rehearsed in the CI VM before they touch a disk.
- **The laptop config and the ISO config stay separate.** The ISO is built from
  `installation-cd-minimal.nix`, which overrides `fileSystems`; importing the
  laptop's disk layout into it silently discards that layout rather than
  erroring.
- **The CI-only `*Test` outputs may differ from the real ones in credential
  policy only.** `installerTest` and `inspironTest` exist so the rehearsal can
  reach a shell. Their disk layout, bootloader and services must stay identical
  to `installer` and `inspiron`, or the rehearsal stops proving anything.

## Verifying changes

There is no Nix on the development machine, so nothing here can be evaluated
locally. CI is what actually builds the config — a wrong option name or a broken
import fails there, not here.

Two jobs, and they prove different things: `build-iso` shows the configuration
evaluates and the ISO builds; `install-test` boots that ISO under UEFI in QEMU,
runs `install.sh` against a blank disk, and asserts the installed system boots.
Only the second one touches a disk, and it is the only thing that ever executes
`install.sh`.
