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
<html>
  <head>
    <style>
      .nowrap{
        overflow: visible;
        white-space: nowrap;
        display:block;
        width:100%;
      }
      body {
        color: %s;
        background-color: %s;
    }
      %s
    </style>
  </head>
  <body>
    <div>
""";

internal const string WATERFALL_ROW = """
      <p id="%i" class="nowrap">
        <span style="font-family: monospace;font-size: 10px;">%s</span>
        <span class="previewText" style="font-size:%ipx;font-family:%s;font-style:%s;font-weight:%i;">%s</span>
      </p>
""";

internal const string FOOTER = """
    </div>
  </body>
</html>
""";

namespace FontManager.GoogleFonts {

    [GtkTemplate (ui = "/org/gnome/FontManager/web/google/ui/google-fonts-preview-pane.ui")]
    public class PreviewPane : Gtk.Box {

        public Family? family { get; set; default = null; }
        public Font? font { get; set; default = null; }

        public string preview_text {
            get {
                return _preview_text != null ? _preview_text : default_preview_text;
            }
            set {
                _preview_text = value;
            }
        }

        [GtkChild] Gtk.Box controls;
        [GtkChild] Gtk.Button download_button;
        [GtkChild] Gtk.ScrolledWindow preview_box;
        [GtkChild] Gtk.ColorButton bg_color_button;
        [GtkChild] Gtk.ColorButton fg_color_button;
        [GtkChild] PreviewEntry entry;

        WebKit.WebView? preview = null;
        string? _preview_text = null;
        string? default_preview_text = "The quick brown fox jumps over the lazy dog.";

        WebKit.WebContext get_webkit_context () {
            var web_context = new WebKit.WebContext.ephemeral();
            web_context.set_cache_model(WebKit.CacheModel.DOCUMENT_BROWSER);
            web_context.prefetch_dns("https://www.googleapis.com/");
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
            notify["preview-text"].connect(() => { entry.set_placeholder_text(preview_text); });
            bg_color_button.color_set.connect_after(() => { update_preview(); });
            fg_color_button.color_set.connect_after(() => { update_preview(); });
            set_button_relief_style(controls);
            download_button.set_relief(Gtk.ReliefStyle.NORMAL);
        }

        bool on_event (Gtk.Widget widget, Gdk.Event event) {
            if (event.type == Gdk.EventType.SCROLL)
                return Gdk.EVENT_PROPAGATE;
            message(preview.get_settings().user_agent);
            return Gdk.EVENT_STOP;
        }

        string generate_waterfall () {
            StringBuilder builder = new StringBuilder();
            builder.append(HEADER.printf(fg_color_button.get_rgba().to_string(),
                                         bg_color_button.get_rgba().to_string(),
                                         font.to_font_face_rule()));
            for (int i = 6; i <= 96; i++) {
                string pixels = i < 10 ? "&nbsp;&nbsp;%ipx&nbsp".printf(i) : "&nbsp;%ipx&nbsp;".printf(i);
                builder.append(WATERFALL_ROW.printf(i, pixels, i, font.family, font.style, font.weight, preview_text));
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
            return;
        }

        public void update_preview () {
            string html = "<html><body><p> </p></body></html>";
            if (font != null)
                html = generate_waterfall();
            preview.load_html(html, null);
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
