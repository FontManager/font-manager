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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontManager {

    namespace Metadata {

        public class Properties : Gtk.Grid {

            Gtk.Label psname;
            Gtk.Label weight;
            Gtk.Label slant;
            Gtk.Label width;
            Gtk.Label spacing;
            Gtk.Label version;
            Gtk.Label vendor;
            Gtk.Grid prop_grid;
            Gtk.Separator separator;
            Description description;

            string [] labels = {
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
                separator.margin = 6;
                separator.margin_top = 12;
                separator.margin_bottom = 12;
                separator.opacity = 0.90;
                psname = new Gtk.Label("psname");
                weight = new Gtk.Label("weight");
                slant = new Gtk.Label("slant");
                width = new Gtk.Label("width");
                spacing = new Gtk.Label("spacing");
                version = new Gtk.Label("version");
                vendor = new Gtk.Label("vendor");
                prop_grid = create_prop_grid();
                attach(prop_grid, 0, 0, 1, 1);
                attach(separator, 2, 0, 1, 7);
                attach(description, 3, 0, 3, 7);
            }

            public override void show () {
                prop_grid.show();
                separator.show();
                description.show();
                base.show();
                return;
            }

            void reset () {
                weight.set_text("");
                slant.set_text("");
                width.set_text("");
                spacing.set_text("");
                version.set_text("");
                vendor.set_text("");
                return;
            }

            public void update (FontData? font_data) {
                description.update(font_data);
                this.reset();
                if (font_data == null || font_data.fontinfo == null)
                    return;
                var fontinfo = font_data.fontinfo;
                var fcfont = font_data.font;
                psname.set_text(fontinfo.psname);
                string? _weight = ((FontConfig.Weight) fcfont.weight).to_string();
                weight.set_text(_weight == null ? "Regular" : _weight);
                string? _slant = ((FontConfig.Slant) fcfont.slant).to_string();
                if (_slant == null)
                    _slant = "Normal";
                slant.set_text(_slant);
                string? _width = ((FontConfig.Width) fcfont.width).to_string();
                if (_width == null)
                    _width = "Normal";
                width.set_text(_width);
                string? _spacing = ((FontConfig.Spacing) fcfont.spacing).to_string();
                if (_spacing == null)
                    _spacing = "Proportional";
                spacing.set_text(_spacing);
                version.set_text(fontinfo.version);
                vendor.set_text(fontinfo.vendor);
                if (fontinfo.vendor == "Unknown Vendor") {
                    prop_grid.get_child_at(0, 6).hide();
                    vendor.hide();
                } else {
                    vendor.show();
                    prop_grid.get_child_at(0, 6).show();
                }
                return;
            }

            Gtk.Grid create_prop_grid () {
                var grid = new Gtk.Grid();
                grid.expand = false;
                Gtk.Label [] values = {
                    psname,
                    weight,
                    slant,
                    width,
                    spacing,
                    version,
                    vendor
                };
                for (int i = 0; i < labels.length; i++) {
                    var widget = new Gtk.Label(labels[i]);
                    widget.sensitive = false;
                    grid.attach(widget, 0, i, 1, 1);
                    widget.halign = Gtk.Align.END;
                    widget.margin = 12;
                    widget.expand = false;
                    grid.attach(values[i], 1, i, 1, 1);
                    values[i].halign = Gtk.Align.START;
                    values[i].expand = false;
                    values[i].margin = 12;
                    if (i == 0) {
                        widget.margin_top = 24;
                        values[i].margin_top = 24;
                    } else if (i == labels.length - 1) {
                        widget.margin_bottom = 24;
                        values[i].margin_bottom = 24;
                    }
                    widget.show();
                    values[i].show();
                }
                return grid;
            }

        }

    }

}

