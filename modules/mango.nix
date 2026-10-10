{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    getExe
    getExe'
    ;
  cfg = config.cfg.mango;
  c = config.cfg.theme.colors;

  strip = color: lib.substring 1 6 color;
  hexToMango = hex: "0x${hex}ff";
  colorToMango = color: hexToMango (strip color);

  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.cfg.mango = {
    enable = mkEnableOption "Enable MangoWC configuration.";
  };

  imports = [ inputs.mango.nixosModules.mango ];

  config = mkIf cfg.enable {
    programs.mango = {
      enable = true;
      package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;
    };

    hj.packages = [
      pkgs.xrdb
    ];

    hj.xdg.config.files."mango/config.conf".text = ''
      exec_once="${getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots"
      exec_once=systemctl --user reset-failed
      exec_once=systemctl --user start mango-session.target
      exec_once = "${getExe pkgs.xwayland-satellite}"
      exec_once = "sh -c 'sleep 1; echo \"Xft.dpi: 140\" | ${getExe' pkgs.xrdb "xrdb"} -merge'"
      exec_once = "${getExe' pkgs.networkmanagerapplet "nm-applet"} --indicator"
      exec_once = "${getExe quickshell}"
      exec_once = ${getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${getExe pkgs.cliphist} store
      exec_once = ${getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch ${getExe pkgs.cliphist} store
      exec_once = ${getExe pkgs.wl-clip-persist} --clipboard regular --reconnect-tries 0
      exec_once = "${getExe pkgs.fcitx5} -d --replace"

      env=WLR_NO_HARDWARE_CURSORS,1
      env=QT_AUTO_SCREEN_SCALE_FACTOR,1
      env=QT_QPA_PLATFORM,wayland;xcb
      env=QT_WAYLAND_DISABLE_WINDOWDECORATION,1
      env=XDG_SESSION_TYPE,wayland
      env=GDK_BACKEND,wayland,x11
      env=CLUTTER_BACKEND,wayland
      env=MOZ_ENABLE_WAYLAND,1
      env=ELECTRON_OZONE_PLATFORM_HINT,auto
      env=XCURSOR_THEME,Bibata-Modern-Ice
      env=XCURSOR_SIZE,24
      env=DISPLAY,:0
      env=QT_IM_MODULE,fcitx
      env=SDL_IM_MODULE,fcitx
      env=XMODIFIERS,@im=fcitx
      env=GLFW_IM_MODULE,ibus
      env=QT_QPA_PLATFORMTHEME,qt5ct
      env=QT_WAYLAND_FORCE_DPI,140
      env=GDK_DPI_SCALE,1.45

      monitor_rule=name:^eDP-1$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1,rr:0
      xkb_rules_layout=br
      xkb_rules_variant=abnt2
      cursor_size=24
      cursor_theme=Bibata-Modern-Ice
      gap_inner_horizontal=5
      gap_inner_vertical=5
      gap_outer_horizontal=5
      gap_outer_vertical=5
      border_px=3
      border_radius=12
      no_border_when_single=1
      no_radius_when_single=0
      root_color=${colorToMango c.base00}
      border_color=${colorToMango c.base02}
      focus_color=${colorToMango c.base0D}
      urgent_color=${colorToMango c.base08}
      repeat_rate=50
      repeat_delay=300
      warp_cursor=1
      new_is_master=0
      smart_gaps=1
      cursor_hide_timeout=5000
      trackpad_natural_scrolling=0
      animation_duration_move=150
      animation_duration_open=150
      animation_duration_tag=0
      animation_duration_close=150
      animation_duration_focus=150
      animation_curve_open=0.22,1.0,0.36,1
      animation_curve_move=0.46,1.0,0.29,1
      animation_curve_tag=0.65,0,0.35,1
      animation_curve_close=0.08,0.92,0,1
      animation_curve_focus=0.46,1.0,0.29,1

      animation_fade_in=1
      animation_fade_out=1
      tag_animation_direction=0
      animations=1
      layer_animations=1
      animation_type_open=zoom
      animation_type_close=slide
      layer_animation_type_open=zoom
      layer_animation_type_close=slide
      zoom_initial_ratio=0.3
      zoom_end_ratio=0.7
      fade_in_begin_opacity=0.5
      fade_out_begin_opacity=0.8
      blur=1
      blur_layer=1
      blur_optimized=1
      blur_params_num_passes = 2
      blur_params_radius = 3
      blur_params_noise = 0.02
      blur_params_brightness = 1
      blur_params_contrast = 0.9
      blur_params_saturation = 1.5
      shadows=1
      layer_shadows = 0
      shadow_only_floating=1
      shadows_size=10
      shadows_blur=15
      shadows_position_x = 0
      shadows_position_y = 0
      shadows_color=${colorToMango c.base00}
      scroller_structs=0
      scroller_default_proportion=1.0
      scroller_focus_center=0
      scroller_prefer_center=1
      scroller_default_proportion_single=1.0

      tag_rule=id:*,layout_name:tile,master_count:1,master_factor:0.5

      bind=SUPER,r,reload_config
      bind=SUPER,t,spawn,${getExe pkgs.${config.cfg.vars.terminal}}
      bind=SUPER,a,spawn,${getExe quickshell} ipc call launcher toggle
      bind=SUPER,n,spawn,${getExe quickshell} ipc call notificationCenter toggle
      bind=SUPER,b,spawn,${config.cfg.vars.browser}
      bind=SUPER,x,spawn,${getExe quickshell} ipc call powerMenu toggle
      bind=SUPER,c,spawn,${getExe quickshell} ipc call controlCenter toggle
      bind=SUPER,y,spawn,${getExe quickshell} ipc call wallpaperPicker toggle
      bind=SUPER,p,spawn,${getExe pkgs.flameshot} gui -p $HOME/Pictures/Screenshots -c
      bind=SUPER,v,spawn,${getExe quickshell} ipc call clipboard toggle
      bind=SUPER,m,toggle_named_scratchpad,io.github.screwys.Rufin,none,rufin

      bind=SUPER,q,killclient
      bind=SUPER,space,togglefloating
      bind=SUPER,f,togglefullscreen
      bind=SUPER+SHIFT,f,togglefakefullscreen
      bind=SUPER,j,focusstack,next
      bind=SUPER,k,focusstack,prev
      bind=SUPER,h,focusdir,left
      bind=SUPER,l,focusdir,right
      bind=SUPER,u,focuslast
      bind=SUPER+SHIFT,Up,exchange_client,up
      bind=SUPER+SHIFT,Down,exchange_client,down
      bind=SUPER+SHIFT,Left,exchange_client,left
      bind=SUPER+SHIFT,Right,exchange_client,right
      bind=SUPER,i,incnmaster,+1
      bind=SUPER,d,incnmaster,-1
      bind=SUPER,Return,zoom
      bind=SUPER+ALT,h,resizewin,-50,0
      bind=SUPER+ALT,l,resizewin,+50,0
      bind=SUPER+ALT,k,resizewin,0,-50
      bind=SUPER+ALT,j,resizewin,0,+50

      circle_layout=tile,scroller
      bind=SUPER,Tab,switch_layout
      bind=SUPER,o,toggleoverview

      bind=SUPER,1,comboview,1
      bind=SUPER,2,comboview,2
      bind=SUPER,3,comboview,3
      bind=SUPER,4,comboview,4
      bind=SUPER,5,comboview,5
      bind=SUPER,6,comboview,6
      bind=SUPER,7,comboview,7
      bind=SUPER,8,comboview,8
      bind=SUPER,9,comboview,9

      bind=SUPER+SHIFT,1,tag,1
      bind=SUPER+SHIFT,2,tag,2
      bind=SUPER+SHIFT,3,tag,3
      bind=SUPER+SHIFT,4,tag,4
      bind=SUPER+SHIFT,5,tag,5
      bind=SUPER+SHIFT,6,tag,6
      bind=SUPER+SHIFT,7,tag,7
      bind=SUPER+SHIFT,8,tag,8
      bind=SUPER+SHIFT,9,tag,9

      bind=NONE,XF86AudioRaiseVolume,spawn,${getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind=NONE,XF86AudioLowerVolume,spawn,${getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind=NONE,XF86AudioMute,spawn,${getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind=NONE,XF86AudioMicMute,spawn,${getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bind=NONE,XF86MonBrightnessUp,spawn,${getExe pkgs.brightnessctl} s 5%+
      bind=NONE,XF86MonBrightnessDown,spawn,${getExe pkgs.brightnessctl} s 5%-
      bind=NONE,XF86AudioNext,spawn,${getExe pkgs.playerctl} next
      bind=NONE,XF86AudioPrev,spawn,${getExe pkgs.playerctl} previous
      bind=NONE,XF86AudioPlay,spawn,${getExe pkgs.playerctl} play-pause

      mousebind=SUPER,btn_left,moveresize,curmove
      mousebind=SUPER,btn_right,moveresize,curresize

      window_rule=title:Authentication required,is_floating:1
      window_rule=title:Keybindings,is_floating:1
      window_rule=title:Rename*,is_floating:1
      window_rule=title:Compressing*,is_floating:1
      window_rule=title:File Already Exists*,is_floating:1
      window_rule=title:Extracting Files*,is_floating:1
      window_rule=title:File Operation Progress*,is_floating:1
      window_rule=title:Confirm to replace files*,is_floating:1
      window_rule=app_id:pavucontrol,is_floating:1
      window_rule=app_id:blueman-manager,is_floating:1
      window_rule=app_id:nm-connection-editor,is_floating:1
      window_rule=is_named_scratchpad:1,width:1800,height:1000,app_id:io.github.screwys.Rufin
      window_rule=app_id:thunderbird,is_floating:1
      window_rule=app_id:dolphin,is_floating:1

      enable_hotarea = 0

      window_rule=is_named_scratchpad:1,width:1900,height:1600,app_id:yazi
      window_rule=is_named_scratchpad:1,width:1900,height:1600,app_id:filechooser
      layer_rule=no_blur:1,layer_name:selection
    '';

    systemd.user.targets.mango-session = {
      unitConfig = {
        Description = "mango compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };
  };
}
