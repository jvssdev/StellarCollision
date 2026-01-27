{
  programs.nvf.settings.vim = {
    formatter = {
      conform-nvim = {
        enable = true;
        setupOpts.formatters_by_ft = {
          nix = [ "nixfmt" ];
        };
      };
    };

    keymaps = [
      {
        key = "<leader>lf";
        action = "require('conform').format";
        mode = "n";
        silent = true;
        nowait = true;
        lua = true;
      }
    ];
  };
}
