{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.cfg.zen-browser;

  c = config.cfg.theme.colors;

  nur = import inputs.nur { inherit pkgs; };

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
    VisualSearchEnabled = false;
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
  };

  zen-unwrapped =
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.override
      {
        policies = customPolicies;
      };

  zen-wrapped = pkgs.wrapFirefox zen-unwrapped {
    icon = "zen-browser";
  };

  settings = {
    "apz.overscroll.enabled" = true;
    "browser.aboutConfig.showWarning" = false;
    "browser.download.start_downloads_in_tmp_dir" = true;
    "browser.ml.linkPreview.enabled" = true;
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
    "zen.welcome-screen.seen" = true;
    "zen.theme.gradient.show-custom-colors" = true;
    "zen.view.compact.hide-toolbar" = true;
    "zen.view.compact.enable-at-startup" = true;
    "zen.tabs.vertical.right-side" = true;
    "zen.view.use-single-toolbar" = false;
    "zen.workspaces.continue-where-left-off" = true;
    "zen.view.window.scheme" = 0;
    "devtools.theme" = "dark";
    "layout.css.prefers-color-scheme.content-override" = 0;
    "zen.theme.accent-color" = "#${c.base0D}";

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

  addons = nur.repos.rycee.firefox-addons;

  extensionsList = with addons; [
    ublock-origin
    darkreader
    keepassxc-browser
    sponsorblock
    betterttv
    vimium
    auto-tab-discard
  ];

  extensionFiles = lib.listToAttrs (
    builtins.map (ext: {
      name = ".zen/default/extensions/${ext.addonId}.xpi";
      value = {
        source = ext;
      };
    }) extensionsList
  );
in
{
  options.cfg.zen-browser = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Zen browser configuration.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = zen-wrapped;
      description = "The Zen browser package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      environment.sessionVariables = {
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_USE_XINPUT2 = "1";
      };

      files = {
        ".zen/profiles.ini".text = ''
          [General]
          StartWithLastProfile=1
          Version=2

          [Profile0]
          Name=default
          IsRelative=1
          Path=default
          Default=1
        '';

        ".zen/default/user.js".text = ''
          // Configurações adaptadas do seu profile original
          ${userJsContent}
        '';

        ".zen/default/chrome/userChrome.css".text = ''
          @-moz-document url("about:blank") {
            :root {
              background-color: #${c.base00} !important;
            }
          }

          @-moz-document url-prefix("about:") {
            :root {
              --zen-colors-border: #${c.base03} !important;
              --zen-colors-secondary: #${c.base02} !important;
              --zen-colors-tertiary: #${c.base03} !important;
              --zen-primary-color: #${c.base0D} !important;
              --in-content-page-background: #${c.base00} !important;
              --in-content-box-background: #${c.base01} !important;
              --in-content-box-border-color: #${c.base03} !important;
            }
          }

          @-moz-document url("about:newtab"), url("about:home") {
            :root {
              --newtab-background-color: #${c.base00} !important;
              --newtab-background-color-secondary: #${c.base01} !important;
              --newtab-element-hover-color: #${c.base02} !important;
              --newtab-text-primary-color: #${c.base05} !important;
              --newtab-wordmark-color: #${c.base05} !important;
              --newtab-primary-action-background: #${c.base0D} !important;
            }

            body {
              background-color: #${c.base00} !important;
            }

            .icon {
              color: #${c.base0D} !important;
            }

            .card-outer:is(:hover, :focus, .active):not(.placeholder) .card-title {
              color: #${c.base0D} !important;
            }

            .top-site-outer .search-topsite {
              background-color: #${c.base0D} !important;
            }

            .compact-cards .card-outer .card-context .card-context-icon.icon-download {
              fill: #${c.base0B} !important;
            }

            .top-sites-list .top-site-outer .tile {
              background-color: #${c.base01} !important;
            }
          }

          @-moz-document url-prefix("about:preferences") {
            :root {
              --zen-colors-tertiary: #${c.base03} !important;
              --in-content-text-color: #${c.base05} !important;
              --link-color: #${c.base0D} !important;
              --link-color-hover: #${c.base0C} !important;
              --zen-colors-primary: #${c.base01} !important;
              --in-content-box-background: #${c.base01} !important;
              --zen-primary-color: #${c.base0D} !important;
            }

            groupbox, moz-card {
              background: #${c.base01} !important;
              border: 1px solid #${c.base03} !important;
            }

            button,
            groupbox menulist {
              background: #${c.base02} !important;
              color: #${c.base05} !important;
              border: 1px solid #${c.base03} !important;
            }

            button:hover {
              background: #${c.base03} !important;
            }

            .main-content {
              background-color: #${c.base00} !important;
            }

            .identity-color-blue {
              --identity-tab-color: #${c.base0D} !important;
              --identity-icon-color: #${c.base0D} !important;
            }

            .identity-color-turquoise {
              --identity-tab-color: #${c.base0C} !important;
              --identity-icon-color: #${c.base0C} !important;
            }

            .identity-color-green {
              --identity-tab-color: #${c.base0B} !important;
              --identity-icon-color: #${c.base0B} !important;
            }

            .identity-color-yellow {
              --identity-tab-color: #${c.base0A} !important;
              --identity-icon-color: #${c.base0A} !important;
            }

            .identity-color-orange {
              --identity-tab-color: #${c.base09} !important;
              --identity-icon-color: #${c.base09} !important;
            }

            .identity-color-red {
              --identity-tab-color: #${c.base08} !important;
              --identity-icon-color: #${c.base08} !important;
            }

            .identity-color-pink {
              --identity-tab-color: #${c.base0E} !important;
              --identity-icon-color: #${c.base0E} !important;
            }

            .identity-color-purple {
              --identity-tab-color: #${c.base0F} !important;
              --identity-icon-color: #${c.base0F} !important;
            }
          }

          @-moz-document url-prefix("about:addons") {
            :root {
              --zen-dark-color-mix-base: #${c.base01} !important;
              --background-color-box: #${c.base00} !important;
              --in-content-box-background: #${c.base01} !important;
            }

            .addon-card {
              background-color: #${c.base01} !important;
              border: 1px solid #${c.base03} !important;
            }
          }

          @-moz-document url-prefix("about:protections") {
            :root {
              --zen-primary-color: #${c.base0D} !important;
              --social-color: #${c.base0E} !important;
              --coockie-color: #${c.base0D} !important;
              --fingerprinter-color: #${c.base0A} !important;
              --cryptominer-color: #${c.base0F} !important;
              --tracker-color: #${c.base0B} !important;
              --in-content-primary-button-background-hover: #${c.base03} !important;
              --in-content-primary-button-text-color-hover: #${c.base05} !important;
              --in-content-primary-button-background: #${c.base02} !important;
              --in-content-primary-button-text-color: #${c.base05} !important;
            }

            .card {
              background-color: #${c.base01} !important;
              border: 1px solid #${c.base03} !important;
            }

            body {
              background-color: #${c.base00} !important;
            }
          }
        '';
      }
      // extensionFiles;
    };
  };
}
