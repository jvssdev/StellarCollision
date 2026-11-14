{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cfg.firefox;

  customPolicies = {
    AutofillCreditCardEnabled = false;
    AutofillAddressEnabled = false;
    DisableFirefoxStudies = true;
    DisableFeedbackCommands = true;
    DisableTelemetry = true;
    DisableMasterPasswordCreation = true;
    DisplayBookmarksToolbar = "never";
    DontCheckDefaultBrowser = true;
    OfferToSaveLogins = false;
    PasswordManagerEnabled = false;
    NoDefaultBookmarks = true;
    PrimaryPassword = false;
    SkipTermsOfUse = true;
    DisablePocket = true;
    DisableAppUpdate = true;
    WindowsSSO = false;

    HttpsOnlyMode = "force_enabled";

    SearchEngines.Default = "DuckDuckGo";

    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
      EmailTracking = true;
      Category = "strict";
    };

    FirefoxHome = {
      Search = false;
      TopSites = false;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      Stories = false;
      SponsoredPocket = false;
      SponsoredStories = false;
      Snippets = false;
      Locked = true;
    };

    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
      Locked = true;
    };

    GenerativeAI = {
      Enabled = false;
      Chatbot = false;
      LinkPreviews = false;
      TabGroups = false;
      Locked = true;
    };

    AIControls = {
      Default = {
        Value = "blocked";
        Locked = true;
      };
    };

    Homepage = {
      StartPage = "none";
      Locked = true;
    };

    UserMessaging = {
      WhatsNew = false;
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      UrlbarInterventions = false;
      SkipOnBoarding = false;
      MoreFromMozilla = false;
      FirefoxLabs = false;
    };

    Preferences = {
      "browser.toolbars.bookmarks.visibility" = {
        Value = "never";
        Status = "locked";
      };
      "browser.tabs.unloadOnLowMemory" = {
        Value = true;
        Status = "default";
      };
      "browser.ctrlTab.sortByRecentlyUsed" = {
        Value = true;
        Status = "default";
      };
      "browser.tabs.warnOnClose" = {
        Value = false;
        Status = "default";
      };
      "breakpad.reportURL" = {
        Value = "";
        Status = "locked";
      };
      "browser.tabs.crashReporting.sendReport" = {
        Value = false;
        Status = "locked";
      };
      "browser.crashReports.unsubmittedCheck.autoSubmit2" = {
        Value = false;
        Status = "locked";
      };
    };
    ExtensionSettings = {
      "*" = {
        installation_mode = "allowed";
      };
      "firefox-oled@oled.firefox" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/firefox-oled/latest.xpi";
      };
    }
    //
      lib.mapAttrs'
        (name: slug: {
          inherit name;
          value = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
          };
        })
        {
          "uBlock0@raymondhill.net" = "ublock-origin";
          "addon@darkreader.org" = "darkreader";
          "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
          "sponsorblocker@ajay.app" = "sponsorblock";
          "seventv-next@7tv.app" = "7tv-new";
          "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = "auto-tab-discard";
          "control-panel-for-youtube@jbscript.dev" = "control-panel-for-youtube";
        };
  };

  settings = {
    "apz.overscroll.enabled" = true;
    "browser.aboutConfig.showWarning" = false;
    "browser.download.start_downloads_in_tmp_dir" = true;
    "browser.search.isUS" = true;
    "browser.tabs.groups.enabled" = true;
    "browser.tabs.groups.smart.enabled" = true;
    "cookiebanners.service.mode.privateBrowsing" = 2;
    "cookiebanners.service.mode" = 2;
    "cookiebanners.ui.desktop.enabled" = 2;
    "distribution.searchplugins.defaultLocale" = "en-US";
    "extensions.autoDisableScopes" = 0;
    "general.useragent.locale" = "en-US";
    "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = false;
    "devtools.debugger.remote-enabled" = true;
    "devtools.chrome.enabled" = true;
    "browser.display.os-zoom-behavior" = 0;
    "sidebar.verticalTabs" = true;
    "sidebar.visibility" = "hide-sidebar";
    "browser.tabs.inTitlebar" = 0;
    "browser.tabs.insertAfterCurrent" = true;
    "browser.link.open_newwindow.override.external" = 7;
    "media.eme.enabled" = true;
    "browser.startup.page" = 3;
    "devtools.theme" = "dark";
    "layout.css.prefers-color-scheme.content-override" = 0;
    "layout.css.devPixelsPerPx" = "1.0";
    "browser.uidensity" = 1;
    "browser.search.defaultenginename" = "DuckDuckGo";
    "browser.search.defaultenginename.private" = "DuckDuckGo";
    "browser.ai.control.default" = "blocked";
    "browser.ai.control.sidebarChatbot" = "blocked";
    "browser.ai.control.linkPreviewKeyPoints" = "blocked";
    "browser.ai.control.smartTabGroups" = "blocked";
    "browser.ai.control.translations" = "blocked";
    "browser.ai.control.pdfjsAltText" = "blocked";
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.was_ever_enabled" = true;
    "privacy.donottrackheader.enabled" = true;
  };

  prefsContent = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "pref(${builtins.toJSON name}, ${builtins.toJSON value});") settings
  );

  firefox-wrapped = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPolicies = customPolicies;
    extraPrefs = prefsContent;
  };

  profilesIni = pkgs.writeText "profiles.ini" ''
    [General]
    StartWithLastProfile=1
    Version=2

    [Profile0]
    Name=default
    IsRelative=1
    Path=default
    Default=1
  '';

  customKeysFile = pkgs.writeText "customKeys.json" (
    builtins.toJSON {
      toggleSidebarKb = {
        modifiers = "accel";
        key = "E";
      };
    }
  );

  syncScript = ''
    root="$HOME/.mozilla/firefox"
    ini="$root/profiles.ini"
    mkdir -p "$root"
    if [ -L "$ini" ] || [ ! -e "$ini" ]; then
      rm -f "$ini"
      install -m 0644 ${profilesIni} "$ini"
    fi
    awk -v root="$root" '
      /^\[/ {
        if (path != "") print (rel == "0" ? path : root "/" path)
        path = ""
        rel = "1"
        next
      }
      /^IsRelative=/ { sub(/^IsRelative=/, ""); rel = $0 }
      /^Path=/ { sub(/^Path=/, ""); path = $0 }
      END { if (path != "") print (rel == "0" ? path : root "/" path) }
    ' "$ini" | while IFS= read -r dir; do
      mkdir -p "$dir"
      install -m 0644 ${customKeysFile} "$dir/customKeys.json"
    done
    for dir in "$root"/*/; do
      if [ -f "$dir/prefs.js" ]; then
        install -m 0644 ${customKeysFile} "$dir/customKeys.json"
      fi
    done
  '';
in
{
  options.cfg.firefox = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Firefox configuration.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = firefox-wrapped;
      description = "The Firefox package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      systemd.services.firefox-profiles = {
        description = "Seed profiles.ini and copy customKeys.json into every Firefox profile";
        wantedBy = [ "default.target" ];
        path = [
          pkgs.gawk
          pkgs.coreutils
        ];
        serviceConfig.Type = "oneshot";
        script = syncScript;
      };

      systemd.paths.firefox-profiles = {
        description = "Watch Firefox profiles.ini for changes";
        wantedBy = [ "default.target" ];
        pathConfig.PathChanged = [
          "%h/.mozilla/firefox/profiles.ini"
          "%h/.mozilla/firefox"
        ];
      };
    };
  };
}
