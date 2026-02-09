{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    ;
  cfg = config.cfg.opencode;
  c = config.cfg.theme.colors;
in
{
  options.cfg.opencode = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable opencode configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.opencode;
      description = "The opencode package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      xdg.config.files = {
        "opencode/opencode.json".text = ''
          {
            "$schema": "https://opencode.ai/config.json",
            "theme": "theme",
            "provider": {},
            "model": "anthropic/claude-sonnet-4-5",
            "small_model": "anthropic/claude-haiku-4-5"
          }
        '';

        "opencode/themes/theme.json".text = ''
          {
            "$schema": "https://opencode.ai/theme.json",
            "defs": {
              "theme0": "${c.base00}",
              "theme1": "${c.base01}",
              "theme2": "${c.base02}",
              "theme3": "${c.base03}",
              "theme4": "${c.base04}",
              "theme5": "${c.base05}",
              "theme6": "${c.base06}",
              "theme7": "${c.base07}",
              "theme8": "${c.base08}",
              "theme9": "${c.base09}",
              "theme10": "${c.base0A}",
              "theme11": "${c.base0B}",
              "theme12": "${c.base0C}",
              "theme13": "${c.base0D}",
              "theme14": "${c.base0E}",
              "theme15": "${c.base0F}"
            },
            "theme": {
              "primary": {
                "dark": "theme12",
                "light": "theme13"
              },
              "secondary": {
                "dark": "theme13",
                "light": "theme13"
              },
              "accent": {
                "dark": "theme11",
                "light": "theme11"
              },
              "error": {
                "dark": "theme8",
                "light": "theme8"
              },
              "warning": {
                "dark": "theme9",
                "light": "theme9"
              },
              "success": {
                "dark": "theme11",
                "light": "theme11"
              },
              "info": {
                "dark": "theme12",
                "light": "theme13"
              },
              "text": {
                "dark": "theme4",
                "light": "theme0"
              },
              "textMuted": {
                "dark": "theme3",
                "light": "theme1"
              },
              "background": {
                "dark": "theme0",
                "light": "theme6"
              },
              "backgroundPanel": {
                "dark": "theme1",
                "light": "theme5"
              },
              "backgroundElement": {
                "dark": "theme1",
                "light": "theme4"
              },
              "border": {
                "dark": "theme2",
                "light": "theme3"
              },
              "borderActive": {
                "dark": "theme3",
                "light": "theme2"
              },
              "borderSubtle": {
                "dark": "theme2",
                "light": "theme3"
              },
              "diffAdded": {
                "dark": "theme11",
                "light": "theme11"
              },
              "diffRemoved": {
                "dark": "theme8",
                "light": "theme8"
              },
              "diffContext": {
                "dark": "theme3",
                "light": "theme3"
              },
              "diffHunkHeader": {
                "dark": "theme3",
                "light": "theme3"
              },
              "diffHighlightAdded": {
                "dark": "theme11",
                "light": "theme11"
              },
              "diffHighlightRemoved": {
                "dark": "theme8",
                "light": "theme8"
              },
              "diffAddedBg": {
                "dark": "${c.base01}",
                "light": "${c.base05}"
              },
              "diffRemovedBg": {
                "dark": "${c.base01}",
                "light": "${c.base05}"
              },
              "diffContextBg": {
                "dark": "theme1",
                "light": "theme5"
              },
              "diffLineNumber": {
                "dark": "theme2",
                "light": "theme4"
              },
              "diffAddedLineNumberBg": {
                "dark": "${c.base01}",
                "light": "${c.base05}"
              },
              "diffRemovedLineNumberBg": {
                "dark": "${c.base01}",
                "light": "${c.base05}"
              },
              "markdownText": {
                "dark": "theme4",
                "light": "theme0"
              },
              "markdownHeading": {
                "dark": "theme12",
                "light": "theme13"
              },
              "markdownLink": {
                "dark": "theme13",
                "light": "theme13"
              },
              "markdownLinkText": {
                "dark": "theme11",
                "light": "theme11"
              },
              "markdownCode": {
                "dark": "theme11",
                "light": "theme11"
              },
              "markdownBlockQuote": {
                "dark": "theme3",
                "light": "theme3"
              },
              "markdownEmph": {
                "dark": "theme9",
                "light": "theme9"
              },
              "markdownStrong": {
                "dark": "theme10",
                "light": "theme10"
              },
              "markdownHorizontalRule": {
                "dark": "theme3",
                "light": "theme3"
              },
              "markdownListItem": {
                "dark": "theme12",
                "light": "theme13"
              },
              "markdownListEnumeration": {
                "dark": "theme11",
                "light": "theme11"
              },
              "markdownImage": {
                "dark": "theme13",
                "light": "theme13"
              },
              "markdownImageText": {
                "dark": "theme11",
                "light": "theme11"
              },
              "markdownCodeBlock": {
                "dark": "theme4",
                "light": "theme0"
              },
              "syntaxComment": {
                "dark": "theme3",
                "light": "theme3"
              },
              "syntaxKeyword": {
                "dark": "theme13",
                "light": "theme13"
              },
              "syntaxFunction": {
                "dark": "theme12",
                "light": "theme12"
              },
              "syntaxVariable": {
                "dark": "theme11",
                "light": "theme11"
              },
              "syntaxString": {
                "dark": "theme11",
                "light": "theme11"
              },
              "syntaxNumber": {
                "dark": "theme14",
                "light": "theme14"
              },
              "syntaxType": {
                "dark": "theme11",
                "light": "theme11"
              },
              "syntaxOperator": {
                "dark": "theme13",
                "light": "theme13"
              },
              "syntaxPunctuation": {
                "dark": "theme4",
                "light": "theme0"
              }
            }
          }
        '';
      };
    };
  };
}
