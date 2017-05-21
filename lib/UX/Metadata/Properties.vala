/* Properties.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontManager {

    namespace Metadata {

        public class Properties : Gtk.Grid {

            Gtk.Label [] labels;
            Gtk.Grid prop_grid;
            Gtk.Separator separator;
            Description description;

            string [] props = {
                _("PostScript Name"),
                _("Weight"),
                _("Slant"),
                _("Width"),
                _("Spacing"),
                _("Version"),
                _("Vendor")
            };

            public Properties () {
                expand = true;
                description = new Description();
                separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
                separator.set_size_request(1, -1);
                separator.margin = DEFAULT_MARGIN_SIZE / 4;
                separator.margin_top = separator.margin_bottom = DEFAULT_MARGIN_SIZE / 2;
                separator.opacity = 0.5;
                foreach (string prop in props)
                    labels += new Gtk.Label("");
                prop_grid = new Gtk.Grid();
                prop_grid.expand = false;
                for (int i = 0; i < labels.length; i++) {
                    var widget = new Gtk.Label(props[i]);
                    widget.sensitive = false;
                    widget.opacity = 0.75;
                    widget.halign = Gtk.Align.END;
                    widget.margin = DEFAULT_MARGIN_SIZE / 2;
                    widget.margin_start = DEFAULT_MARGIN_SIZE;
                    widget.expand = false;
                    labels[i].halign = Gtk.Align.START;
                    labels[i].expand = false;
                    labels[i].margin = DEFAULT_MARGIN_SIZE / 2;
                    labels[i].margin_end = DEFAULT_MARGIN_SIZE;
                    if (i == 0) {
                        widget.margin_top = DEFAULT_MARGIN_SIZE;
                        labels[i].margin_top = DEFAULT_MARGIN_SIZE;
                    } else if (i == labels.length - 1) {
                        widget.margin_bottom = DEFAULT_MARGIN_SIZE;
                        labels[i].margin_bottom = DEFAULT_MARGIN_SIZE;
                    }
                    prop_grid.attach(widget, 0, i, 1, 1);
                    prop_grid.attach(labels[i], 1, i, 1, 1);
                    widget.show();
                    labels[i].show();
                }
                attach(prop_grid, 0, 0, 1, 1);
                attach(separator, 2, 0, 1, 7);
                attach(description, 3, 0, 3, 7);
                get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            }

            public override void show () {
                prop_grid.show();
                separator.show();
                description.show();
                base.show();
                return;
            }

            void reset () {
                foreach (Gtk.Label label in labels)
                    label.set_text("");
                return;
            }

            public void update (FontData? font_data) {
                description.update(font_data);
                this.reset();
                if (font_data == null || font_data.fontinfo == null)
                    return;
                var fontinfo = font_data.fontinfo;
                var fcfont = font_data.font;
                labels[0].set_text(fontinfo.psname);
                string? _weight = ((FontConfig.Weight) fcfont.weight).to_string();
                labels[1].set_text(_weight == null ? "Regular" : _weight);
                string? _slant = ((FontConfig.Slant) fcfont.slant).to_string();
                labels[2].set_text(_slant == null ? "Normal" : _slant);
                string? _width = ((FontConfig.Width) fcfont.width).to_string();
                labels[3].set_text(_width == null ? "Normal" : _width);
                string? _spacing = ((FontConfig.Spacing) fcfont.spacing).to_string();
                labels[4].set_text(_spacing == null ? "Proportional" : _spacing);
                labels[5].set_text(fontinfo.version);
                labels[6].set_text(fontinfo.vendor);
                if (fontinfo.vendor == "Unknown Vendor") {
                    prop_grid.get_child_at(0, 6).hide();
                    labels[6].hide();
                } else {
                    labels[6].show();
                    prop_grid.get_child_at(0, 6).show();
                }
                return;
            }

        }

    }

}

