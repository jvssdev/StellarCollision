{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernel.sysctl = {
      "kernel.sysrq" = 0;
      "kernel.kptr_restrict" = 2;
      "net.core.bpf_jit_enable" = false;
      "kernel.ftrace_enabled" = false;
      "kernel.dmesg_restrict" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;
      "kernel.perf_event_paranoid" = 3;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
    };

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
      "acpi_osi=Linux"
      "pci=noaer"
      "fbcon=nodefer"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "slab_nomerge"
      "module.sig_enforce=1"
      "page_poison=1"
      "page_alloc.shuffle=1"
      "sysrq_always_enabled=0"
      "rootflags=noatime"
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"
      "i915.enable_fbc=0"
      "i915.disable_power_well=0"
    ];

    blacklistedKernelModules = [
      "af_802154"
      "appletalk"
      "atm"
      "ax25"
      "can"
      "dccp"
      "decnet"
      "econet"
      "ipx"
      "n-hdlc"
      "netrom"
      "p8022"
      "p8023"
      "psnap"
      "rds"
      "rose"
      "sctp"
      "tipc"
      "x25"
      "adfs"
      "affs"
      "befs"
      "bfs"
      "cramfs"
      "efs"
      "erofs"
      "exofs"
      "freevxfs"
      "gfs2"
      "hfs"
      "hfsplus"
      "hpfs"
      "jffs2"
      "jfs"
      "ksmbd"
      "minix"
      "nilfs2"
      "omfs"
      "qnx4"
      "qnx6"
      "sysv"
      "udf"
      "vivid"
      "firewire-core"
      "thunderbolt"
    ];
  };
}
