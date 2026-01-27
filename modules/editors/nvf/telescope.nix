{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    telescope = {
      enable = true;
      extensions = [
        {
          name = "fzf";
          packages = [ pkgs.vimPlugins.telescope-fzf-native-nvim ];
          setup = {
            fzf = {
              fuzzy = true;
              override_generic_sorter = true;
              override_file_sorter = true;
              case_mode = "smart_case";
            };
          };
        }
      ];
      mappings = {
        buffers = "<leader>.";
        diagnostics = "<leader>sd";
        findFiles = "<leader>sf";
        liveGrep = "<leader>sg";
        lspDefinitions = "grd";
        lspDocumentSymbols = "gO";
        lspImplementations = "gri";
        lspReferences = "grr";
        lspTypeDefinitions = "grt";
        lspWorkspaceSymbols = "gW";
        resume = "<leader>sr";
        treesitter = "<leader>ss";
      };
    };
  };
}
