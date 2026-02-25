{ lib, buildGoModule }:

let
  common = buildGoModule {
    pname = "bluetooth-agent";
    version = "unstable";
    src = ./.;
    vendorHash = "sha256-WUTGAYigUjuZLHO1YpVhFSWpvULDZfGMfOXZQqVYAfs=";
  };
in
rec {
  bluetooth-agent = common;
  bluetooth-pair = common.overrideAttrs (oldAttrs: {
    postInstall = ''
      ln -s $out/bin/bluetooth-agent $out/bin/bluetooth-pair
    '';
  });
}
