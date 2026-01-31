{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.cfg.vars = {
    email = mkOption {
      type = types.str;
      default = "joao.victor.ss.dev@gmail.com";
    };

    name = mkOption {
      type = types.str;
      default = "João Víctor Santos Silva";
    };

    username = mkOption {
      type = types.str;
      default = "joaov";
    };

    homeDirectory = mkOption {
      type = types.str;
      default = "/home/${config.cfg.vars.username}";
    };

    terminal = mkOption {
      type = types.str;
      default = "wezterm";
    };

    browser = mkOption {
      type = types.str;
      default = "zen-beta";
    };

    stateVersion = mkOption {
      type = types.str;
      default = "25.11";
    };

    timezone = mkOption {
      type = types.str;
      default = "America/Sao_Paulo";
    };

    withGui = mkOption {
      type = types.bool;
      default = false;
    };

    isALaptop = mkOption {
      type = types.bool;
      default = false;
    };
  };
}
