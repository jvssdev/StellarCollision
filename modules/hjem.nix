{
  inputs,
  inputs',
  lib,
  config,
  ...
}:
{
  options.cfg.hjem = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hjem configuration";
    };
  };

  imports = [
    inputs.hjem.nixosModules.default
    (lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" config.cfg.vars.username ])
  ];

  config = lib.mkIf config.cfg.hjem.enable {
    hjem = {
      clobberByDefault = true;
      linker = inputs'.hjem.packages.smfh;
      users = {
        "${config.cfg.vars.username}" = {
          user = "${config.cfg.vars.username}";
          directory = "/home/${config.cfg.vars.username}";
        };
      };
    };
  };
}
