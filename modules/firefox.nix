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
          "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium-ff";
          "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = "auto-tab-discard";
        };
  };

  firefox-wrapped = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPolicies = customPolicies;
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
    "browser.startup.page" = 3;
    "devtools.theme" = "dark";
    "layout.css.prefers-color-scheme.content-override" = 0;
    "layout.css.devPixelsPerPx" = "1.0";
    "browser.search.defaultenginename" = "DuckDuckGo";
    "browser.search.defaultenginename.private" = "DuckDuckGo";
  };

  userJsContent = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: value:
      let
        valStr =
          if builtins.isBool value then
            (if value then "true" else "false")
          else if builtins.isInt value then
            builtins.toString value
          else
            ''"${value}"'';
      in
      ''user_pref("${name}", ${valStr});''
    ) settings
  );
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

      files = {
        ".mozilla/firefox/profiles.ini".text = ''
          [General]
          StartWithLastProfile=1
          Version=2

          [Profile0]
          Name=default
          IsRelative=1
          Path=default
          Default=1
        '';

        ".mozilla/firefox/default/user.js".text = userJsContent;
      };
    };
  };
}
