{ pkgs, ... }:

{
  icon-resolver = pkgs.buildGoModule {
    pname = "icon-resolver";
    version = "0.1.0";
    src = ./icon-resolver;
    vendorHash = null;
    meta = {
      description = "XDG icon theme resolver for Quickshell";
      mainProgram = "icon-resolver";
    };
  };
}
