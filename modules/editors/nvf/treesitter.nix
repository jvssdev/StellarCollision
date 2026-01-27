{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    treesitter = {
      enable = true;
      autotagHtml = true;
      highlight.enable = true;
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        typescript
      ];
    };
    startPlugins = [
      pkgs.vimPlugins.lazy-nvim
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
        p.bash
        p.cmake
        p.css
        p.diff
        p.dockerfile
        p.gitignore
        p.go
        p.gomod
        p.gosum
        p.html
        p.http
        p.ini
        p.javascript
        p.json
        p.just
        p.lua
        p.make
        p.markdown
        p.markdown_inline
        p.meson
        p.ninja
        p.nix
        p.php
        p.python
        p.query
        p.regex
        p.sql
        p.toml
        p.yaml
      ]))
    ];
  };
}
