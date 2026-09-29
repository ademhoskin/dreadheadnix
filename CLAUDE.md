# dreadheadnix

NixOS flake for a Dell Inspiron 16 7630 2-in-1: flake + home-manager + disko,
Hyprland, Doom Emacs. See `README.md` for install steps and repo layout.

## Code style

### Write idiomatic, performant code

- Read the surrounding file first and match it. Conventions already in the tree
  beat conventions you prefer.
- Prefer the standard library and the platform's own tools. Do not add a
  dependency for something a few lines covers.
- Write for someone who knows the language. No defensive ceremony, no
  hand-rolling what the stdlib already does, no abstractions with one caller.
- Performance: avoid needless allocation and copying in hot paths, and prefer
  streaming or laziness where the language makes it natural. Leave cold paths
  plain. Measure before optimising, and say what you measured.

### Be brief when commenting

- Comment the *why*. The code already says *what*.
- No narration of obvious lines, and no comment that restates the function
  name. If a comment is the only thing making a line clear, rename the thing
  instead.
- Never leave commented-out code. Git remembers it.
- Delete a stale comment in the same change that makes it stale.
- A short header on a non-obvious file or function beats inline noise. Silence
  is the right default for code that is already clear.

### Document with the language's own doc tooling

Use the ecosystem's doc format rather than ad-hoc prose:

| Language | Tool | Form |
| --- | --- | --- |
| Rust | rustdoc | `///`, with `# Examples` / `# Errors` where useful |
| Go | godoc | `// Name ...` above the declaration |
| Python | PEP 257 | `"""docstring"""` |
| TypeScript / JavaScript | JSDoc | `/** ... */` |
| C / C++ | Doxygen | `/** ... */` or `///` |
| Java / Kotlin | Javadoc / KDoc | `/** ... */` |
| Haskell | Haddock | `-- \|` |
| OCaml | odoc | `(** ... *)` |
| Lua | LDoc | `---` |
| Nix | nixpkgs style | `#` above the binding |
| Shell | — | `#` header block per script and per function |

- Document the *contract*: what it does, parameters, returns, errors, and any
  invariant a caller must uphold. Implementation notes belong in a plain
  comment, not the doc block.
- Do not document self-evident code. An undocumented obvious function is fine;
  a documented one is noise.

## Repo-specific rules

- **This repo is public.** Never commit a secret, a password, a hash, or an API
  key. The account password is generated at install time into
  `/var/lib/nixos-secrets/passwd`, outside the tree.
- **Nix**: prefer nixpkgs idioms — explicit options over magic, and don't
  duplicate what a module already provides. Check whether an option exists
  before hand-rolling a service.
- **`install.sh` is destructive.** It erases a whole disk. Any change to it
  keeps the typed confirmation step and the partition-label check.
- **`nixos/disko.nix` is not reversible.** There is no undo and no dual-boot
  support. Rehearse layout changes in QEMU via `scripts/qemu-run.sh` first.
- **The laptop config and the ISO config stay separate.** The ISO is built from
  `installation-cd-minimal.nix`, which overrides `fileSystems`; importing the
  laptop's disk layout into it silently discards that layout rather than
  erroring.

## Commits

**Subject line only.** No body, no bullet lists, no trailers. If a change needs
a paragraph to explain it, that is a sign it wants splitting, not describing.
Imperative mood, no trailing period.

## Verifying changes

There is no Nix on the development machine, so nothing here can be evaluated
locally. CI (`.github/workflows/iso.yml`) is what actually builds the config —
a wrong option name or a broken import fails there, not here. Say so plainly
rather than implying a change was tested when it was only written.
