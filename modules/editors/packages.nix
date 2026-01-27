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
    hj.packages = with pkgs; [
      ripgrep
      fd
      tree-sitter
      imagemagick
      bash-language-server
      nil
      nixfmt
      pylyzer
      pyright
      ruff
      clang-tools
      lua-language-server
      yaml-language-server
      taplo
      marksman
      nodePackages_latest.typescript-language-server
      nodePackages_latest.vscode-langservers-extracted
      qt6.qtdeclarative
      qt6.qttools
      just-lsp
      gopls
      sqls
      cmake-language-server
      docker-compose-language-service
      dockerfile-language-server
      zls
      delve
      lldb
      stylua
      shfmt
      prettierd
      cmake-format
      gotools
      black
      rustfmt
      biome
      gcc
      gnumake
      cargo
      rustc
      tree-sitter
      nodejs_22
      zig
      go
    ];
  };
}
