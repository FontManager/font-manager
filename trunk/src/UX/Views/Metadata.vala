/* Metadata.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
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

        private const string font_desc_templ = "<span size=\"xx-large\" weight=\"bold\">%s</span>    <span size=\"large\" weight=\"bold\">%s</span>";

        private struct FontTypeEntry {

            public string name;
            public string tooltip;
            public string url;

            public FontTypeEntry (string name, string tooltip, string url) {
                this.name = name;
                this.tooltip = tooltip;
                this.url = url;
            }

        }

        private class TypeInfoCache : Object {

            FontTypeEntry [] types = {
                FontTypeEntry("null", "", ""),
                FontTypeEntry("opentype", _("OpenType Font"), "http://wikipedia.org/wiki/OpenType"),
                FontTypeEntry("truetype", _("TrueType Font"), "http://wikipedia.org/wiki/TrueType"),
                FontTypeEntry("type1", _("PostScript Type 1 Font"), "http://wikipedia.org/wiki/Type_1_Font#Type_1"),
            };

            construct {
            #if GTK_314
                var icon_theme = Gtk.IconTheme.get_default();
                icon_theme.add_resource_path("/org/gnome/FontManager/icons");
            #endif
            }

            public void update (Gtk.Image icon, string key) {
                var entry = this[key];
            #if GTK_314
                icon.set_from_icon_name(entry.name, Gtk.IconSize.DIALOG);
            #else
                icon.set_from_resource("/org/gnome/FontManager/icons/%s.svg".printf(entry.name));
            #endif
                icon.set_tooltip_text(entry.tooltip);
            }

            public new FontTypeEntry get (string key) {
                var _key = key.down().replace(" ", "");
                foreach (var entry in types)
                    if (entry.name == _key)
                        return entry;
                return types[0];
            }

        }

        public class Pane : Title {

            public Gtk.Notebook notebook { get; private set; }

            private Details details;
            private Legal legal;

            public Pane () {
                notebook = new Gtk.Notebook();
                notebook.show_border = false;
                details = new Details();
                legal = new Legal();
                notebook.append_page(details, new Gtk.Label(_("Details")));
                notebook.append_page(legal, new Gtk.Label(_("Legal")));
                notebook.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                attach(notebook, 0, 1, 2, 2);
            }

            public override void update (FontData? fontdata) {
                details.update(fontdata);
                legal.update(fontdata);
                base.update(fontdata);
                return;
            }

            public override void show () {
                details.show();
                legal.show();
                notebook.show();
                base.show();
                return;
            }

        }

        public class Title : Gtk.Grid {

            private Gtk.Label font;
            private Gtk.Image type_icon;
            private TypeInfoCache type_info_cache;

            construct {
                font = new Gtk.Label(null);
                font.hexpand = true;
                font.halign = Gtk.Align.START;
                font.xpad = 12;
                font.ypad = 6;
                type_info_cache = new TypeInfoCache();
                type_icon = new Gtk.Image.from_icon_name("null", Gtk.IconSize.DIALOG);
                type_icon.xpad = 12;
                type_icon.ypad = 6;
                attach(font, 0, 0, 1, 1);
                attach(type_icon, 1, 0, 1, 1);
                get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            }

            public override void show () {
                font.show();
                type_icon.show();
                base.show();
                return;
            }

            private void reset () {
                font.set_text("");
                type_info_cache.update(type_icon, "null");
                return;
            }

            public virtual void update (FontData? fontdata) {
                this.reset();
                if (fontdata == null)
                    return;
                var fontinfo = fontdata.fontinfo;
                var fcfont = fontdata.font;
                var font_desc = font_desc_templ.printf(fcfont.family, fcfont.style);
                font.set_markup(font_desc);
                type_info_cache.update(type_icon, fontinfo.filetype);
                return;
            }

        }

        public class Details : Gtk.Grid {

            private Gtk.Label psname;
            private Gtk.Label weight;
            private Gtk.Label slant;
            private Gtk.Label width;
            private Gtk.Label spacing;
            private Gtk.Label version;
            private Gtk.Label vendor;
            private Gtk.Separator separator;
            private Description description;

            private string [] labels = {
                _("PostScript Name"),
                _("Weight"),
                _("Slant"),
                _("Width"),
                _("Spacing"),
                _("Version"),
                _("Vendor")
            };

            construct {
                expand = true;
                column_homogeneous = false;
                row_homogeneous = true;
                psname = new Gtk.Label("psname");
                weight = new Gtk.Label("weight");
                slant = new Gtk.Label("slant");
                width = new Gtk.Label("width");
                spacing = new Gtk.Label("spacing");
                version = new Gtk.Label("version");
                vendor = new Gtk.Label("vendor");
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
                    attach(widget, 0, i, 1, 1);
                    widget.halign = Gtk.Align.END;
                    widget.margin_start = 12;
                    widget.margin_end = 12;
                    widget.vexpand = true;
                    attach(values[i], 1, i, 1, 1);
                    values[i].halign = Gtk.Align.START;
                    values[i].margin_start = 12;
                    values[i].margin_end = 12;
                    if (i == 0) {
                        widget.margin_top = 12;
                        values[i].margin_top = 12;
                    } else if (i == labels.length - 1) {
                        widget.margin_bottom = 12;
                        values[i].margin_bottom = 12;
                    }
                    widget.show();
                    values[i].show();
                }
            }

            public Details () {
                description = new Description();
                separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
                separator.set_size_request(1, -1);
                separator.margin = 6;
                separator.margin_top = 12;
                separator.margin_bottom = 12;
                separator.opacity = 0.90;
                attach(separator, 2, 0, 1, 7);
                attach(description, 3, 0, 1, 7);
            }

            public override void show () {
                separator.show();
                description.show();
                base.show();
                return;
            }

            private void reset () {
                weight.set_text("");
                slant.set_text("");
                width.set_text("");
                spacing.set_text("");
                version.set_text("");
                vendor.set_text("");
                return;
            }

            public void update (FontData? fontdata) {
                description.update(fontdata);
                this.reset();
                if (fontdata == null)
                    return;
                var fontinfo = fontdata.fontinfo;
                var fcfont = fontdata.font;
                psname.set_text(fontinfo.psname);
                string? _weight = ((FontConfig.Weight) fcfont.weight).to_string();
                if (_weight == null)
                    _weight = "Regular";
                weight.set_text(_weight);
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
                    get_child_at(0, 6).hide();
                    vendor.hide();
                } else {
                    vendor.show();
                    get_child_at(0, 6).show();
                }
                return;
            }

        }

        public class Description : StaticTextView {

            public Description () {
                base(null);
                view.margin = 12;
                view.justification = Gtk.Justification.LEFT;
                view.pixels_above_lines = 1;
                set_size_request(0, 0);
                get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                expand = true;
            }

            private void reset () {
                buffer.set_text("");
                return;
            }

            public void update (FontData? fontdata) {
                this.reset();
                if (fontdata == null)
                    return;
                var fontinfo = fontdata.fontinfo;
                if (fontinfo.copyright != null)
                    view.buffer.set_text("%s".printf(fontinfo.copyright));
                if (fontinfo.description != null && fontinfo.description.length > 10)
                    view.buffer.set_text("%s\n\n%s".printf(get_buffer_text(), fontinfo.description));
                return;
            }

        }

        public class Legal : Gtk.Overlay {

            private Gtk.Grid grid;
            private Gtk.EventBox blend;
            private Gtk.Label label;
            private Gtk.LinkButton link;
            private StaticTextView view;

            public Legal () {
                grid = new Gtk.Grid();
                view = new StaticTextView(null);
                view.view.left_margin = 12;
                view.view.right_margin = 12;
                view.view.pixels_above_lines = 1;
                label = new Gtk.Label(_("File does not contain license description."));
                label.sensitive = false;
                link = new Gtk.LinkButton("https://code.google.com/p/font-manager/");
                link.set_label("");
                link.halign = Gtk.Align.CENTER;
                link.valign = Gtk.Align.CENTER;
                blend = new Gtk.EventBox();
                blend.add(link);
                blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                view.expand = true;
                grid.attach(view, 0, 0, 1, 3);
                grid.attach(blend, 0, 3, 1 ,1);
                add(grid);
                add_overlay(label);
            }

            public override void show () {
                link.show();
                view.show();
                label.show();
                grid.show();
                blend.show();
                base.show();
                this.reset();
                return;
            }

            private void reset () {
                view.buffer.set_text("");
                link.set_uri("https://code.google.com/p/font-manager/");
                link.set_label("");
                blend.hide();
                view.hide();
                label.show();
                return;
            }

            public void update (FontData? fontdata) {
                this.reset();
                if (fontdata == null)
                    return;
                var fontinfo = fontdata.fontinfo;
                if (fontinfo.license_data == null && fontinfo.license_url == null)
                    return;
                if (fontinfo.license_url != null) {
                    link.set_uri(fontinfo.license_url);
                    link.set_label(fontinfo.license_url);
                    blend.show();
                }
                bool license_data = (fontinfo.license_data != null);
                if (license_data)
                    view.buffer.set_text("\n%s\n".printf(fontinfo.license_data));
                view.visible = license_data;
                link.expand = !license_data;
                if (!license_data && fontinfo.license_url == null)
                    label.show();
                else
                    label.hide();
                return;
            }

        }

    }

}
