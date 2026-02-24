{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types mkIf;

  cfg = config.cfg.rmpc;
  c = config.cfg.theme.colors;
in
{
  options.cfg.rmpc = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable RMPC (MPD Client) and configuration.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ pkgs.rmpc ];

    hj.xdg.config.files = {
      "rmpc/config.ron".text = ''
        #![enable(implicit_some)]
        #![enable(unwrap_newtypes)]
        #![enable(unwrap_variant_newtypes)]
        (
          address: "127.0.0.1:6600",
          cache_dir: Some("${config.hj.xdg.cache.directory}/rmpc"),
          password: None,
          default_album_art_path: None,
          show_song_table_header: true,
          draw_borders: true,
          enable_config_hot_reload: true,
          on_song_change: None,
          select_current_song_on_change: false,
          album_art: (
              method: Auto,
              disabled_protocols: ["http://", "https://"],
              vertical_align: Center,
              horizontal_align: Center,
          ),
          background_color: "${c.base00}",
          modal_backdrop: true,
          text_color: "${c.base04}",
          header_background_color: "${c.base00}",
          modal_background_color: "${c.base00}",

          preview_label_style: (fg: "${c.base0E}"),
          preview_metadata_group_style: (fg: "${c.base08}"),

          tab_bar: (
            active_style: (fg: "${c.base00}", bg: "${c.base09}", modifiers: "Bold"),
            inactive_style: (fg: "${c.base04}", bg: "${c.base00}", modifiers: ""),
          ),

          highlighted_item_style: (fg: "${c.base0B}", modifiers: "Bold"),
          current_item_style: (fg: "${c.base00}", bg: "${c.base09}", modifiers: "Bold"),
          borders_style: (fg: "${c.base09}", modifiers: "Bold"),
          highlight_border_style: (fg: "${c.base09}"),

          symbols: (song: "󰝚 ", dir: " ", playlist: "󰲸 ", marker: "* ", ellipsis: "..."),

          progress_bar: (
            symbols: ["█", "█", "█", "█", "█"],
            track_style: (fg: "${c.base01}"),
            elapsed_style: (fg: "${c.base09}"),
            thumb_style: (fg: "${c.base09}"),
          ),

          scrollbar: (
            symbols: ["│", "█", "▲", "▼"],
            track_style: (fg: "${c.base09}"),
            ends_style: (fg: "${c.base09}"),
            thumb_style: (fg: "${c.base09}"),
          ),

          song_table_format: [
            (
              prop: (kind: Property(Artist), style: (fg: "${c.base09}"),
                default: (kind: Text("Unknown"), style: (fg: "${c.base0E}"))
              ),
              width: "20%",
            ),
            (
              prop: (kind: Property(Title), style: (fg: "${c.base08}"),
                highlighted_item_style: (fg: "${c.base04}", modifiers: "Bold"),
                default: (kind: Property(Filename), style: (fg: "${c.base04}"))
              ),
              width: "35%",
            ),
            (
              prop: (kind: Property(Album), style: (fg: "${c.base09}"),
                default: (kind: Text("Unknown Album"), style: (fg: "${c.base0E}"))
              ),
              width: "30%",
            ),
            (
              prop: (kind: Property(Duration), style: (fg: "${c.base08}"),
                default: (kind: Text("-"))
              ),
              width: "15%",
              alignment: Right,
            ),
          ],

          keybinds: (
                  global: {
                      ":":       CommandMode,
                      ",":       VolumeDown,
                      "s":       Stop,
                      ".":       VolumeUp,
                      "<Tab>":   NextTab,
                      "<S-Tab>": PreviousTab,
                      "L":       NextTab,
                      "H":       PreviousTab,
                      "1":       SwitchToTab("Playing"),
                      "4":       SwitchToTab("Dir"),
                      "3":       SwitchToTab("Lists"),
                      "2":       SwitchToTab("Find"),
                      "q":       Quit,
                      ">":       NextTrack,
                      "p":       TogglePause,
                      "<":       PreviousTrack,
                      "f":       SeekForward,
                      "z":       ToggleRepeat,
                      "x":       ToggleRandom,
                      "c":       ToggleConsume,
                      "v":       ToggleSingle,
                      "b":       SeekBack,
                      "~":       ShowHelp,
                      "I":       ShowCurrentSongInfo,
                      "O":       ShowOutputs,
                      "P":       ShowDecoders,
                  },
                  navigation: {
                      "k":         Up,
                      "j":         Down,
                      "h":         Left,
                      "l":         Right,
                      "<Up>":      Up,
                      "<Down>":    Down,
                      "<Left>":    Left,
                      "<Right>":   Right,
                      "<C-k>":     PaneUp,
                      "<C-j>":     PaneDown,
                      "<C-h>":     PaneLeft,
                      "<C-l>":     PaneRight,
                      "<C-u>":     UpHalf,
                      "N":         PreviousResult,
                      "a":         Add,
                      "A":         AddAll,
                      "r":         Rename,
                      "n":         NextResult,
                      "g":         Top,
                      "<Space>":   Select,
                      "<C-Space>": InvertSelection,
                      "G":         Bottom,
                      "<CR>":      Confirm,
                      "i":         FocusInput,
                      "J":         MoveDown,
                      "<C-d>":     DownHalf,
                      "/":         EnterSearch,
                      "<C-c>":     Close,
                      "<Esc>":     Close,
                      "K":         MoveUp,
                      "D":         Delete,
                  },
                  queue: {
                      "D":       DeleteAll,
                      "<CR>":    Play,
                      "<C-s>":   Save,
                      "a":       AddToPlaylist,
                      "d":       Delete,
                      "i":       ShowInfo,
                      "C":       JumpToCurrent,
                  },
              ),

          layout: Split(
            direction: Vertical,
            panes: [
              (size: "3", pane: Pane(Tabs)),
              (
                size: "4",
                pane: Split(
                  direction: Horizontal,
                  panes: [
                    (
                      size: "100%",
                      pane: Split(
                        direction: Vertical,
                        panes: [
                          (size: "4", borders: "ALL", pane: Pane(Header)),
                        ]
                      )
                    ),
                  ]
                ),
              ),
              (
                size: "100%",
                pane: Split(
                  direction: Horizontal,
                  panes: [
                    (size: "100%", borders: "NONE", pane: Pane(TabContent)),
                  ]
                ),
              ),
              (size: "3", borders: "TOP | BOTTOM", pane: Pane(ProgressBar)),
            ],
          ),

          header: (
            rows: [
              (
                left: [
                  (kind: Text(""), style: (fg: "${c.base09}", modifiers: "Bold")),
                  (kind: Property(Status(StateV2(playing_label: " ", paused_label: " ", stopped_label: " ")))),
                  (kind: Text(" "), style: (fg: "${c.base09}", modifiers: "Bold")),
                  (kind: Property(Widget(ScanStatus)))
                ],
                center: [
                  (kind: Property(Song(Title)), style: (fg: "${c.base04}", modifiers: "Bold"),
                    default: (kind: Property(Song(Filename)), style: (fg: "${c.base04}", modifiers: "Bold"))
                  )
                ],
                right: [
                  (kind: Text("󱡬"), style: (fg: "${c.base09}", modifiers: "Bold")),
                  (kind: Property(Status(Volume)), style: (fg: "${c.base04}", modifiers: "Bold")),
                  (kind: Text("%"), style: (fg: "${c.base09}", modifiers: "Bold"))
                ]
              ),
              (
                left: [
                  (kind: Text("[ "), style: (fg: "${c.base09}", modifiers: "Bold")),
                  (kind: Property(Status(Elapsed)), style: (fg: "${c.base04}")),
                  (kind: Text(" / "), style: (fg: "${c.base09}", modifiers: "Bold")),
                  (kind: Property(Status(Duration)), style: (fg: "${c.base04}")),
                  (kind: Text(" | "), style: (fg: "${c.base09}")),
                  (kind: Property(Status(Bitrate)), style: (fg: "${c.base04}")),
                  (kind: Text(" kbps"), style: (fg: "${c.base09}")),
                  (kind: Text("]"), style: (fg: "${c.base09}", modifiers: "Bold"))
                ],
                center: [
                  (kind: Property(Song(Artist)), style: (fg: "${c.base08}", modifiers: "Bold"),
                    default: (kind: Text("Unknown Artist"), style: (fg: "${c.base08}", modifiers: "Bold"))
                  ),
                  (kind: Text(" - ")),
                  (kind: Property(Song(Album)), style: (fg: "${c.base09}"),
                    default: (kind: Text("Unknown Album"), style: (fg: "${c.base09}", modifiers: "Bold"))
                  )
                ],
                right: [
                  (kind: Text("[ "), style: (fg: "${c.base09}")),
                  (kind: Property(Status(RepeatV2(
                    on_label: "", off_label: "",
                    on_style: (fg: "${c.base04}", modifiers: "Bold"), off_style: (fg: "${c.base03}", modifiers: "Bold")
                  )))),
                  (kind: Text(" | "), style: (fg: "${c.base09}")),
                  (kind: Property(Status(RandomV2(
                    on_label: "", off_label: "",
                    on_style: (fg: "${c.base04}", modifiers: "Bold"), off_style: (fg: "${c.base03}", modifiers: "Bold")
                  )))),
                  (kind: Text(" | "), style: (fg: "${c.base09}")),
                  (kind: Property(Status(ConsumeV2(
                    on_label: "󰮯", off_label: "󰮯", oneshot_label: "󰮯󰇊",
                    on_style: (fg: "${c.base04}", modifiers: "Bold"), off_style: (fg: "${c.base03}", modifiers: "Bold")
                  )))),
                  (kind: Text(" | "), style: (fg: "${c.base09}")),
                  (kind: Property(Status(SingleV2(
                    on_label: "󰎤", off_label: "󰎦", oneshot_label: "󰇊", off_oneshot_label: "󱅊",
                    on_style: (fg: "${c.base04}", modifiers: "Bold"), off_style: (fg: "${c.base03}", modifiers: "Bold")
                  )))),
                  (kind: Text(" ]"), style: (fg: "${c.base09}")),
                ]
              ),
            ],
          ),

          browser_song_format: [
            (
              kind: Group([
                (kind: Property(Track)),
                (kind: Text(" "))
              ])
            ),
            (
              kind: Group([
                (kind: Property(Artist)),
                (kind: Text(" - ")),
                (kind: Property(Title)),
              ]),
              default: (kind: Property(Filename))
            ),
          ],

          tabs: [
            (
              name: "Playing",
              pane: Split(
                  direction: Horizontal,
                  panes: [(size: "65%", pane: Pane(Queue)), (size: "35%", pane: Pane(AlbumArt))],
              ),
            ),
            (
              name: "Directories",
              pane: Split(
                direction: Horizontal,
                panes: [(size: "100%", borders: "ALL", pane: Pane(Directories))],
              ),
            ),
            (
              name: "Artists",
              pane: Split(
                direction: Horizontal,
                panes: [(size: "100%", borders: "ALL", pane: Pane(Artists))],
              ),
            ),
            (
              name: "Albums",
              pane: Split(
                direction: Horizontal,
                panes: [(size: "100%", borders: "ALL", pane: Pane(Albums))],
              ),
            ),
            (
              name: "Playlists",
              pane: Split(
                direction: Horizontal,
                panes: [(size: "100%", borders: "ALL", pane: Pane(Playlists))],
              ),
            ),
            (
              name: "Search",
              pane: Split(
                direction: Horizontal,
                panes: [(size: "100%", borders: "ALL", pane: Pane(Search))],
              ),
            ),
          ],
        )
      '';
    };
  };
}
