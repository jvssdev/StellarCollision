{ lib, buildGoModule }:

buildGoModule {
  pname = "bluetooth-agent";
  version = "unstable";
  src = ./.;

  vendorHash = "sha256-WUTGAYigUjuZLHO1YpVhFSWpvULDZfGMfOXZQqVYAfs=";
}
