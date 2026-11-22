{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cfg.virtualisation;
in
{
  options.cfg.virtualisation = {
    enable = mkEnableOption "virtualisation configuration";
  };
  config = mkIf cfg.enable {

    hj = {
      packages = [
        pkgs.libvirt
        pkgs.qemu_kvm
        pkgs.virt-viewer
        pkgs.virt-manager
        pkgs.spice
        pkgs.spice-gtk
        pkgs.spice-protocol
        pkgs.virglrenderer
        pkgs.mesa
        pkgs.waydroid
        pkgs.lxc
      ];
    };

    systemd.services.virt-secret-init-encryption = {
      serviceConfig.ExecStart = lib.mkForce "${pkgs.writeShellScript "virt-secret-init-encryption" ''
        umask 0077
        ${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 \
          | ${config.systemd.package}/bin/systemd-creds encrypt --name=secrets-encryption-key \
              - /var/lib/libvirt/secrets/secrets-encryption-key
      ''}";
    };
    systemd.services.libvirt-guests.enable = false;
    virtualisation = {
      docker = {
        enable = false;
      };
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          swtpm.enable = true;
          runAsRoot = false;
          verbatimConfig = ''
            user = "${config.cfg.vars.username}"
            group = "libvirtd"
          '';
        };
      };
      spiceUSBRedirection.enable = true;
      waydroid = {
        enable = true;
        package = pkgs.waydroid-nftables;
      };
    };
  };
}
