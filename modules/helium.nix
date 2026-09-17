{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.cfg.helium;

  inherit (lib.attrsets) mapAttrsToList filterAttrs;
  inherit (lib.lists) singleton;

  extensions = {
    dark-reader = {
      id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    };
    ublock-origin = {
      id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      policy.toOverwrite.filterLists = [
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
    };
    violentmonkey = {
      id = "jinjaccalgkegednnccohejagnlnfdag";
    };
    vimium = {
      id = "dbepggeogbaibhgnhhndojpepiihcmeb";
    };
    seven-tv = {
      id = "ammjkodgmmoknidbanneddgankgfejfh";
    };
    i-still-dont-care-about-cookies = {
      id = "edibdbjcniadpccecjdfdjjppcpchdlm";
    };
    clearurls = {
      id = "lckanjgmijmafbedllaakclkaicjfmnk";
    };
    bypass-paywalls = {
      id = "lkbebcjgcmobigpeffafkodonchffocl";
    };
    control-panel-for-youtube = {
      id = "lodcanccmfbpjjpnngindkkmiehimile";
    };
  };

  forcelist = mapAttrsToList (_: ext: ext.id) (
    filterAttrs (_: ext: !(ext.preinstalled or false)) extensions
  );

  policy = {
    ExtensionInstallBlocklist = singleton "*";
    ExtensionInstallAllowlist = forcelist;
    ExtensionInstallForcelist = forcelist;

    ExtensionInstallSources = [
      "https://services.helium.imput.net/*"
      "https://gitflic.ru/*"
    ];

    ExtensionSettings = lib.concatMapAttrs (
      _: ext: lib.optionalAttrs (ext ? settings) { ${ext.id} = ext.settings; }
    ) extensions;

    "3rdparty".extensions = lib.concatMapAttrs (
      _: ext: lib.optionalAttrs (ext ? policy) { ${ext.id} = ext.policy; }
    ) extensions;

    DefaultBrowserSettingEnabled = false;
    DnsOverHttpsMode = "automatic";
    HttpsOnlyMode = "allowed";
    MetricsReportingEnabled = false;

    RestoreOnStartup = 1;

    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}";
    SearchSuggestEnabled = true;
  };

  helium-unwrapped = inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium;

  helium-assets = pkgs.runCommand "helium-assets" { } ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/helium.desktop <<EOF
    [Desktop Entry]
    Name=Helium
    Exec=helium %U
    Terminal=false
    Type=Application
    Icon=helium
    StartupWMClass=Helium
    Comment=A private, fast, and honest web browser
    MimeType=text/html;text/xml;application/xhtml+xml;application/xml;x-scheme-handler/http;x-scheme-handler/https;
    Categories=Network;WebBrowser;
    EOF

    for size in 16 32 48 64 128 256; do
      icon=$(find "${helium-unwrapped}" -name "product_logo_''${size}.png" 2>/dev/null | head -1)
      if [ -z "$icon" ]; then
        icon=$(find "${helium-unwrapped}" -name "product_logo_48.png" 2>/dev/null | head -1)
      fi
      if [ -n "$icon" ]; then
        dest="$out/share/icons/hicolor/''${size}x''${size}/apps"
        mkdir -p "$dest"
        cp "$icon" "$dest/helium.png"
      fi
    done
  '';

  heliumPrefsScript = pkgs.writeShellScript "helium-set-prefs" ''
    set -euo pipefail
    PREFS_DIR="$HOME/.config/net.imput.helium/Default"
    PREFS_FILE="$PREFS_DIR/Preferences"
    mkdir -p "$PREFS_DIR"

    if [ ! -f "$PREFS_FILE" ] || ! ${pkgs.jq}/bin/jq empty "$PREFS_FILE" 2>/dev/null; then
      echo '{}' > "$PREFS_FILE"
    fi

    ${pkgs.jq}/bin/jq '
      .browser.custom_chrome_frame = false
      | .helium.completed_onboarding = true
      | .helium.services.user_consented = true
      | .download.prompt_for_download = true
    ' "$PREFS_FILE" > "$PREFS_FILE.tmp" \
      && mv "$PREFS_FILE.tmp" "$PREFS_FILE"
  '';

  helium-launcher = pkgs.writeShellScriptBin "helium" ''
    ${heliumPrefsScript}
    exec ${helium-unwrapped}/bin/helium "$@" 2> >(${pkgs.gnugrep}/bin/grep -v 'Could not load icon' >&2)
  '';
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
      packages = [
        helium-launcher
        helium-assets
        pkgs.jq
      ];
    };

    environment.etc = {
      "chromium/policies/managed/policies.json".text = builtins.toJSON policy;
      "helium/policies/managed/policies.json".text = builtins.toJSON policy;
    };
  };
}
