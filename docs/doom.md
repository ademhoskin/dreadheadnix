# Doom Emacs

Orientation for someone arriving from Neovim. Every binding below was read out
of Doom's own source rather than recalled, so they are what this config actually
ships.

## The mental model, versus Neovim

| | Neovim | Doom |
| --- | --- | --- |
| Config | `init.lua` you write | `init.el` lists *modules*; Doom supplies the config |
| Plugins | A manager you drive (`lazy.nvim`, `:Lazy`) | `doom sync`, run for you — you mostly never touch it |
| Keys | You bind everything | `SPC` leader + which-key already has everything |
| Language support | Per-plugin setup | `+lsp` on a language module |
| Startup | Immediate | First start compiles; later starts are fast |

The important shift: **in Neovim you build the editor, in Doom you select from a
menu.** Most "how do I do X" questions are answered by pressing `SPC` and
reading which-key, not by writing config.

## The thing that will bite you

**Doom skips a module it cannot resolve, silently.** No error, no warning — you
just don't get the feature. A typo in `init.el` costs you the capability and
tells you nothing. If something you enabled isn't working, check the module name
against `~/.config/emacs/modules/` before debugging anything else.

**After editing `init.el` or `packages.el`, run:**

```sh
~/.config/emacs/bin/doom sync
```

Nothing changes until you do. This is the equivalent of `:Lazy sync`.

## Discovery: press SPC and wait

`SPC` is the leader. Press it and pause — which-key opens a panel listing every
binding available under that prefix. That panel is the manual. `SPC h` is help
(`SPC h k` describes a key, `SPC h f` a function, `SPC h m` the mode list).

You will rarely need to memorise anything below; use it as a map of what exists.

## The leader menu

| Key | Group | Key | Group |
| --- | --- | --- | --- |
| `SPC SPC` | find file in project | `SPC b` | buffer |
| `SPC .` | find file | `SPC c` | code / LSP |
| `SPC ,` | switch buffer | `SPC d` | debugger |
| `SPC /` | search project | `SPC f` | file |
| `SPC *` | search project for symbol at point | `SPC g` | git |
| `SPC :` | M-x (run any command by name) | `SPC o` | open |
| `SPC x` | scratch buffer | `SPC p` | project |
| `SPC h` | help | `SPC q` | quit / session |
| `SPC w` | window (evil's window map) | `SPC s` | search |
| `SPC t` | toggle | `SPC TAB` | workspace |

### Files and buffers

| Key | Does |
| --- | --- |
| `SPC .` | find a file |
| `SPC SPC` | find a file in the current project |
| `SPC f s` | save |
| `SPC f S` | save as |
| `SPC f r` | recent files |
| `SPC f R` | rename/move this file |
| `SPC f y` | yank this file's path |
| `SPC ,` | switch buffer |
| `SPC b d` | kill this buffer |
| `SPC b i` | ibuffer — the buffer list |
| `SPC b r` | revert buffer (reload from disk) |

### Search

| Key | Does |
| --- | --- |
| `SPC s s` | search in this buffer |
| `SPC s p` | search the project (ripgrep) |
| `SPC /` | same, from the leader |
| `SPC s i` | jump to a symbol |
| `SPC s o` | look the thing at point up online |

### Project and windows

| Key | Does |
| --- | --- |
| `SPC p p` | switch project |
| `SPC p f` | find file in project |
| `SPC p b` | switch to a buffer in the project |
| `SPC p c` | compile in the project |
| `SPC p T` | run the project's tests |
| `SPC p !` | run a shell command in the project root |
| `SPC w v` / `SPC w s` | split vertically / horizontally |
| `SPC w d` | close this window |
| `SPC w h/j/k/l` | move between windows |
| `SPC w w` | cycle windows |

`SPC w` opens evil's window map, so `SPC w` then which-key lists the rest.

## Code and LSP

The language servers come from `home.packages` — see `docs/toolchain.md`. Doom
finds them on `PATH`; there is no separate install step.

| Key | Does |
| --- | --- |
| `SPC c d` | jump to definition |
| `SPC c D` | jump to references |
| `SPC c i` | find implementations |
| `SPC c t` | find type definition |
| `SPC c k` | documentation for the thing at point |
| `SPC c a` | code action — "add missing import", "fix this" |
| `SPC c r` | rename symbol across the project |
| `SPC c o` | organise imports |
| `SPC c f` | format buffer or region |
| `SPC c x` | list errors |
| `SPC c c` / `SPC c C` | compile / recompile |

In a buffer, `gd` and `K` also work — they are the standard evil/xref keys.

**If a server isn't running**, `SPC h m` shows the mode list and `M-x
lsp-workspace-restart` (or `M-x eglot-reconnect`) restarts it. Doom's LSP module
supports both `lsp-mode` and `eglot`; the module flag decides which.

## Debugging

Doom's `:tools debugger` module uses **dape**, which speaks DAP — the same
protocol VS Code uses. That means it drives real debug adapters rather than
Emacs-specific ones, and the adapters come from `home.packages`: `debugpy` for
Python, `delve` for Go, `lldb` and `gdb` for C/C++/Rust, `vscode-js-debug` for
Node, `netcoredbg` for .NET, `jdt-language-server` for Java.

| Key | Does |
| --- | --- |
| `SPC d d` | start a debugger (prompts for the config) |
| `SPC d b` | toggle a breakpoint |
| `SPC d B` | remove all breakpoints |
| `SPC d c` | continue |
| `SPC d n` | step over |
| `SPC d s` | step into |
| `SPC d o` | step out |
| `SPC d p` | pause |
| `SPC d r` | restart |
| `SPC d i` | info panel |
| `SPC d R` | open the REPL |
| `SPC d x` | evaluate an expression |
| `SPC d w` | watch an expression |
| `SPC d q` | quit the debug session |

dape reads launch configurations from `.dape` files or Emacs variables; on first
use it will ask. The commands you are prompted with are the adapters it found on
your `PATH`.

## Git

| Key | Does |
| --- | --- |
| `SPC g g` | magit status — the git UI |
| `SPC g G` | magit status for this file's repo |
| `SPC g b` | switch branch |
| `SPC g B` | blame |
| `SPC g C` | clone |
| `SPC g F` | fetch |
| `SPC g L` | log for this buffer |
| `SPC g s` / `SPC g r` | stage / revert the hunk at point |
| `SPC g ]` / `SPC g [` | next / previous hunk |

This is the biggest departure from Neovim. Magit is not `:Git` — it is a fully
interactive interface, and most people end up doing all their git through it.
Press `?` inside any magit buffer for its own transient menu.

Note `delta` in `docs/toolchain.md` is wired as git's pager, which applies to
`git` on the command line, **not** to magit's diff view — magit renders diffs
itself.

## Terminals

| Key | Does |
| --- | --- |
| `SPC o t` | toggle a terminal popup |
| `SPC o T` | open a terminal at the project root |
| `SPC o e` | toggle an eshell popup |

`vterm` is the module enabled here. It compiles a native module on first
`doom sync`, which is why `libtool`, `libvterm` and `texinfo` are in
`home.packages`.

## What is different from Neovim, concretely

| Neovim | Doom |
| --- | --- |
| `:w` | `SPC f s` |
| `:q` | `SPC b d` (kill buffer) or `SPC q q` (quit Emacs) |
| `:e file` | `SPC .` |
| `Space Space` (telescope) | `SPC SPC` |
| `<leader>ff` | `SPC SPC` or `SPC f f` |
| `<leader>fg` (live grep) | `SPC s p` |
| `gd` | `SPC c d` (or `gd`) |
| `gr` (references) | `SPC c D` |
| `K` (hover) | `SPC c k` (or `K`) |
| `<leader>rn` (rename) | `SPC c r` |
| `<leader>ca` (code action) | `SPC c a` |
| `:Lazy` | `~/.config/emacs/bin/doom sync` |
| `:Mason` | nothing — servers come from `home.packages` |

`Mason` genuinely has no equivalent: this setup does not let the editor install
tools at runtime. Anything you need goes in `home-manager/home.nix` so it is
reproducible and survives a rebuild.

## Where the config lives

```
dotfiles/doom/init.el      module list — select features here
dotfiles/doom/config.el    settings, key overrides per mode
dotfiles/doom/packages.el  extra packages beyond the modules
```

They are symlinked to `~/.config/doom/`. Doom itself is cloned to
`~/.config/emacs` and is **not** in this repo — `doom sync` writes compiled
packages into it, so a read-only store path would break every module change.

To add a keybinding, use `map!` in `config.el`:

```elisp
(map! :leader :desc "Open this file" "z" #'find-file)
```

## Troubleshooting

**A feature from a module doesn't exist.** The module name is wrong. Doom
skipped it silently. Check the name against `~/.config/emacs/modules/`.

**A language server isn't starting.** Check it is on `PATH` (`command -v gopls`),
then check the module is enabled, then `doom sync`.

**Everything is broken after a config change.** `doom sync` did not run, or it
failed. Run it manually and read the output.

**Startup is slow once.** The first start after a `doom sync` compiles
packages. It is fast afterwards.
