{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    listToAttrs
    ;

  cfg = config.cfg.yazi;
  c = config.cfg.theme.colors;

  mkYaziPlugin =
    {
      shortName,
      owner,
      repo,
      rev ? "main",
      hash,
    }:
    pkgs.stdenv.mkDerivation {
      name = shortName;

      src = pkgs.fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          ;
      };

      dontUnpack = true;
      dontBuild = true;
      dontFixup = true;

      installPhase = ''
        mkdir -p $out
        cp -r $src/* $out/
      '';
    };

  yatline = mkYaziPlugin {
    shortName = "yatline";
    owner = "imsi32";
    repo = "yatline.yazi";
    hash = "sha256-HjTRAfUHs6vlEWKruQWeA2wT/Mcd+WEHM90egFTYcWQ=";
  };

  yatlineGithead = mkYaziPlugin {
    shortName = "yatline-githead";
    owner = "imsi32";
    repo = "yatline-githead.yazi";
    hash = "sha256-1r7AY0Yzr32YZl2g74ylx+1vGoNg04PMkDXnaB0X+lk=";
  };

  fullBorder = pkgs.stdenv.mkDerivation {
    name = "full-border";

    src = pkgs.fetchFromGitHub {
      owner = "yazi-rs";
      repo = "plugins";
      rev = "main";
      hash = "sha256-TzHJNIFZjUOImZ4dRC0hnB4xsDZCOuEjfXRi2ZXr8QE=";
    };

    dontUnpack = false;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      mkdir -p $out
      cp -r $src/full-border.yazi/* $out/
    '';
  };

  nixpkgsPlugins = with pkgs.yaziPlugins; [
    chmod
    git
    restore
  ];

  allPlugins = nixpkgsPlugins ++ [
    fullBorder
    yatline
    yatlineGithead
  ];
in
{
  options.cfg.yazi = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Yazi configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.yazi;
      description = "The Yazi package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.package
        pkgs.trash-cli
      ];

      xdg.config.files = {
        "yazi/theme.toml".text = ''
          [mgr.size]
          fg = "${c.base03}"

          [status.progress_normal]
          fg = "${c.base04}"
          bg = "${c.base03}"
        '';

        "yazi/yazi.toml".text = ''
          [mgr]
          show_hidden = true
          show_symlink = true
          sort_dir_first = true
          linemode = "size"
          ratio = [1, 3, 4]

          [preview]
          max_width = 1920
          max_height = 1080
          image_filter = "lanczos3"
          image_quality = 90

          [[plugin.prepend_fetchers]]
          id = "git"
          name = "*"
          run = "git"

          [[plugin.prepend_fetchers]]
          id = "git"
          name = "*/"
          run = "git"

          [[opener.play]]
          run = "haruna \"$@\""
          orphan = true
          for = "unix"

          [[opener.image]]
          run = "imv \"$@\""
          orphan = true
          for = "unix"

          [[opener.pdf]]
          run = "zathura \"$@\""
          orphan = true
          for = "unix"

          [[opener.edit]]
          run = "$EDITOR \"$@\""
          block = true
          for = "unix"

          [[open.rules]]
          mime = "image/*"
          use = "image"

          [[open.rules]]
          mime = "application/pdf"
          use = "pdf"

          [[open.rules]]
          mime = "video/*"
          use = "play"

          [[open.rules]]
          mime = "audio/*"
          use = "play"

          [[open.rules]]
          mime = "text/*"
          use = "edit"

          [[open.rules]]
          mime = "application/json"
          use = "edit"

          [[open.rules]]
          mime = "application/javascript"
          use = "edit"

          [[open.rules]]
          mime = "application/x-shellscript"
          use = "edit"

          [[open.rules]]
          mime = "*"
          use = "edit"
        '';

        "yazi/keymap.toml".text = ''
          [[mgr.prepend_keymap]]
          on = ["g", "s"]
          run = "plugin git"
          desc = "Show git status"

          [[mgr.prepend_keymap]]
          on = ["c", "m"]
          run = "plugin chmod"

          [[mgr.prepend_keymap]]
          on = "u"
          run = "plugin restore"
          desc = "Restore last deleted files/folders"
        '';

        "yazi/init.lua".text = ''
          require("full-border"):setup {
            type = ui.Border.ROUNDED,
          }

          require("git"):setup()

          require("yatline"):setup({
            show_background = true,
            display_header_line = true,

            section_separator = { open = "", close = "" },
            part_separator = { open = "", close = "" },
            inverse_separator = { open = "", close = "" },

            header_line = {
              left = {
                section_a = { { type = "string", custom = false, name = "hovered_path" } },
                section_b = { { type = "coloreds", custom = false, name = "githead" } },
                section_c = {},
              },
              right = {
                section_a = { { type = "string", custom = false, name = "date", params = { "%A, %d %B %Y" } } },
                section_b = { { type = "string", custom = false, name = "date", params = { "%X" } } },
                section_c = {},
              },
            },

            style_a = {
              fg = "${c.base01}",
              bg_mode = {
                normal = "${c.base0D}",
                select = "${c.base0B}",
                un_set = "${c.base0D}",
              },
            },

            style_b = { bg = "${c.base03}", fg = "${c.base04}" },
            style_c = { bg = "${c.base01}", fg = "${c.base05}" },

            permissions_t_fg = "${c.base04}",
            permissions_r_fg = "${c.base04}",
            permissions_w_fg = "${c.base04}",
            permissions_x_fg = "${c.base04}",
            permissions_s_fg = "${c.base04}",

            status_line = {
              left = {
                section_a = { { type = "string", custom = false, name = "tab_mode" } },
                section_b = { { type = "coloreds", custom = false, name = "permissions" } },
                section_c = {},
              },
              right = {
                section_a = {
                  { type = "string", custom = false, name = "cursor_percentage" },
                  { type = "string", custom = false, name = "cursor_position" },
                },
                section_b = { { type = "string", custom = false, name = "hovered_size" } },
                section_c = {},
              },
            },
          })

          require("yatline-githead"):setup({
            show_branch = true,
            branch_prefix = "",
            branch_symbol = "",
            branch_borders = "",
            commit_symbol = " ",
            show_behind_ahead = true,
            behind_symbol = "⇣",
            ahead_symbol = "⇡",
            show_stashes = true,
            stashes_symbol = "✘",
            show_state = true,
            show_state_prefix = true,
            state_symbol = "󱅉",
            show_staged = true,
            staged_symbol = "+",
            show_unstaged = true,
            unstaged_symbol = "!",
            show_untracked = true,
            untracked_symbol = "?",
            prefix_color = "${c.base04}",
            branch_color = "${c.base04}",
            commit_color = "${c.base0E}",
            stashes_color = "${c.base0B}",
            state_color = "${c.base07}",
            staged_color = "${c.base0B}",
            unstaged_color = "${c.base0A}",
            untracked_color = "${c.base09}",
            ahead_color = "${c.base0B}",
            behind_color = "${c.base0A}",
          })
        '';
      }
      // (listToAttrs (
        map (
          plugin:
          let
            pluginName = plugin.pname or plugin.name;
            dirName = if lib.hasSuffix ".yazi" pluginName then pluginName else "${pluginName}.yazi";
          in
          {
            name = "yazi/plugins/${dirName}";
            value = {
              source = plugin;
            };
          }
        ) allPlugins
      ));
    };
  };
}
