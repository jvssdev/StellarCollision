{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.cfg.editorPackages;
in

{
  options.cfg.editorPackages = {
    enable = mkEnableOption "Packages for editors";
  };

  config = mkIf cfg.enable {
    hj.packages = [
      pkgs.ripgrep
      pkgs.fd
      pkgs.tree-sitter
      pkgs.imagemagick
      pkgs.bash-language-server
      pkgs.nil
      pkgs.nixfmt
      pkgs.pylyzer
      pkgs.pyright
      pkgs.ruff
      pkgs.clang-tools
      pkgs.lua-language-server
      pkgs.yaml-language-server
      pkgs.taplo
      pkgs.marksman
      #pkgs.nodePackages_latest.typescript-language-server
      #pkgs.nodePackages_latest.vscode-langservers-extracted
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qttools
      pkgs.just-lsp
      pkgs.gopls
      pkgs.sqls
      pkgs.cmake-language-server
      pkgs.docker-compose-language-service
      pkgs.dockerfile-language-server
      pkgs.zls
      pkgs.delve
      pkgs.lldb
      pkgs.stylua
      pkgs.shfmt
      pkgs.prettierd
      pkgs.cmake-format
      pkgs.gotools
      pkgs.black
      pkgs.rustfmt
      pkgs.biome
      pkgs.python314
      pkgs.gcc
      pkgs.gnumake
      pkgs.cargo
      pkgs.rustc
      pkgs.tree-sitter
      pkgs.nodejs_22
      pkgs.zig
      pkgs.go
    ];
  };
}
