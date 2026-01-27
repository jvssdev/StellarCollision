{
  programs.nvf.settings.vim.languages = {
    enableDAP = true;
    enableExtraDiagnostics = true;
    enableFormat = true;
    go.enable = true;
    bash = {
      enable = true;
    };
    ts = {
      enable = true;
      extensions.ts-error-translator.enable = true;
    };
    markdown = {
      enable = true;
      extensions = {
        markview-nvim = {
          enable = true;
        };
      };
    };
    nix = {
      enable = true;
      format.type = [ "nixfmt" ];
      lsp.servers = [ "nil" ];
    };
  };
}
