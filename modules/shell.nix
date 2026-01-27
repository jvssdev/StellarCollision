{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    getExe
    ;
  cfg = config.cfg.zsh;
  c = config.cfg.theme.colors;
  homeDir = config.cfg.vars.homeDirectory;
  xdgCache = "${homeDir}/.cache";
in
{
  options.cfg.zsh.enable = mkEnableOption "zsh";

  config = mkIf cfg.enable {
    users.users.${config.cfg.vars.username} = {
      shell = pkgs.zsh;
    };

    hj = {
      packages = [
        pkgs.unzip
        pkgs.tree
        pkgs.fzf
        pkgs.fd
        pkgs.ncdu
        pkgs.ripgrep
        pkgs.nixos-shell
        pkgs.nix-your-shell
        pkgs.starship
        pkgs.atuin
        pkgs.bat
        pkgs.lsd
        pkgs.zoxide
        pkgs.wezterm
        pkgs.zsh-autosuggestions
        pkgs.zsh-completions
        pkgs.zsh-fast-syntax-highlighting
        pkgs.zsh-fzf-tab
        pkgs.zsh-fzf-history-search
        pkgs.zsh-history-substring-search
      ];

      files = {
        ".zprofile".text = ''
          export PATH="/usr/lib64/qt6/bin:$PATH"
          export PATH="$HOME/.cargo/bin:$PATH"
          export GOPATH=$HOME/go
          export PATH="$HOME/.local/bin:$PATH"
        '';

        ".zshrc".text = ''
          setopt HIST_IGNORE_DUPS
          setopt HIST_IGNORE_ALL_DUPS
          setopt HIST_IGNORE_SPACE
          setopt SHARE_HISTORY
          setopt GLOBDOTS

          HISTSIZE=100000
          SAVEHIST=100000
          HISTFILE="${xdgCache}/zsh/history"

          autoload -Uz compinit
          zstyle ':completion:*' menu select
          zmodload zsh/complist
          compinit -d ${xdgCache}/zsh/zcompdump-$ZSH_VERSION

          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
          WORDCHARS='*?_-.[]~=&;!$%^(){}<>|'

          fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)

          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
          source ${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.zsh
          source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
          source ${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/zsh-fzf-history-search.zsh

          bindkey '^[[A' history-substring-search-up
          bindkey '^[[B' history-substring-search-down
          bindkey -M vicmd 'k' history-substring-search-up
          bindkey -M vicmd 'j' history-substring-search-down

          export ZHM_STYLE_CURSOR_SELECT="fg:${c.base00},bg:${c.base08}"
          export ZHM_STYLE_CURSOR_INSERT="fg:${c.base00},bg:${c.base0B}"
          export ZHM_STYLE_OTHER_CURSOR_NORMAL="fg:${c.base00},bg:${c.base0C}"
          export ZHM_STYLE_OTHER_CURSOR_SELECT="fg:${c.base00},bg:${c.base0E}"
          export ZHM_STYLE_OTHER_CURSOR_INSERT="fg:${c.base00},bg:${c.base0D}"
          export ZHM_STYLE_SELECTION="fg:${c.base07},bg:${c.base02}"
          export ZHM_CURSOR_INSERT='\e[0m\e[6 q\e]12;${c.base0B}\a'

          ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
            zhm_history_prev zhm_history_next zhm_prompt_accept
            zhm_accept zhm_accept_or_insert_newline
          )
          ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(
            zhm_move_right zhm_clear_selection_move_right
          )
          ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(
            zhm_move_next_word_start zhm_move_next_word_end
          )

          eval "$(${pkgs.fzf}/bin/fzf --zsh)"

          export FZF_DEFAULT_OPTS="
            --color=bg+:${c.base02},bg:${c.base00},spinner:${c.base04},hl:${c.base0D}
            --color=fg:${c.base05},header:${c.base0D},info:${c.base0C},pointer:${c.base04}
            --color=marker:${c.base0B},fg+:${c.base07},prompt:${c.base0C},hl+:${c.base0C}"

          if [[ "$TERM" != "dumb" ]]; then
            source ${pkgs.wezterm}/etc/profile.d/wezterm.sh
          fi

          eval "$(${getExe pkgs.direnv} hook zsh)"
          eval "$(${getExe pkgs.zoxide} init --cmd cd zsh)"
          eval "$(${getExe pkgs.atuin} init zsh)"
          eval "$(${getExe pkgs.starship} init zsh)"
          eval "$(${getExe pkgs.nix-your-shell} zsh)"

          alias ls="${getExe pkgs.lsd}"
          alias cat="${getExe pkgs.bat} --paging=never"
          alias grep="${getExe pkgs.ripgrep}"
        '';
      };

      xdg.config.files = {
        "atuin/config.toml".text = ''
          enter_accept = false
          keymap_mode = "vim-insert"
          [keymap_cursor]
          vim_insert = "steady-bar"
          vim_normal = "steady-block"
        '';

        "starship.toml".text = ''
          add_newline = true
          format = """
          [░▒▓](${c.base03})[ ](bg:${c.base03} fg:${c.base06})[](bg:${c.base0D} fg:${c.base03})$nix_shell$directory[](fg:${c.base0D} bg:${c.base01})$git_branch$git_status[](fg:${c.base01} bg:${c.base02})$nodejs$rust$golang$php[](fg:${c.base02} bg:${c.base03})$time[](fg:${c.base03})
          $character
          """

          [nix_shell]
          disabled = false
          format = "[ ]($style)"
          style = "bold fg:${c.base06} bg:${c.base0D}"

          [directory]
          style = "fg:${c.base03} bg:${c.base0D}"
          format = "[ $path ]($style)"
          truncation_length = 3
          truncation_symbol = "…/"

          [git_branch]
          symbol = ""
          style = "bg:${c.base01}"
          format = "[[ $symbol $branch ](fg:${c.base04} bg:${c.base01})]($style)"

          [time]
          disabled = false
          time_format = "%R"
          style = "bg:${c.base03}"
          format = "[[  $time ](fg:${c.base04} bg:${c.base03})]($style)"
        '';
      };
    };

    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        angrr.enable = config.services.angrr.enable;
      };

      zsh.enable = true;
    };
  };
}
