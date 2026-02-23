{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  c = config.cfg.theme.colors;
  cfg = config.cfg.qt;
  hexMap = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    a = 10;
    b = 11;
    c = 12;
    d = 13;
    e = 14;
    f = 15;
  };

  toHexInt =
    pair:
    let
      lower = lib.toLower pair;
      high = hexMap.${builtins.substring 0 1 lower};
      low = hexMap.${builtins.substring 1 1 lower};
    in
    high * 16 + low;

  toRGB =
    color:
    let
      hex = lib.strings.removePrefix "#" color;
      r = toHexInt (builtins.substring 0 2 hex);
      g = toHexInt (builtins.substring 2 2 hex);
      b = toHexInt (builtins.substring 4 2 hex);
    in
    "${toString r},${toString g},${toString b}";
in
{

  options.cfg.qt = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable QT Theme configuration.";
    };
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "qt5ct";
      style = "kvantum";
    };
    hj = {
      files.".local/share/color-schemes/Tsuki.colors".text = ''
        [General]
        Name=Tsuki
        Description=Base16 Tsuki dark theme for KDE Plasma

        [ColorEffects:Disabled]
        Color=${toRGB c.base03}
        ColorAmount=0
        ColorEffect=0
        ContrastAmount=0.65
        ContrastEffect=2
        IntensityAmount=0.1
        IntensityEffect=1

        [ColorEffects:Inactive]
        Color=${toRGB c.base01}
        ColorAmount=-0.2
        ColorEffect=2
        ContrastAmount=0.5
        ContrastEffect=1
        IntensityAmount=0
        IntensityEffect=0

        [Colors:Button]
        BackgroundNormal=${toRGB c.base01}
        BackgroundAlternate=${toRGB c.base00}
        ForegroundNormal=${toRGB c.base06}
        ForegroundInactive=${toRGB c.base03}
        ForegroundActive=${toRGB c.base06}
        ForegroundLink=${toRGB c.base0D}
        ForegroundVisited=${toRGB c.base0E}
        DecorationFocus=${toRGB c.base0D}
        DecorationHover=${toRGB c.base0F}
        DecorationInactive=${toRGB c.base03}

        [Colors:Complementary]
        BackgroundNormal=${toRGB c.base01}
        BackgroundAlternate=${toRGB c.base00}
        ForegroundNormal=${toRGB c.base06}
        ForegroundInactive=${toRGB c.base03}
        ForegroundActive=${toRGB c.base06}
        ForegroundLink=${toRGB c.base0D}
        ForegroundVisited=${toRGB c.base0E}
        DecorationFocus=${toRGB c.base0D}
        DecorationHover=${toRGB c.base0F}
        DecorationInactive=${toRGB c.base03}

        [Colors:Header]
        BackgroundNormal=${toRGB c.base01}
        BackgroundAlternate=${toRGB c.base00}
        ForegroundNormal=${toRGB c.base06}
        ForegroundInactive=${toRGB c.base03}
        DecorationFocus=${toRGB c.base0D}
        DecorationInactive=${toRGB c.base03}

        [Colors:Header:Inactive]
        BackgroundNormal=${toRGB c.base01}
        BackgroundAlternate=${toRGB c.base00}
        ForegroundNormal=${toRGB c.base03}
        DecorationInactive=${toRGB c.base03}

        [Colors:Selection]
        BackgroundNormal=${toRGB c.base0D}
        BackgroundAlternate=${toRGB c.base03}
        ForegroundNormal=${toRGB c.base00}
        ForegroundInactive=${toRGB c.base04}
        ForegroundActive=${toRGB c.base00}
        ForegroundLink=${toRGB c.base00}
        ForegroundVisited=${toRGB c.base00}
        DecorationFocus=${toRGB c.base0D}
        DecorationHover=${toRGB c.base0F}
        DecorationInactive=${toRGB c.base02}

        [Colors:Tooltip]
        BackgroundNormal=${toRGB c.base01}
        BackgroundAlternate=${toRGB c.base00}
        ForegroundNormal=${toRGB c.base06}
        ForegroundInactive=${toRGB c.base03}
        DecorationFocus=${toRGB c.base0D}
        DecorationInactive=${toRGB c.base03}

        [Colors:View]
        BackgroundNormal=${toRGB c.base00}
        BackgroundAlternate=${toRGB c.base01}
        ForegroundNormal=${toRGB c.base06}
        ForegroundInactive=${toRGB c.base03}
        ForegroundActive=${toRGB c.base06}
        ForegroundLink=${toRGB c.base0D}
        ForegroundVisited=${toRGB c.base0E}
        DecorationFocus=${toRGB c.base0D}
        DecorationHover=${toRGB c.base0F}
        DecorationInactive=${toRGB c.base03}

        [Colors:Window]
        BackgroundNormal=${toRGB c.base00}
        BackgroundAlternate=${toRGB c.base01}
        ForegroundNormal=${toRGB c.base06}
        ForegroundInactive=${toRGB c.base03}
        ForegroundActive=${toRGB c.base06}
        ForegroundLink=${toRGB c.base0D}
        ForegroundVisited=${toRGB c.base0E}
        DecorationFocus=${toRGB c.base0D}
        DecorationHover=${toRGB c.base0F}
        DecorationInactive=${toRGB c.base03}
      '';
      xdg = {
        config = {

          files = {
            "Kvantum/kvantum.kvconfig".source = (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
              General.theme = "Base16Kvantum";
            };

            "Kvantum/Base16Kvantum/Base16Kvantum.kvconfig".text = ''
              [%General]
                author=Bluskript based on Catppuccin Frappe Mauve theme
                comment=base16-qt
                combo_focus_rect=true
                spread_menuitems=true
                left_tabs=true
                mirror_doc_tabs=true
                scroll_width=8
                attach_active_tab=true
                composite=true
                menu_shadow_depth=7
                tooltip_shadow_depth=0
                splitter_width=7
                check_size=16
                slider_width=4
                slider_handle_width=18
                slider_handle_length=18
                textless_progressbar=false
                menubar_mouse_tracking=true
                slim_toolbars=false
                toolbutton_style=1
                x11drag=menubar_and_primary_toolbar
                double_click=false
                translucent_windows=false
                blurring=false
                popup_blurring=true
                opaque=kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,smplayer,smplayer2,avidemux,avidemux2_qt4,avidemux3_qt4,avidemux3_qt5,kamoso,QtCreator,VirtualBox,trojita,dragon,digikam,qmplay2
                group_toolbar_buttons=false
                vertical_spin_indicators=false
                fill_rubberband=false
                spread_progressbar=true
                merge_menubar_with_toolbar=true
                small_icon_size=16
                large_icon_size=32
                button_icon_size=16
                scroll_arrows=false
                iconless_pushbutton=true
                toolbar_icon_size=16
                combo_as_lineedit=true
                button_contents_shift=false
                groupbox_top_label=true
                inline_spin_indicators=true
                joined_inactive_tabs=false
                layout_spacing=2
                submenu_overlap=0
                tooltip_delay=-1
                animate_states=false
                transient_scrollbar=true
                alt_mnemonic=true
                combo_menu=true
                layout_margin=4
                no_window_pattern=false
                respect_DE=true
                scroll_min_extent=36
                scrollable_menu=false
                scrollbar_in_view=false
                spin_button_width=16
                submenu_delay=250
                tree_branch_line=true
                progressbar_thickness=8
                click_behavior=0
                contrast=1.00
                dialog_button_layout=0
                drag_from_buttons=false
                hide_combo_checkboxes=false
                intensity=1.00
                no_inactiveness=false
                reduce_menu_opacity=0
                reduce_window_opacity=10
                saturation=1.00
                shadowless_popup=false
                transient_groove=false

                [GeneralColors]
                window.color=${c.base00}
                base.color=${c.base00}
                alt.base.color=${c.base01}
                button.color=${c.base02}
                light.color=${c.base01}
                mid.light.color=${c.base02}
                dark.color=${c.base03}
                mid.color=${c.base02}
                highlight.color=${c.base0D}
                inactive.highlight.color=${c.base03}
                tooltip.base.color=${c.base01}
                text.color=${c.base06}
                window.text.color=${c.base06}
                button.text.color=${c.base06}
                disabled.text.color=${c.base03}
                tooltip.text.color=${c.base06}
                highlight.text.color=${c.base00}
                link.color=${c.base0D}
                link.visited.color=${c.base0A}


                [ItemView]
                inherits=PanelButtonCommand
                frame.element=itemview
                interior.element=itemview
                frame=true
                interior=true
                text.iconspacing=3
                text.press.color=${c.base06}
                text.toggle.color=${c.base06}

                [RadioButton]
                inherits=PanelButtonCommand
                frame=false
                interior.element=radio

                [CheckBox]
                inherits=PanelButtonCommand
                frame=false
                interior.element=checkbox

                [TreeExpander]
                indicator.element=tree
                indicator.size=8

                [ToolTip]
                frame.top=4
                frame.right=4
                frame.bottom=4
                frame.left=4
                frame=true

                [PanelButtonCommand]
                inherits=PanelButtonCommand
                interior.element=button
                frame.element=button
                text.normal.color=${c.base06}
                text.focus.color=${c.base0D}
                text.press.color=${c.base0D}
                text.toggle.color=${c.base0D}

                [PanelButtonTool]
                inherits=PanelButtonCommand

                [DockTitle]
                inherits=PanelButtonCommand
                interior=false
                frame=false
                text.margin.top=5
                text.margin.bottom=5
                text.margin.left=5
                text.margin.right=5
                indicator.size=0

                [Dock]
                interior.element=toolbar
                frame.element=toolbar
                frame=true
                interior=true

                [GroupBox]
                inherits=PanelButtonCommand
                interior.element=tabframe
                interior=true
                frame=false

                [Focus]
                inherits=PanelButtonCommand
                frame=true
                frame.element=focus
                frame.top=1
                frame.bottom=1
                frame.left=1
                frame.right=1
                frame.patternsize=20

                [GenericFrame]
                inherits=PanelButtonCommand
                frame.element=common
                frame.top=1
                frame.bottom=1
                frame.left=1
                frame.right=1

                [Slider]
                inherits=PanelButtonCommand
                interior=true
                frame.element=slider
                interior.element=slider
                frame.top=3
                frame.bottom=3
                frame.left=3
                frame.right=3
                focusFrame=true

                [SliderCursor]
                inherits=PanelButtonCommand
                interior=true
                interior.element=slidercursor
                frame=false

                [LineEdit]
                inherits=PanelButtonCommand
                frame.element=lineedit
                interior.element=lineedit

                [IndicatorSpinBox]
                inherits=LineEdit
                frame.element=lineedit
                interior.element=lineedit
                frame.top=0
                frame.bottom=2
                frame.left=2
                frame.right=2
                indicator.size=8

                [DropDownButton]
                inherits=PanelButtonCommand
                frame.top=2
                frame.bottom=2
                frame.left=0
                frame.right=1
                indicator.size=8

                [ToolboxTab]
                inherits=PanelButtonCommand
                frame.element=tabframe
                frame.top=1
                frame.bottom=1
                frame.left=1
                frame.right=1

                [Tab]
                inherits=PanelButtonCommand
                interior.element=tab
                frame.element=tab
                frame.top=2
                frame.bottom=3
                frame.left=3
                frame.right=3
                indicator.size=10
                text.normal.color=${c.base06}
                text.focus.color=${c.base0D}
                text.press.color=${c.base0D}
                text.toggle.color=${c.base0D}
                focusFrame=true

                [TabBarFrame]
                inherits=GenericFrame
                frame=true
                frame.element=tabBarFrame
                interior=false
                frame.top=4
                frame.bottom=4
                frame.left=4
                frame.right=4

                [TabFrame]
                inherits=PanelButtonCommand
                frame.element=tabframe
                interior.element=tabframe

                [Dialog]
                inherits=TabBarFrame
                frame.element=tabframe
                interior=false
                frame=false
                frame.top=1
                frame.bottom=1
                frame.left=1
                frame.right=1

                [HeaderSection]
                inherits=PanelButtonCommand
                interior.element=header
                frame.element=header
                frame.top=0
                frame.bottom=1
                frame.left=1
                frame.right=1
                frame.expansion=0
                text.normal.color=${c.base06}
                text.focus.color=${c.base0D}
                text.press.color=${c.base0D}
                text.toggle.color=${c.base0D}
                indicator.element=harrow

                [SizeGrip]
                inherits=PanelButtonCommand
                frame=false
                interior=false
                indicator.element=resize-grip
                indicator.size=0

                [Toolbar]
                inherits=PanelButtonCommand
                interior.element=menubar
                frame.element=menubar
                frame=true
                frame.bottom=4
                frame.left=4
                frame.right=4
                text.normal.color=${c.base06}
                text.focus.color=${c.base0D}
                text.press.color=${c.base0D}
                text.toggle.color=${c.base0D}
                text.bold=false

                [MenuBar]
                inherits=PanelButtonCommand
                frame.element=menubar
                interior.element=menubar
                frame.bottom=0
                text.normal.color=${c.base06}
                frame.expansion=0
                text.bold=false

                [ToolbarButton]
                frame.element=tbutton
                interior.element=tbutton
                indicator.element=arrow
                text.normal.color=${c.base06}
                text.focus.color=${c.base0D}
                text.press.color=${c.base0D}
                text.toggle.color=${c.base0D}
                text.bold=false

                [ToolbarLineEdit]
                frame.element=lineedit
                interior.element=lineedit

                [Scrollbar]
                inherits=PanelButtonCommand
                indicator.size=0
                interior=false
                frame=false

                [ScrollbarGroove]
                inherits=PanelButtonCommand
                interior=false
                frame=false

                [ScrollbarSlider]
                inherits=PanelButtonCommand
                interior=false
                frame.element=scrollbarslider
                frame.top=4
                frame.bottom=4
                frame.left=4
                frame.right=4

                [ProgressbarContents]
                inherits=PanelButtonCommand
                frame=true
                frame.element=progress-pattern
                interior.element=progress-pattern
                frame.top=2
                frame.bottom=2
                frame.left=2
                frame.right=2

                [Progressbar]
                inherits=PanelButtonCommand
                frame.element=progress
                interior.element=progress
                frame.top=2
                frame.bottom=2
                frame.left=2
                frame.right=2
                text.margin=0
                text.normal.color=${c.base06}
                text.focus.color=${c.base0D}
                text.press.color=${c.base0D}
                text.toggle.color=${c.base0D}
                text.bold=false
                frame.expansion=18

                [RadioButton]
                inherits=PanelButtonCommand

                [Menu]
                frame.element=menu
                interior.element=menu
                inherits=PanelButtonCommand
                text.press.color=${c.base00}
                text.toggle.color=${c.base00}
                text.bold=false
                frame.top=3
                frame.bottom=3
                frame.left=3
                frame.right=3

                [MenuItem]
                inherits=PanelButtonCommand
                interior.element=menuitem
                indicator.size=8
                frame=true
                frame.element=menuitem
                frame.right=10
                frame.left=10
                text.focus.color=${c.base00}
                text.press.color=${c.base00}

                [MenuBarItem]
                inherits=PanelButtonCommand
                interior.element=menubaritem
                frame=false
                text.margin.top=3
                text.margin.bottom=3
                text.margin.left=5
                text.margin.right=5

                [StatusBar]
                inherits=Toolbar
                frame.element=toolbar
                font.bold=true
                text.normal.color=${c.base06}
                frame=true
                frame.top=0
                frame.bottom=0

                [TitleBar]
                inherits=PanelButtonCommand
                frame=false
                interior=false
                text.margin.top=2
                text.margin.bottom=2
                text.margin.left=3
                text.margin.right=3

                [ComboBox]
                inherits=PanelButtonCommand
                indicator.size=8
                frame.top=3
                frame.bottom=3
                frame.left=3
                frame.right=3
                text.margin.top=1
                text.margin.bottom=1
                text.margin.left=3
                text.margin.right=3
                text.press.color=${c.base06}
                text.toggle.color=${c.base06}

                [ToolboxTab]
                inherits=PanelButtonCommand
                text.normal.color=${c.base06}
                text.press.color=${c.base0D}
                text.focus.color=${c.base0D}

                [Hacks]
                transparent_dolphin_view=false
                blur_konsole=true
                transparent_ktitle_label=true
                transparent_menutitle=true
                respect_darkness=true
                kcapacitybar_as_progressbar=true
                force_size_grip=false
                iconless_pushbutton=true
                iconless_menu=false
                disabled_icon_opacity=100
                lxqtmainmenu_iconsize=0
                normal_default_pushbutton=true
                single_top_toolbar=false
                tint_on_mouseover=0
                transparent_pcmanfm_sidepane=true
                transparent_pcmanfm_view=false
                blur_translucent=true
                centered_forms=false
                kinetic_scrolling=false
                middle_click_scroll=false
                no_selection_tint=true
                noninteger_translucency=false
                style_vertical_toolbars=false
                blur_only_active_window=false

                [Window]
                interior=true
                interior.element=window
                frame.top=0
                frame.bottom=0
                frame.left=0
                frame.right=0
            '';

            "Kvantum/Base16Kvantum/Base16Kvantum.svg".text = ''
              <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="845" height="695" version="1">
                <defs>
                  <defs>
                    <linearGradient id="linearGradient1304" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1768" />
                    <linearGradient id="linearGradient1266">
                      <stop style="stop-color:#000000;stop-opacity:0.3137255" offset="0" />
                      <stop style="stop-color:#000000;stop-opacity:0" offset="1" />
                    </linearGradient>
                    <linearGradient id="linearGradient1272">
                      <stop style="stop-color:${c.base06};stop-opacity:0.69072163" offset="0" />
                      <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                    </linearGradient>
                    <radialGradient id="radialGradient1278" cx="522.895" cy="481.866" r="15.301" fx="522.899" fy="473.033" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1702" />
                    <linearGradient id="linearGradient1279" x1="522.942" x2="522.942" y1="469.499" y2="505.084" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1697" />
                    <linearGradient id="linearGradient1280" x1="213.828" x2="214.592" y1="183.484" y2="463.473" gradientTransform="matrix(1.5539,0,0,0.643542,-1.017928,0)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1702" />
                    <linearGradient id="linearGradient1281" x1="520.572" x2="520.572" y1="506.287" y2="466.279" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1697" />
                    <linearGradient id="linearGradient1282" x1="522.942" x2="522.942" y1="469.499" y2="505.084" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1697" />
                    <linearGradient id="linearGradient1283" x1="44.931" x2="45.512" y1="56.725" y2="185.057" gradientTransform="matrix(1.694118,0,0,0.651906,0,-2.410339)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1702" />
                    <linearGradient id="linearGradient1284" x1="520.572" x2="520.572" y1="506.287" y2="466.279" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1735" />
                    <linearGradient id="linearGradient1285" x1="27.12" x2="27.018" y1="-353.759" y2="-316.477" gradientTransform="scale(2.89873,-0.344979)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1702" />
                    <radialGradient id="radialGradient1286" cx="41.876" cy="37.866" r="12.563" fx="42.024" fy="37.866" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1845" />
                    <linearGradient id="linearGradient1287" x1="10.686" x2="11.66" y1="22.703" y2="4.104" gradientTransform="scale(1.016203,0.984055)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1302" />
                    <linearGradient id="linearGradient1288" x1="16.884" x2="12.517" y1="28.773" y2="2.602" gradientTransform="scale(1.016203,0.984055)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1305" />
                    <defs>
                      <linearGradient id="linearGradient1290" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient2002" />
                      <linearGradient id="linearGradient1291" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient2009" />
                      <linearGradient id="linearGradient1292" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient2006" />
                      <linearGradient id="linearGradient1296">
                        <stop style="stop-color:${c.base06}" offset="0" />
                        <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                      </linearGradient>
                      <linearGradient id="linearGradient1299">
                        <stop style="stop-color:#000000;stop-opacity:0.14835165" offset="0" />
                        <stop style="stop-color:#7f7f7f;stop-opacity:0.49803922" offset=".5" />
                        <stop style="stop-color:#bfbfbf;stop-opacity:0.34705882" offset=".75" />
                        <stop style="stop-color:${c.base06};stop-opacity:0.12156863" offset=".875" />
                        <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                      </linearGradient>
                      <linearGradient id="linearGradient1309" x1="28.814" x2="47.366" y1="-1.616" y2="22.77" gradientTransform="scale(0.764292,1.3084)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                      <linearGradient id="linearGradient1310" x1="30.723" x2="39.781" y1="28.135" y2="27.315" gradientTransform="scale(0.475459,2.103232)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                      <linearGradient id="linearGradient1311" x1="30.382" x2="47.366" y1="7.533" y2="22.77" gradientTransform="matrix(0.479578,0,0,0.81043,36.76785,3.324472)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                      <linearGradient id="linearGradient1312" x1="25.955" x2="39.782" y1="25.071" y2="27.315" gradientTransform="scale(0.475459,2.103231)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                      <defs>
                        <linearGradient id="linearGradient1314" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1302" />
                        <linearGradient id="linearGradient1315" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1305" />
                        <linearGradient id="linearGradient1319" x1=".284" x2=".325" y1=".883" y2=".105" xlink:href="#linearGradient4114" />
                        <linearGradient id="linearGradient1320" x1="-.008" x2=".596" y1="-1.245" y2=".361" xlink:href="#linearGradient1513" />
                        <linearGradient id="linearGradient1321" x1="-.451" x2=".471" y1="-.151" y2=".366" xlink:href="#linearGradient1513" />
                        <linearGradient id="linearGradient1322" x1=".459" x2=".69" y1="1.277" y2="-.297" xlink:href="#linearGradient2122" />
                        <linearGradient id="linearGradient1323" x1="-.182" x2=".685" y1="-.44" y2=".424" xlink:href="#linearGradient1513" />
                        <linearGradient id="linearGradient1324">
                          <stop style="stop-color:#000000;stop-opacity:0.40784314" offset="0" />
                          <stop style="stop-color:#000000;stop-opacity:0" offset="1" />
                        </linearGradient>
                        <linearGradient id="linearGradient1327" x1="1.378" x2=".584" y1=".254" y2=".13" xlink:href="#linearGradient2122" />
                        <linearGradient id="linearGradient1328" x1="-.142" x2=".498" y1="-.288" y2=".356" xlink:href="#linearGradient1513" />
                        <linearGradient id="linearGradient1329" x1=".995" x2=".327" y1=".644" y2=".3" xlink:href="#linearGradient1918" />
                        <linearGradient id="linearGradient1330" x1=".278" x2=".451" y1="-.064" y2=".611" xlink:href="#linearGradient1513" />
                        <linearGradient id="linearGradient1331">
                          <stop style="stop-color:#d6d6d6" offset="0" />
                          <stop style="stop-color:#eaeaea" offset=".258" />
                          <stop style="stop-color:#919191" offset=".706" />
                          <stop style="stop-color:#d2d2d2" offset=".733" />
                          <stop style="stop-color:#a6a6a6" offset="1" />
                        </linearGradient>
                        <linearGradient id="linearGradient1337" x1=".475" x2=".804" y1=".218" y2=".52" xlink:href="#linearGradient2317" />
                        <linearGradient id="linearGradient1338">
                          <stop style="stop-color:${c.base06}" offset="0" />
                          <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                        </linearGradient>
                        <linearGradient id="linearGradient1341" x1=".416" x2=".596" y1=".277" y2=".443" xlink:href="#linearGradient1513" />
                        <radialGradient id="radialGradient1342" cx=".5" cy=".5" r=".5" fx=".384" fy=".476" xlink:href="#linearGradient1918" />
                        <linearGradient id="linearGradient1343" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1845" />
                        <radialGradient id="radialGradient1344" cx=".5" cy=".5" r=".5" fx=".506" fy=".5" xlink:href="#linearGradient1918" />
                        <linearGradient id="linearGradient1345" x1=".544" x2=".361" y1="1.137" y2=".042" xlink:href="#linearGradient4111" />
                      </defs>
                    </defs>
                    <radialGradient id="radialGradient1397" cx="41.876" cy="37.866" r="12.563" fx="42.024" fy="37.866" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2002" />
                    <linearGradient id="linearGradient1303" x1="240.862" x2="240.862" y1="635.747" y2="1038.944" transform="matrix(1.475472,0,0,0.677749,-32.57368,52.93652)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1683" />
                    <defs>
                      <linearGradient id="linearGradient1694">
                        <stop style="stop-color:${c.base06};stop-opacity:0" offset="0" />
                        <stop style="stop-color:${c.base06}" offset="1" />
                      </linearGradient>
                      <linearGradient id="linearGradient1683" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1304" />
                      <linearGradient id="linearGradient1686" x1="242.398" x2="242.398" y1="1035.334" y2="636.255" transform="scale(1.475472,0.677749)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1683" />
                      <linearGradient id="linearGradient1690" x1="240.862" x2="240.862" y1="635.747" y2="1038.944" transform="scale(1.475472,0.677749)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1683" />
                      <linearGradient id="linearGradient1692" x1="244.86" x2="244.86" y1="827.013" y2="646.062" transform="scale(1.479463,0.675921)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1694" />
                      <linearGradient id="linearGradient1249" x1="242.398" x2="242.398" y1="1035.334" y2="636.255" transform="scale(1.475472,0.677749)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1683" />
                      <linearGradient id="linearGradient1251" x1="244.86" x2="244.86" y1="827.013" y2="646.062" transform="scale(1.479463,0.675921)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient1694" />
                    </defs>
                  </defs>
                  <defs>
                    <linearGradient id="linearGradient1845" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient2002" />
                    <linearGradient id="linearGradient1305" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient2009" />
                    <linearGradient id="linearGradient1302" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient2006" />
                    <linearGradient id="linearGradient2354">
                      <stop style="stop-color:${c.base06}" offset="0" />
                      <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                    </linearGradient>
                    <linearGradient id="linearGradient1778">
                      <stop style="stop-color:#000000;stop-opacity:0.14835165" offset="0" />
                      <stop style="stop-color:#7f7f7f;stop-opacity:0.49803922" offset=".5" />
                      <stop style="stop-color:#bfbfbf;stop-opacity:0.34705882" offset=".75" />
                      <stop style="stop-color:${c.base06};stop-opacity:0.12156863" offset=".875" />
                      <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                    </linearGradient>
                    <linearGradient id="linearGradient2353" x1="28.814" x2="47.366" y1="-1.616" y2="22.77" gradientTransform="scale(0.764292,1.3084)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                    <linearGradient id="linearGradient2358" x1="30.723" x2="39.781" y1="28.135" y2="27.315" gradientTransform="scale(0.475459,2.103232)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                    <linearGradient id="linearGradient2360" x1="30.382" x2="47.366" y1="7.533" y2="22.77" transform="matrix(0.479578,0,0,0.81043,36.76785,3.324472)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                    <linearGradient id="linearGradient2368" x1="25.955" x2="39.782" y1="25.071" y2="27.315" gradientTransform="scale(0.475459,2.103231)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient2354" />
                    <defs>
                      <linearGradient id="linearGradient4114" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1302" />
                      <linearGradient id="linearGradient4111" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1305" />
                      <linearGradient id="linearGradient2222" x1=".284" x2=".325" y1=".883" y2=".105" xlink:href="#linearGradient4114" />
                      <linearGradient id="linearGradient2313" x1="-.008" x2=".596" y1="-1.245" y2=".361" xlink:href="#linearGradient1513" />
                      <linearGradient id="linearGradient2314" x1="-.451" x2=".471" y1="-.151" y2=".366" xlink:href="#linearGradient1513" />
                      <linearGradient id="linearGradient1516" x1=".459" x2=".69" y1="1.277" y2="-.297" xlink:href="#linearGradient2122" />
                      <linearGradient id="linearGradient2223" x1="-.182" x2=".685" y1="-.44" y2=".424" xlink:href="#linearGradient1513" />
                      <linearGradient id="linearGradient2122">
                        <stop style="stop-color:#000000;stop-opacity:0.40784314" offset="0" />
                        <stop style="stop-color:#000000;stop-opacity:0" offset="1" />
                      </linearGradient>
                      <linearGradient id="linearGradient2138" x1="1.378" x2=".584" y1=".254" y2=".13" xlink:href="#linearGradient2122" />
                      <linearGradient id="linearGradient2224" x1="-.142" x2=".498" y1="-.288" y2=".356" xlink:href="#linearGradient1513" />
                      <linearGradient id="linearGradient1512" x1=".995" x2=".327" y1=".644" y2=".3" xlink:href="#linearGradient1918" />
                      <linearGradient id="linearGradient2315" x1=".278" x2=".451" y1="-.064" y2=".611" xlink:href="#linearGradient1513" />
                      <linearGradient id="linearGradient2317">
                        <stop style="stop-color:#d6d6d6" offset="0" />
                        <stop style="stop-color:#eaeaea" offset=".258" />
                        <stop style="stop-color:#919191" offset=".706" />
                        <stop style="stop-color:#d2d2d2" offset=".733" />
                        <stop style="stop-color:#a6a6a6" offset="1" />
                      </linearGradient>
                      <linearGradient id="linearGradient2316" x1=".475" x2=".804" y1=".218" y2=".52" xlink:href="#linearGradient2317" />
                      <linearGradient id="linearGradient1513">
                        <stop style="stop-color:${c.base06}" offset="0" />
                        <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                      </linearGradient>
                      <linearGradient id="linearGradient2121" x1=".416" x2=".596" y1=".277" y2=".443" xlink:href="#linearGradient1513" />
                      <radialGradient id="radialGradient2541" cx=".5" cy=".5" r=".5" fx=".384" fy=".476" xlink:href="#linearGradient1918" />
                      <linearGradient id="linearGradient1918" x1="0" x2="1" y1=".5" y2=".5" gradientUnits="objectBoundingBox" spreadMethod="pad" xlink:href="#linearGradient1845" />
                      <radialGradient id="radialGradient1502" cx=".5" cy=".5" r=".5" fx=".506" fy=".5" xlink:href="#linearGradient1918" />
                      <linearGradient id="linearGradient2312" x1=".544" x2=".361" y1="1.137" y2=".042" xlink:href="#linearGradient4111" />
                    </defs>
                  </defs>
                  <linearGradient id="linearGradient1702">
                    <stop style="stop-color:${c.base06};stop-opacity:0.69072163" offset="0" />
                    <stop style="stop-color:${c.base06};stop-opacity:0" offset="1" />
                  </linearGradient>
                  <linearGradient id="linearGradient2002">
                    <stop style="stop-color:#000000;stop-opacity:0.3137255" offset="0" />
                    <stop style="stop-color:#000000;stop-opacity:0" offset="1" />
                  </linearGradient>
                  <linearGradient id="selected_bg_color" transform="translate(91,-40.99999)">
                    <stop style="stop-color:${c.base0D}" offset="0" />
                  </linearGradient>
                  <radialGradient id="radialGradient11175" cx="525" cy="330" r="5" fx="525" fy="330" gradientTransform="matrix(0,-1.4,2,0,-135,1065)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <linearGradient id="linearGradient3893">
                    <stop style="stop-color:#000000" offset="0" />
                    <stop style="stop-color:#000000;stop-opacity:0" offset="1" />
                  </linearGradient>
                  <linearGradient id="linearGradient11121" x1="532" x2="532" y1="330" y2="323" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <linearGradient id="linearGradient11133" x1="525" x2="515" y1="348" y2="348" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <radialGradient id="radialGradient11173" cx="571" cy="330" r="5" fx="571" fy="330" gradientTransform="matrix(2,0,0,1.4,-571,-132)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <linearGradient id="linearGradient11125" x1="571" x2="581" y1="351" y2="351" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <radialGradient id="radialGradient11177" cx="525" cy="373" r="5" fx="525" fy="373" gradientTransform="matrix(-2,0,0,-2,1575,1119)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <linearGradient id="linearGradient11129" x1="533" x2="533" y1="373" y2="383" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <radialGradient id="radialGradient11179" cx="571" cy="373" r="5" fx="571" fy="373" gradientTransform="matrix(0,2,-2,0,1317,-769)" gradientUnits="userSpaceOnUse" xlink:href="#linearGradient3893" />
                  <linearGradient id="linearGradient2266" x1="18" x2="32" y1="31.36" y2="31.36" gradientUnits="userSpaceOnUse" xlink:href="#selected_bg_color" />
                  <linearGradient id="linearGradient2268" x1="18" x2="32" y1="31.36" y2="31.36" gradientUnits="userSpaceOnUse" xlink:href="#selected_bg_color" />
                  <linearGradient id="linearGradient2270" x1="51.199" x2="80.35" y1="127.576" y2="127.576" transform="scale(1.0080248,0.9920391)" gradientUnits="userSpaceOnUse" xlink:href="#selected_bg_color" />
                  <linearGradient id="linearGradient2272" x1="18" x2="32" y1="31.36" y2="31.36" gradientUnits="userSpaceOnUse" xlink:href="#selected_bg_color" />
                  <linearGradient id="linearGradient2274" x1="18" x2="32" y1="31.36" y2="31.36" gradientUnits="userSpaceOnUse" xlink:href="#selected_bg_color" />
                  <linearGradient id="linearGradient2276" x1="51.199" x2="80.35" y1="127.576" y2="127.576" transform="scale(1.0080248,0.9920391)" gradientUnits="userSpaceOnUse" xlink:href="#selected_bg_color" />
                </defs>
                <g id="menuitem-tearoff-normal" transform="translate(569.22443,-600.73382)">
                  <rect style="opacity:0;fill:#141414" width="7" height="9" x="686.5" y="-229.5" transform="rotate(90)" />
                  <path style="fill:${c.base02}" d="m 227.2385,689 h -2.2462 v 2 h 2.2462 z m -4.4924,0 H 220.5 v 2 h 2.2461 z" />
                </g>
                <g id="menuitem-tearoff-focused" transform="translate(591.22443,-600.73382)">
                  <rect style="opacity:0;fill:#141414" width="7" height="9" x="686.5" y="-229.5" transform="rotate(90)" />
                  <path style="fill:${c.base01}" d="m 227.2385,689 h -2.2462 v 2 h 2.2462 z m -4.4924,0 H 220.5 v 2 h 2.2461 z" />
                </g>
                <g id="dial" transform="matrix(0.95744681,0,0,0.95744681,359.41894,236.51316)">
                  <rect id="dial-handle-4" style="opacity:0.00100002;fill:none;stroke:#000000;stroke-width:1.04444" width="10.444" height="10.444" x="104.86" y="228.25" rx="5.222" ry="5.222" />
                </g>
                <g id="dial-notches" style="fill:${c.base06}" transform="translate(-158.89134,-161.46256)">
                  <rect style="opacity:0" width="45" height="45" x="202.5" y="667.5" />
                  <path id="dial-notches0" style="opacity:0.3" d="m 214.625,670 -1.75,1 2.25,3.9063 1.75,-1 z m 20.75,0 -2.25,3.9063 1.75,1 2.25,-3.9063 z M 202.5,689 v 2 h 4.5 v -2 z m 40.5,0 v 2 h 4.5 v -2 z m -27.875,16.0938 -2.25,3.9062 1.75,1 2.25,-3.9062 z m 19.75,0 -1.75,1 2.25,3.9062 1.75,-1 z" />
                  <path style="opacity:0.3" d="m 222.9062,667.5938 -0.5,0.0625 0.3125,2.9688 0.5,-0.0312 -0.3125,-3 z m 4.1875,0 -0.3125,3 0.5,0.0312 0.3125,-2.9688 -0.5,-0.0625 z m -8.8125,0.9375 -0.4688,0.1562 0.9375,2.8438 0.4688,-0.1562 z m 13.4375,0 -0.9375,2.8438 0.4688,0.1562 0.9375,-2.8438 z m -21.5938,4.5938 -0.375,0.3125 2.0312,2.25 0.3438,-0.3438 -2,-2.2188 z m 29.75,0 -2,2.2188 0.3438,0.3438 2.0312,-2.25 -0.375,-0.3125 z m -32.9375,3.4375 -0.2812,0.4062 2.4062,1.7812 0.3125,-0.4062 z m 36.125,0 -2.4375,1.7812 0.3125,0.4062 2.4062,-1.7812 z m -38.5,4.0625 -0.2188,0.4375 2.75,1.25 0.1875,-0.4688 -2.7188,-1.2188 z m 40.875,0 -2.7188,1.2188 0.1875,0.4688 2.75,-1.25 -0.2188,-0.4375 z m -42.4062,4.4375 -0.0937,0.5 2.9375,0.625 0.0937,-0.5 z m 43.9375,0 -2.9375,0.625 0.0937,0.5 2.9375,-0.625 z m -41.0938,8.75 -2.9375,0.625 0.0937,0.5 2.9375,-0.625 z m 38.25,0 -0.0937,0.5 2.9375,0.625 0.0937,-0.5 z m -37.0312,3.875 -2.75,1.25 0.2188,0.4375 2.7188,-1.2188 -0.1875,-0.4688 z m 35.8125,0 -0.1875,0.4688 2.7188,1.2188 0.2188,-0.4375 -2.75,-1.25 z m -33.8438,3.5625 -2.4062,1.7812 0.2812,0.4062 2.4375,-1.7812 z m 31.875,0 -0.3125,0.4062 2.4375,1.7812 0.2812,-0.4062 z m -29.1562,3.0625 -2.0312,2.25 0.375,0.3125 2,-2.2188 -0.3438,-0.3438 z m 26.4375,0 -0.3438,0.3438 2,2.2188 0.375,-0.3125 -2.0312,-2.25 z" />
                </g>
                <rect id="grip-normal" style="opacity:0" width="5" height="5" x="549.3" y="636.64" />
                <rect id="grip-focused" style="opacity:0" width="5" height="5" x="579.3" y="636.64" />
                <rect id="grip-pressed" style="opacity:0" width="5" height="5" x="609.3" y="636.64" />
                <g id="itemview-toggled-left" transform="matrix(0.44036689,0,0,-1.999996,510.85999,2181.7643)">
                  <rect style="fill:${c.base03}" width="2" height="21" x="-721.81" y="789.58" />
                </g>
                <g id="itemview-toggled-bottom" transform="matrix(0.84070043,0,0,-1.1999995,799.02299,1538.1001)">
                  <rect style="fill:${c.base03}" width="55" height="2" x="-719.81" y="777.58" />
                </g>
                <rect id="itemview-toggled-top" style="fill:${c.base03}" width="46.239" height="3.6" x="193.88" y="-560.6" transform="scale(1,-1)" />
                <g id="itemview-toggled-right" transform="matrix(0.44036689,0,0,-1.999996,532.87829,2181.7643)">
                  <rect style="fill:${c.base03}" width="2" height="21" x="-664.81" y="789.58" />
                </g>
                <rect id="itemview-toggled" style="fill:${c.base03}" width="46.239" height="42" x="193.88" y="-602.6" transform="scale(1,-1)" />
                <path id="itemview-togg" style="fillled-topleft:${c.base03}" d="m 193.88074,556.99973 c -0.48641,0 -0.88073,1.0745 -0.88073,2.4 v 1.2 h 0.88073 v -1.2 z" />
                <path id="itemview-toggled-bottomright" style="fill:${c.base03}" d="m 241,602.59961 a 0.88073379,2.3999989 0 0 1 -0.88074,2.4 v -2.4 z" />
                <path id="itemview-toggled-bottomleft" style="fill:${c.base03}" d="m 193,602.59961 a 0.88073379,2.3999989 0 0 0 0.88074,2.4 v -2.4 z" />
                <path id="itemview-toggled-topright" style="fill:${c.base03}" d="m 240.11927,556.99973 c 0.48641,0 0.88073,1.0745 0.88073,2.4 v 1.2 h -0.88073 v -1.2 z" />
                <g id="toolbar-normal-top" transform="matrix(0.83636363,0,0,0.5,616.0229,-304.79001)">
                  <path style="fill:${c.base01}" transform="matrix(1.25,0,0,2,-738.56,609.52204)" d="m 15,84.029297 v 0.5 0.5 h 44 v -0.5 -0.5 z" />
                </g>
                <rect id="toolbar-normal" style="fill:${c.base01}" width="46" height="46" x="14" y="85" />
                <g id="itemview-pressed-left" transform="matrix(0.44036689,0,0,-1.999996,588.86,2181.7643)">
                  <rect style="fill:${c.base03}" width="2" height="21" x="-721.81" y="789.58" />
                </g>
                <g id="itemview-pressed-bottom" transform="matrix(0.84070043,0,0,-1.1999995,877.02311,1538.1001)">
                  <rect style="fill:${c.base03}" width="55" height="2" x="-719.81" y="777.58" />
                </g>
                <rect id="itemview-pressed-top" style="fill:${c.base03}" width="46.239" height="3.6" x="271.88" y="-560.6" transform="scale(1,-1)" />
                <g id="itemview-pressed-right" transform="matrix(0.44036689,0,0,-1.999996,610.8783,2181.7643)">
                  <rect style="fill:${c.base03}" width="2" height="21" x="-664.81" y="789.58" />
                </g>
                <rect id="itemview-pressed" style="fill:${c.base03}" width="46.239" height="42" x="271.88" y="-602.6" transform="scale(1,-1)" />
                <path id="itemview-pressed-topleft" style="fill:${c.base03}" d="m 271.88074,556.99973 c -0.48641,0 -0.88073,1.0745 -0.88073,2.4 v 1.2 h 0.88073 v -1.2 z" />
                <path id="itemview-pressed-bottomright" style="fill:${c.base03}" d="m 319,602.59961 a 0.88073379,2.3999989 0 0 1 -0.88074,2.4 v -2.4 z" />
                <path id="itemview-pressed-bottomleft" style="fill:${c.base03}" d="m 271,602.59961 a 0.88073379,2.3999989 0 0 0 0.88074,2.4 v -2.4 z" />
                <path id="itemview-pressed-topright" style="fill:${c.base03}" d="m 318.11927,556.99973 c 0.48641,0 0.88073,1.0745 0.88073,2.4 v 1.2 h -0.88073 v -1.2 z" />
                <g id="splitter-grip-focused" style="opacity:0" transform="translate(502.42498,-393.92675)">
                  <path style="fill:${c.base03}" d="m 227.5,690 c 0,1.3807 -1.11929,2.5 -2.5,2.5 -1.38071,0 -2.5,-1.1193 -2.5,-2.5 0,-1.3807 1.11929,-2.5 2.5,-2.5 1.38071,0 2.5,1.1193 2.5,2.5 z" />
                  <g style="fill:${c.base03}">
                    <path style="fill:${c.base03}" d="m 226.9643,683.9643 c 0,1.0848 -0.87944,1.9643 -1.96429,1.9643 -1.08484,0 -1.96428,-0.8795 -1.96428,-1.9643 0,-1.0849 0.87944,-1.9643 1.96428,-1.9643 1.08485,0 1.96429,0.8794 1.96429,1.9643 z" />
                    <path style="fill:${c.base03}" d="m 226.9643,696.0357 c 0,1.0848 -0.87944,1.9643 -1.96429,1.9643 -1.08484,0 -1.96428,-0.8795 -1.96428,-1.9643 0,-1.0849 0.87944,-1.9643 1.96428,-1.9643 1.08485,0 1.96429,0.8794 1.96429,1.9643 z" />
                  </g>
                </g>
                <g id="splitter-grip-pressed" style="opacity:0" transform="translate(515.66069,-421.12141)">
                  <path style="fill:${c.base03}" d="m 227.5,690 c 0,1.3807 -1.11929,2.5 -2.5,2.5 -1.38071,0 -2.5,-1.1193 -2.5,-2.5 0,-1.3807 1.11929,-2.5 2.5,-2.5 1.38071,0 2.5,1.1193 2.5,2.5 z" />
                  <g style="fill:${c.base03}">
                    <path style="fill:${c.base03}" d="m 226.9643,683.9643 c 0,1.0848 -0.87944,1.9643 -1.96429,1.9643 -1.08484,0 -1.96428,-0.8795 -1.96428,-1.9643 0,-1.0849 0.87944,-1.9643 1.96428,-1.9643 1.08485,0 1.96429,0.8794 1.96429,1.9643 z" />
                    <path style="fill:${c.base03}" d="m 226.9643,696.0357 c 0,1.0848 -0.87944,1.9643 -1.96429,1.9643 -1.08484,0 -1.96428,-0.8795 -1.96428,-1.9643 0,-1.0849 0.87944,-1.9643 1.96428,-1.9643 1.08485,0 1.96429,0.8794 1.96429,1.9643 z" />
                  </g>
                </g>
                <rect id="slider-topglow-normal" style="opacity:0.6;fill:#dcdcdc;fill-opacity:0" width="10" height="30" x="311.17" y="491.77" />
                <use id="slider-bottomglow-normal" width="450" height="1380" x="0" y="0" transform="translate(39.999997)" xlink:href="#slider-topglow-normal" />
                <g id="splitter-grip-normal" style="opacity:0" transform="translate(518.58485,-394.77228)">
                  <path style="fill:#bebebe" d="m 227.5,690 c 0,1.3807 -1.11929,2.5 -2.5,2.5 -1.38071,0 -2.5,-1.1193 -2.5,-2.5 0,-1.3807 1.11929,-2.5 2.5,-2.5 1.38071,0 2.5,1.1193 2.5,2.5 z" />
                  <g style="fill:${c.base03}">
                    <path style="fill:${c.base03}" d="m 226.9643,683.9643 c 0,1.0848 -0.87944,1.9643 -1.96429,1.9643 -1.08484,0 -1.96428,-0.8795 -1.96428,-1.9643 0,-1.0849 0.87944,-1.9643 1.96428,-1.9643 1.08485,0 1.96429,0.8794 1.96429,1.9643 z" />
                    <path style="fill:${c.base03}" d="m 226.9643,696.0357 c 0,1.0848 -0.87944,1.9643 -1.96429,1.9643 -1.08484,0 -1.96428,-0.8795 -1.96428,-1.9643 0,-1.0849 0.87944,-1.9643 1.96428,-1.9643 1.08485,0 1.96429,0.8794 1.96429,1.9643 z" />
                  </g>
                </g>
              </svg>
            '';
          };
        };
      };
    };
  };
}
