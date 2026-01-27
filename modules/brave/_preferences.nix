{
  brave = {
    de_amp.enabled = true;
    debounce.enabled = true;
    reduce_language = true;
    webtorrent_enabled = false;
    gcm.channel_status = false;
    webcompat.report.enable_save_contact_info = false;
    omnibox.bookmark_suggestions_enabled = false;
    omnibox.commander_suggestions_enabled = false;
    top_site_suggestions_enabled = false;
    shields.stats_badge_visible = false;
    brave_ads.should_allow_ads_subdivision_targeting = false;
    rewards.badge_text = "";
    rewards.show_brave_rewards_button_in_location_bar = false;
    today.should_show_toolbar_button = false;
    wallet.show_wallet_icon_on_toolbar = false;
    show_fullscreen_reminder = false;
    show_side_panel_button = false;
    show_bookmarks_button = false;
    tabs = {
      hover_mode = 2;
      vertical_tabs_enabled = true;
      vertical_tabs_collapsed = true;
      vertical_tabs_on_right = true;
      vertical_tabs_show_title_bar = false;
      vertical_tabs_expand_on_hover = true;
      vertical_tabs_expand_independently = false;
      vertical_tabs_show_scrollbar = false;
    };
  };

  safety_hub.unused_site_permissions_revocation.enabled = false;
  enable_do_not_track = true;

  profile = {
    content_settings = {
      exceptions = {
        cosmeticFiltering."*,*".setting = 2;
        cosmeticFiltering."*,https://firstparty".setting = 2;
        fingerprintingV2."*,*".setting = 3;
        shieldsAds."*,*".setting = 3;
        trackers."*,*".setting = 3;
      };
    };
    cookie_controls_mode = 1;
    default_content_setting_values.httpsUpgrades = 2;
    default_content_setting_values.javascript_jit = 2;
  };

  https_only_mode_enabled = true;
  search.suggest_enabled = false;
  extensions.theme.system_theme = 1;
}
