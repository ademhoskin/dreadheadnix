# User environment — shell, editor, terminal, and the polyglot dev toolchain.
#
# This is a NixOS home-manager module (loaded by nixos/configuration.nix with
# useGlobalPkgs), not a standalone homeConfiguration, so it deliberately does
# not set home.username, home.homeDirectory, or nixpkgs.config — the system
# config owns those.
{ lib, pkgs, ... }:

let
  dotfiles = ../dotfiles;
  claude = ../claude;
in {
  home.stateVersion = "26.05";

  # --- Git ---
  programs.git = {
    enable = true;
    # userName/userEmail/extraConfig were renamed to settings.*; the old
    # spellings still work but warn on every evaluation.
    settings = {
      user = {
        name = "Adem Hoskin";
        email = "ademjhoskin@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # --- Shell: zsh ---
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Both moved under a namespace; the enable* spellings are deprecated.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 5000;
      save = 5000;
      path = "$HOME/.histfile";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -lh --icons --git --group-directories-first";
      la = "eza -lah --icons --git --group-directories-first";
      tree = "eza --tree --icons";
      top = "btm";
      jq = "jq -C";
    };

    initContent = ''
      # powerlevel10k prompt + the saved config
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # hackery red prompt overrides
      POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND='#ff3b30'
      POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND='#ff3b30'
      POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_FOREGROUND='#ff3b30'
      POWERLEVEL9K_DIR_FOREGROUND='#ff3b30'
      POWERLEVEL9K_VCS_FOREGROUND='#8a1f1f'
      POWERLEVEL9K_TIME_FOREGROUND='#8a1f1f'
      POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='#ff3b30'
      POWERLEVEL9K_VIRTUALENV_FOREGROUND='#8a1f1f'

      # fzf-tab (tab completion with previews). The package installs under
      # share/fzf-tab, not share/zsh-fzf-tab — and because this is a plain
      # string, nothing catches a wrong path at build time; every new shell
      # would just print "no such file or directory".
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # history + autosuggest bindings
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey "^f" autosuggest-accept

      alias zii="zoxide query -i"

      # fzf + ripgrep — fuzzy search code and open in $EDITOR
      frg() {
        rg --line-number --no-heading --color=always "$@" | \
          fzf --ansi --delimiter : --preview "bat --color=always --highlight-line {2} {1}" | \
          awk -F: '{print $1 " +" $2}' | xargs -r ''${EDITOR:-nvim}
      }

      export CC=clang
      export CXX=clang++

      # Claude Code credential. It cannot live in home.sessionVariables (those
      # are baked into the world-readable store at build time) and this repo is
      # public, so it is read from an untracked file at shell start instead.
      # After install:
      #   install -Dm600 /dev/null ~/.config/claude/env
      #   printf 'export ANTHROPIC_AUTH_TOKEN=%s\n' '<token>' > ~/.config/claude/env
      if [[ -r ~/.config/claude/env ]]; then
        source ~/.config/claude/env
      fi
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- Default applications ---
  #
  # Without this, nothing handles text/html or the http(s) schemes, and
  # clicking a link in another application silently does nothing rather than
  # failing loudly.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "org.qutebrowser.qutebrowser.desktop";
      "application/xhtml+xml" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/about" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/unknown" = "org.qutebrowser.qutebrowser.desktop";
    };
  };

  # --- Environment ---
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    # Claude Code routed at DeepSeek's Anthropic-compatible endpoint. Keep the
    # [1m] suffix: it selects the 1M-token-context variant, and dropping it
    # silently falls back to the smaller model.
    ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic";
    ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-flash[1m]";
    ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-flash[1m]";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-flash[1m]";
    CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-flash[1m]";
    CLAUDE_CODE_EFFORT_LEVEL = "ultracode";

    # QTWEBENGINE_CHROMIUM_FLAGS is set in dotfiles/hypr/hyprland.conf instead.
    # home.sessionVariables only reaches shells and systemd user units, so a
    # qutebrowser launched from a keybind would not see it there.

    # ANTHROPIC_AUTH_TOKEN is deliberately absent: home.sessionVariables are
    # evaluated at build time, so anything here lands in the world-readable
    # store. The shell exports it from ~/.config/claude/env instead — see the
    # sourcing block in zsh.initExtra below.
  };

  # --- Config from this repo ---
  #
  # Neovim's config is symlinked entry-by-entry rather than as one directory:
  # LazyVim rewrites lazyvim.json and lazy-lock.json at runtime, and a store
  # symlink is read-only, so a wholesale `".config/nvim".source = ...` makes
  # plugin and extras changes fail. Those two files are seeded as writable
  # copies instead. (The `lua` subtree is still symlinked whole — LazyVim only
  # reads from it.)
  home.file = {
    ".config/nvim/init.lua".source = "${dotfiles}/nvim/init.lua";
    ".config/nvim/lua".source = "${dotfiles}/nvim/lua";
    ".config/nvim/stylua.toml".source = "${dotfiles}/nvim/stylua.toml";
    ".config/nvim/.neoconf.json".source = "${dotfiles}/nvim/.neoconf.json";

    ".config/tmux/tmux.conf".source = "${dotfiles}/tmux/tmux.conf";
    ".config/hypr/hyprland.conf".source = "${dotfiles}/hypr/hyprland.conf";
    ".config/hypr/hyprpaper.conf".source = "${dotfiles}/hypr/hyprpaper.conf";
    ".config/hypr/wallpaper.png".source = "${dotfiles}/hypr/wallpaper.png";
    ".p10k.zsh".source = "${dotfiles}/p10k.zsh";

    # Doom Emacs user config. Only the inputs Doom *reads* are symlinked; the
    # rest of ~/.config/doom/ stays a normal writable directory so Doom can drop
    # custom.el and anything else it wants alongside them.
    ".config/doom/init.el".source = "${dotfiles}/doom/init.el";
    ".config/doom/packages.el".source = "${dotfiles}/doom/packages.el";
    ".config/doom/config.el".source = "${dotfiles}/doom/config.el";

    # Claude Code user config. These two files are symlinked individually, NOT
    # the directory: ~/.claude stays a real writable path because Claude Code
    # writes history, sessions, caches and file-history into it.
    #
    # To add subagents or slash commands, drop them in claude/agents/ or
    # claude/commands/ here and add a matching entry — they are picked up by
    # filename.
    ".claude/CLAUDE.md".source = "${claude}/CLAUDE.md";
    ".claude/settings.json".source = "${claude}/settings.json";
  };

  # tpm — the tmux plugin manager that tmux.conf drives directly with
  # `run ~/.tmux/plugins/tpm/tpm` — is not packaged in nixpkgs. tmuxPlugins
  # carries cpu, fpp and others but no tpm, and it is not a top-level package
  # either. So clone it, for the same reason as Doom: the declarative route
  # (fetchFromGitHub) needs a hash, and there is no Nix here to compute one.
  home.activation.installTpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.tmux/plugins/tpm/tpm" ]; then
      run ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
  '';

  # Doom itself cannot be a store symlink the way the other dotfiles are:
  # `doom sync` writes byte-compiled packages into ~/.config/emacs/.local, and a
  # read-only store path would make every module change fail. So clone it once
  # into a real directory. Wrapped in a test so rebuilds are a no-op.
  home.activation.installDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.config/emacs/bin" ]; then
      # --recurse-submodules is load-bearing. Doom's module tree is the
      # sources/doom+ submodule; without it the clone has no modules at all and
      # every entry in init.el is silently ignored.
      run ${pkgs.git}/bin/git clone --depth 1 --recurse-submodules \
        https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
    fi
  '';

  # Seed the two LazyVim state files as writable copies, once.
  home.activation.seedLazyVimState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/nvim"
    for f in lazyvim.json lazy-lock.json; do
      if [ ! -e "$HOME/.config/nvim/$f" ]; then
        run cp ${dotfiles}/nvim/$f "$HOME/.config/nvim/$f"
        run chmod u+w "$HOME/.config/nvim/$f"
      fi
    done
  '';

  # --- Dev toolchain ---
  home.packages = with pkgs; [
    # core / shell
    neovim
    tmux
    ripgrep   # also what Doom's search uses
    fd
    bat
    eza
    glow
    bottom

    # Doom Emacs. libtool/libvterm/texinfo are the build inputs `doom sync`
    # needs for the term/vterm module and for building some packages from
    # source; without them that step fails on NixOS with a compile error.
    emacs
    libtool
    libvterm
    texinfo

    # Claude Code, from nixpkgs rather than npm. Unfree — it ships a prebuilt
    # binary — so it rides on nixpkgs.config.allowUnfree in the system config.
    claude-code
    # git tooling. The package is `delta`; `git-delta` is not an attribute.
    delta
    lazygit
    gh
    just

    # C / C++
    clang
    clang-tools
    lld
    lldb
    gnumake
    cmake
    ninja
    pkg-config
    gdb
    valgrind
    doxygen
    # codelldb was here but is not an attribute in nixpkgs 26.05. Neovim's dap
    # setup will need a debug adapter configured another way if you want it.

    # Rust
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # Go
    go
    gopls
    gofumpt
    gotools   # provides the goimports binary; `goimports` is not an attribute
    delve

    # Zig
    zig

    # Java / .NET
    jdk21
    dotnet-sdk

    # Nix. nixfmt-rfc-style is now the same package as nixfmt and warns.
    nil
    nixfmt

    # Node / JS
    nodejs   # provides npm
    bun
    # nodePackages was removed in 26.05 and now throws; these moved to the top
    # level.
    pnpm
    yarn

    # Python
    python3
    uv
    pipx
    black
    isort
    python3Packages.debugpy   # not top-level

    # OCaml
    ocaml
    opam
    dune_3

    # Formatting / linting
    prettier
    stylua
    shfmt
    shellcheck

    # misc
    yaml-language-server
    awscli2
    subversion
  ];
}
