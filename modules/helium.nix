{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.cfg.helium;

  inherit (lib) fix;
  inherit (lib.attrsets) attrNames mapAttrsToList;
  inherit (lib.lists) elem singleton;
  inherit (lib.strings) hasInfix;

  extensions = {
    dark-reader = {
      id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    };
    sponsorblock = {
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
    };
    ublock-origin = fix (self: {
      id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      filters = {

        internal = attrNames (builtins.fromJSON (builtins.readFile "${inputs.ublock}/assets/assets.json"));

        wanted = [
          "user-filters"
          "ublock-filters"
          "ublock-badware"
          "ublock-privacy"
          "ublock-abuse"
          "ublock-unbreak"
          "easylist"
          "easyprivacy"
          "urlhaus-1"
          "plowe-0"

          "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/ClearURLs%20for%20uBo/clear_urls_uboified.txt"
          "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/privacy_essentials.txt"
          "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt"
          "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/annoyance_list.txt"
          "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/BrowseWebsitesWithoutLoggingIn.txt"
        ];

        warnings = builtins.filter (
          name: !(hasInfix "://" name || elem name self.filters.internal)
        ) self.filters.wanted;
      };
    });
    violentmonkey = {
      id = "jinjaccalgkegednnccohejagnlnfdag";
    };
    vimium = {
      id = "dbepggeogbaibhgnhhndojpepiihcmeb";
    };
    bettertv = {
      id = "ajopnjidmegmdimjlfnijceegpefgped";
    };
  };

  policy = {
    ExtensionInstallForcelist = mapAttrsToList (
      _: ext: "${ext.id};https://services.helium.imput.net/ext"
    ) extensions;
    ExtensionInstallAllowlist = mapAttrsToList (_: ext: ext.id) extensions;
    ExtensionInstallSources = singleton "https://services.helium.imput.net/*";

    "3rdparty".extensions.${extensions.ublock-origin.id}.toOverwrite.filterLists =
      extensions.ublock-origin.filters.wanted;

    DefaultBrowserSettingEnabled = false;
    RestoreOnStartup = 1; # 5 = Open New Tab Page, 1 = Restore the last session, 4 = Open list of URLs, 6 = 1 + 4
    DnsOverHttpsMode = "secure";
    HttpsOnlyMode = "allowed";
    GtkThemeModeEnabled = true;
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}";
    SearchSuggestEnabled = true;
  };

  helium-unwrapped = inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium;
in
{
  options.cfg.helium = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Helium browser configuration.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = helium-unwrapped;
      description = "The Helium browser package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];
    };

    environment.etc."chromium/policies/managed/policies.json".text = lib.generators.toJSON { } policy;
  };
}
