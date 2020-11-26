/* PreviewPane.vala
 *
 * Copyright (C) 2020 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

internal const string HEADER = """
<html dir="%s">
  <head>
    <style>
      body {
        color: %s;
        background-color: %s;
      }
      .noWrap {
        overflow: visible;
        white-space: nowrap;
        display:block;
        width:100%;
      }
      .bodyText {
        margin: 12px 8px 12px 8px;
        text-align: justify;
      }
      .previewText {
        font-family: %s;
        font-style: %s;
        font-weight: %i;
      }
      %s
    </style>
  </head>
  <body>
    <div>
""";

internal const string WATERFALL_ROW = """
      <p id="%i" class="noWrap">
        <span style="font-family: monospace;font-size: 10px;">%s</span>
        <span class="previewText" style="font-size:%ipx;">%s</span>
      </p>
""";

internal const string BODY_TEXT = """
      <p class="bodyText" style="font-size:%0.2fpx;">
        <span class="previewText">%s</span>
      </p>
""";

internal const string FOOTER = """
    </div>
  </body>
</html>
""";

namespace FontManager.GoogleFonts {

    public enum PreviewType {
        WATERFALL,
        LOREM_IPSUM;
    }

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-preview-pane.ui")]
    public class PreviewPane : Gtk.Box {

        public Family? family { get; set; default = null; }
        public Font? font { get; set; default = null; }
        public double preview_size { get; set; default = 16.0; }
        public WebKit.WebView? preview { get; set; default = null; }
        public PreviewType preview_type { get; set; default = PreviewType.WATERFALL; }

        public string preview_text {
            get {
                return _preview_text != null ? _preview_text : default_preview_text;
            }
            set {
                _preview_text = value;
            }
        }

        [GtkChild] Gtk.Box controls;
        [GtkChild] Gtk.Box scale_container;
        [GtkChild] Gtk.Button download_button;
        [GtkChild] Gtk.ScrolledWindow preview_box;
        [GtkChild] Gtk.ColorButton bg_color_button;
        [GtkChild] Gtk.ColorButton fg_color_button;
        [GtkChild] Gtk.MenuButton menu_button;
        [GtkChild] PreviewEntry entry;
        [GtkChild] FontScale fontscale;

        string? _preview_text = null;
        string? default_preview_text = "The quick brown fox jumps over the lazy dog.";
        bool restore_default_preview = false;
        Font? stored_font = null;

        SampleList sample_list;

        WebKit.WebContext get_webkit_context () {
            var web_context = new WebKit.WebContext.ephemeral();
            web_context.set_cache_model(WebKit.CacheModel.DOCUMENT_BROWSER);
            web_context.prefetch_dns("http://fonts.gstatic.com/");
            return web_context;
        }

        WebKit.WebView get_webkit_webview () {
            var preview = new WebKit.WebView.with_context(get_webkit_context());
            preview_box.add(preview);
            preview.show();
            preview.event.connect(on_event);
            var settings = new WebKit.Settings() {
                enable_fullscreen = false,
                enable_java = false,
                enable_media = false,
                enable_mediasource = false,
                enable_plugins = false,
                enable_site_specific_quirks = false,
                enable_smooth_scrolling = true,
                enable_webaudio = false,
                enable_xss_auditor = false
            };
            settings.set_user_agent_with_application_details(Config.PACKAGE_NAME, Config.PACKAGE_VERSION);
            preview.settings = settings;
            return preview;
        }

        construct {
            map.connect(() => {
                if (preview == null)
                    preview = get_webkit_webview();
            });
            entry.set_placeholder_text(preview_text);
            notify["family"].connect((obj, pspec) => { selection_changed(); });
            notify["font"].connect((obj, pspec) => { update_preview(); selection_changed(); });
            notify["preview-text"].connect((obj, pspec) => { entry.set_placeholder_text(preview_text); });
            notify["preview-type"].connect((obj, pspec) => {
                scale_container.set_visible(preview_type == PreviewType.LOREM_IPSUM);
                entry.set_visible(preview_type == PreviewType.WATERFALL);
            });
            notify["preview-size"].connect((obj, pspec) => { update_preview(); });
            bg_color_button.color_set.connect_after(() => { update_preview(); });
            fg_color_button.color_set.connect_after(() => { update_preview(); });
            set_button_relief_style(controls);
            download_button.set_relief(Gtk.ReliefStyle.NORMAL);
            menu_button.set_relief(Gtk.ReliefStyle.NORMAL);
            scale_container.set_visible(preview_type == PreviewType.LOREM_IPSUM);
            entry.set_visible(preview_type == PreviewType.WATERFALL);
            bind_property("preview-size", fontscale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            sample_list = new SampleList() {
                relative_to = entry,
                position = Gtk.PositionType.BOTTOM
            };
            entry.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "preferences-desktop-locale-symbolic");
            entry.icon_press.connect((entry, position, event) => {
                if (position == Gtk.EntryIconPosition.PRIMARY) {
                    sample_list.popup();
                    sample_list.unselect_all();
                }
            });
            sample_list.row_selected.connect((s) => {
                entry.set_text(s);
                sample_list.popdown();
                /* XXX : TODO : How to disable font fallback for WebView? */
                restore_default_preview = true;
                stored_font = font;
            });
        }

        bool on_event (Gtk.Widget widget, Gdk.Event event) {
            if (event.type == Gdk.EventType.SCROLL)
                return Gdk.EVENT_PROPAGATE;
            return Gdk.EVENT_STOP;
        }

        string generate_lorem_ipsum () {
            StringBuilder builder = new StringBuilder();
            Pango.LayoutLine? line = entry.get_layout().get_line(0);
            string text_direction = line != null && line.resolved_dir == Pango.Direction.RTL ? "rtl" : "ltr";
            builder.append(HEADER.printf(text_direction,
                                         fg_color_button.get_rgba().to_string(),
                                         bg_color_button.get_rgba().to_string(),
                                         font.family, font.style, font.weight,
                                         font.to_font_face_rule()));
            builder.append(BODY_TEXT.printf(preview_size, LOREM_IPSUM));
            builder.append(FOOTER);
            return builder.str;
        }

        string generate_waterfall () {
            StringBuilder builder = new StringBuilder();
            Pango.LayoutLine? line = entry.get_layout().get_line(0);
            string text_direction = line != null && line.resolved_dir == Pango.Direction.RTL ? "rtl" : "ltr";
            builder.append(HEADER.printf(text_direction,
                                         fg_color_button.get_rgba().to_string(),
                                         bg_color_button.get_rgba().to_string(),
                                         font.family, font.style, font.weight,
                                         font.to_font_face_rule()));
            for (int i = 6; i <= 96; i++) {
                string pixels = i < 10 ? "&nbsp;&nbsp;%ipx&nbsp".printf(i) : "&nbsp;%ipx&nbsp;".printf(i);
                builder.append(WATERFALL_ROW.printf(i, pixels, i, preview_text));
            }
            builder.append(FOOTER);
            return builder.str;
        }

        void selection_changed (FileStatus? status = null) {
            if (status == null)
                status = family != null ? family.get_installation_status() : font.get_installation_status();
            string label;
            var ctx = download_button.get_style_context();
            switch (status) {
                case FileStatus.REQUIRES_UPDATE:
                    label = family != null ? _("Update Family") : _("Update Font");
                    ctx.remove_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    ctx.add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    break;
                case FileStatus.INSTALLED:
                    label = family != null ? _("Remove Family") : _("Remove Font");
                    ctx.remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    ctx.add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    break;
                default:
                    label = family != null ? _("Download Family") : _("Download Font");
                    ctx.remove_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    ctx.remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    break;
            }
            download_button.set_label(label);
            sample_list.items = family != null ? family.subsets : font.subsets;
            uint langs = sample_list.model.get_n_items();
            entry.set_icon_tooltip_text(
                Gtk.EntryIconPosition.PRIMARY,
                ngettext(_("%i Language Sample Available "),
                         _("%i Language Samples Available"),
                         (ulong) langs).printf((int) langs)
            );
            return;
        }

        public void update_preview () {
            /* Restore default preview if a language sample was selected and the font has changed. */
            if (font != stored_font && restore_default_preview) {
                entry.set_text("");
                preview_text = default_preview_text;
                restore_default_preview = false;
            }
            string html = "<html><body><p> </p></body></html>";
            if (font != null) {
                switch (preview_type) {
                    case PreviewType.WATERFALL:
                        html = generate_waterfall();
                        break;
                    case PreviewType.LOREM_IPSUM:
                        html = generate_lorem_ipsum();
                        break;
                    default:
                        assert_not_reached();
                }
            }
            preview.load_html(html, null);
            return;
        }

        [GtkCallback]
        void on_preview_type_toggled (Gtk.ToggleButton widget) {
            if (!widget.active)
                return;
            preview_type = (PreviewType) int.parse(widget.name);
            menu_button.popover.popdown();
            update_preview();
            return;
        }

        [GtkCallback]
        void on_download_button_clicked () {
            FileStatus status = family != null ? family.get_installation_status() : font.get_installation_status();
            string dirname = family != null ? family.family : font.family;
            File font_dir = File.new_for_path(Path.build_filename(get_font_directory(), dirname));
            if (family != null) {
                if (font_dir.query_exists())
                    remove_directory(font_dir);
                if (status == FileStatus.INSTALLED) {
                    selection_changed(FileStatus.NOT_INSTALLED);
                } else {
                    download_font_files.begin(family.variants.data, (obj, res) => {
                        if (download_font_files.end(res))
                            selection_changed(FileStatus.INSTALLED);
                    });
                }
            } else {
                File? font_file = null;
                if (status == FileStatus.REQUIRES_UPDATE) {
                    string ext = get_file_extension(font.url);
                    string style = font.to_description().replace(" ", "_");
                    string family = font.family.replace(" ", "_");
                    string filename =  "%s_%s.%i.%s".printf(family, style, font.version - 1, ext);
                    font_file = File.new_for_path(Path.build_filename(font_dir.get_path(), filename));
                } else if (status == FileStatus.INSTALLED) {
                    font_file = File.new_for_path(Path.build_filename(font_dir.get_path(), font.get_filename()));
                }
                if (font_file != null) {
                    try {
                        font_file.delete();
                        remove_directory_tree_if_empty(font_dir);
                        selection_changed(FileStatus.NOT_INSTALLED);
                    } catch (Error e) {
                        warning("Failed to remove file : %s", font_file.get_path());
                        critical("%i : %s", e.code, e.message);
                    }
                }
                if (status == FileStatus.NOT_INSTALLED || status == FileStatus.REQUIRES_UPDATE) {
                    download_font_files.begin({font}, (obj, res) => {
                        if (download_font_files.end(res))
                            selection_changed(FileStatus.INSTALLED);
                    });
                }
            }
            Timeout.add(3500, () => { get_default_application().refresh(); return GLib.Source.REMOVE; });
            return;
        }

        [GtkCallback]
        void on_entry_changed () {
            preview_text = (entry.text_length > 0) ? entry.text : null;
            update_preview();
            return;
        }

    }

}
