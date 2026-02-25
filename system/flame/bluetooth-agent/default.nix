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
  bluetooth-agent = common.overrideAttrs (oldAttrs: {
    meta = oldAttrs.meta or { } // {
      mainProgram = "bluetooth-agent";
    };
  });
  bluetooth-pair = common.overrideAttrs (oldAttrs: {
    meta = oldAttrs.meta or { } // {
      mainProgram = "bluetooth-pair";
    };
    postInstall = ''
      ln -s $out/bin/bluetooth-agent $out/bin/bluetooth-pair
    '';
  });
}
