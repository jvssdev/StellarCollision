{ config, ... }:
{
  users = {
    users.${config.cfg.vars.username} = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "libvirtd"
        "kvm"
        "video"
        "input"
      ];
    };
  };
}
