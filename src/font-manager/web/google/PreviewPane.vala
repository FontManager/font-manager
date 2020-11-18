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

        public Font? font { get; set; default = null; }

        public string preview_text {
            get {
                return _preview_text != null ? _preview_text : default_preview_text;
            }
            set {
                _preview_text = value;
            }
        }

        [GtkChild] Gtk.ScrolledWindow preview_box;
        [GtkChild] Gtk.ColorButton bg_color_button;
        [GtkChild] Gtk.ColorButton fg_color_button;
        [GtkChild] PreviewEntry entry;

        WebKit.WebView preview;
        string? _preview_text = null;
        string? default_preview_text = "The quick brown fox jumps over a lazy dog.";

        construct {
            preview = new WebKit.WebView.with_context(get_webkit_context());
            preview_box.add(preview);
            preview.show();
            entry.set_placeholder_text(preview_text);
            notify["font"].connect(update_preview);
            notify["preview-text"].connect(() => { entry.set_placeholder_text(preview_text); });
            bg_color_button.color_set.connect_after(() => { update_preview(); });
            fg_color_button.color_set.connect_after(() => { update_preview(); });
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

        public void update_preview () {
            string html = "<html><body><p> </p></body></html>";
            if (font != null)
                html = generate_waterfall();
            preview.load_html(html, null);
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
