/* Metadata.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

namespace FontManager {

    public class Metadata : Object {

        public Font? selected_font { get; set; default = null; }
        public FontInfo? info { get; private set; default = null; }

        public PropertiesPane properties { get; private set; }
        public LicensePane license { get; private set; }

        bool update_pending = false;

        public Metadata () {
            properties = new PropertiesPane();
            license = new LicensePane();
            info = new FontInfo();
            connect_signals();
        }

        public void show () {
            properties.show();
            license.show();
            return;
        }

        void connect_signals () {
            notify["selected-font"].connect(() => { update_pending = true; update_if_needed(); });
            properties.notify["is-mapped"].connect(() => { update_if_needed(); });
            license.notify["is-mapped"].connect(() => { update_if_needed(); });
            return;
        }

        public void update () {
            if (is_valid_source(selected_font)) {
                info = new FontInfo();
                try {
                    Database db = get_database(DatabaseType.BASE);
                    string select = "SELECT * FROM Metadata WHERE filepath='%s' AND findex='%i'";
                    string query = select.printf(selected_font.filepath, selected_font.findex);
                    info.source_object = db.get_object(query);
                } catch (DatabaseError e) { }
                if (info.source_object == null)
                    info.source_object = get_metadata(selected_font.filepath, selected_font.findex);
            }
            properties.update(selected_font, info);
            license.update(info);
            return;
        }

        void update_if_needed () {
            if (!properties.is_mapped && !license.is_mapped)
                return;
            if (!update_pending)
                return;
            info = null;
            update();
            update_pending = false;
            return;
        }

    }

    public class DescriptionPane : StandardTextView {

        public DescriptionPane () {
            base(null);
            view.set("pixels-above-lines", 1, "expand", true,
                      "justification", Gtk.Justification.LEFT,
                      "margin", DEFAULT_MARGIN_SIZE, null);
        }

        public void update (FontInfo? info) {
            buffer.set_text("");
            if (!is_valid_source(info))
                return;
            if (info.copyright != null)
                buffer.set_text("%s".printf(info.copyright));
            if (info.description != null && info.description.length > 10)
                buffer.set_text("%s\n\n%s".printf(get_buffer_text(), info.description));
            return;
        }

    }

    public class LicensePane : Gtk.Overlay {

        public bool is_mapped { get; private set; default = false; }

        Gtk.Grid grid;
        Gtk.EventBox blend;
        Gtk.LinkButton link;
        StandardTextView view;
        PlaceHolder notice;
        Gtk.Widget [] widgets;

        public LicensePane () {
            grid = new Gtk.Grid();
            view = new StandardTextView(null);
            view.expand = true;
            view.view.margin = DEFAULT_MARGIN_SIZE;
            view.view.pixels_above_lines = 1;
            var tmpl = "<big>%s</big>";
            var msg = _("File does not contain license information.");
            notice = new PlaceHolder(tmpl.printf(msg), "dialog-question-symbolic");
            link = new Gtk.LinkButton.with_label("", "");
            link.set("halign", Gtk.Align.CENTER, "valign", Gtk.Align.CENTER,
                      "margin", DEFAULT_MARGIN_SIZE / 4, null);
            blend = new Gtk.EventBox();
            blend.add(link);
            blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.attach(view, 0, 0, 1, 3);
            grid.attach(blend, 0, 3, 1 ,1);
            grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            add(grid);
            add_overlay(notice);
            widgets = { grid, blend, link, view, notice };
            connect_signals();
        }

        void connect_signals () {
            map.connect(() => { is_mapped = true; });
            unmap.connect(() => { is_mapped = false; });
            return;
        }

        public override void show () {
            foreach (var widget in widgets)
                widget.show();
            base.show();
            reset();
            return;
        }

        void reset () {
            view.buffer.set_text("");
            link.set_uri("");
            link.set_label("");
            blend.hide();
            view.hide();
            notice.show();
            return;
        }

        public void update (FontInfo? info) {
            reset();
            if (!is_valid_source(info) || info.license_data == null && info.license_url == null)
                return;
            bool license_data = (info.license_data != null);
            if (license_data)
                view.buffer.set_text("\n%s\n".printf(info.license_data));
            view.visible = license_data;
            link.expand = !license_data;
            if (info.license_url != null) {
                link.set_uri(info.license_url);
                link.set_label(info.license_url);
                blend.show();
            }
            notice.hide();
            return;
        }

    }

    public class PropertiesPane : Gtk.Grid {

        public bool is_mapped { get; private set; default = false; }

        Gtk.Label [] values;
        Gtk.Grid prop_grid;
        Gtk.Separator separator;
        DescriptionPane description;
        Gtk.Label design_label;
        Gtk.LinkButton design_link;

        string [] props = {
            _("PostScript Name"),
            _("Width"),
            _("Slant"),
            _("Weight"),
            _("Spacing"),
            _("Version"),
            _("Vendor"),
            _("FileType"),
            _("Filesize")
        };

        public PropertiesPane () {
            expand = true;
            description = new DescriptionPane();
            design_label = new Gtk.Label(null);
            design_label.margin_bottom = DEFAULT_MARGIN_SIZE / 2;
            design_link = new Gtk.LinkButton.with_label("", "");
            design_link.margin_bottom = DEFAULT_MARGIN_SIZE / 4;
            separator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
            separator.set_size_request(1, -1);
            separator.set("opacity", 0.5, "margin", DEFAULT_MARGIN_SIZE / 4,
                           "margin-top", DEFAULT_MARGIN_SIZE / 2,
                           "margin-bottom", DEFAULT_MARGIN_SIZE / 2, null);
            foreach (string prop in props)
                values += new Gtk.Label("");
            prop_grid = new Gtk.Grid();
            prop_grid.expand = false;
            for (int i = 0; i < values.length; i++) {
                var widget = new Gtk.Label(props[i]);
                widget.set("sensitive", false, "opacity", 0.9,
                            "halign", Gtk.Align.END, "expand", false,
                            "margin", DEFAULT_MARGIN_SIZE / 3,
                            "margin-start", DEFAULT_MARGIN_SIZE,
                            "margin-end", DEFAULT_MARGIN_SIZE / 2, null);
                values[i].set("halign", Gtk.Align.START, "expand", false,
                               "margin", DEFAULT_MARGIN_SIZE / 3,
                               "margin-start", DEFAULT_MARGIN_SIZE / 2,
                               "margin-end", DEFAULT_MARGIN_SIZE,
                               "ellipsize", Pango.EllipsizeMode.END,
                               "selectable", true, "can-focus", false, null);
                ((Gtk.Label) values[i]).set_line_wrap(true);
                if (i == 0) {
                    widget.margin_top = DEFAULT_MARGIN_SIZE;
                    values[i].margin_top = DEFAULT_MARGIN_SIZE;
                } else if (i == values.length - 1) {
                    widget.margin_bottom = DEFAULT_MARGIN_SIZE;
                    values[i].margin_bottom = DEFAULT_MARGIN_SIZE;
                }
                prop_grid.attach(widget, 0, i, 1, 1);
                prop_grid.attach(values[i], 1, i, 1, 1);
                widget.show();
                values[i].show();
            }
            attach(prop_grid, 0, 0, 2, 1);
            attach(separator, 2, 0, 1, 2);
            attach(description, 3, 0, 3, 1);
            attach(design_link, 3, 1, 3, 1);
            attach(design_label, 3, 1, 3, 1);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            connect_signals();
        }

        void connect_signals () {
            map.connect(() => { is_mapped = true; });
            unmap.connect(() => { is_mapped = false; });
            return;
        }

        public override void show () {
            prop_grid.show();
            separator.show();
            description.show();
            base.show();
            return;
        }

        void reset () {
            foreach (Gtk.Label label in values)
                label.set_text("");
            design_label.hide();
            design_link.hide();
            return;
        }

        public void update (Font? font, FontInfo? info) {
            description.update(info);
            reset();
            if (!is_valid_source(font) || !is_valid_source(info))
                return;
            values[0].set_text(info.psname);
            string? _width = ((Width) font.width).to_string();
            values[1].set_text(_width == null ? "Normal" : _width);
            string? _slant = ((Slant) font.slant).to_string();
            values[2].set_text(_slant == null ? "Normal" : _slant);
            string? _weight = ((Weight) font.weight).to_string();
            values[3].set_text(_weight == null ? "Regular" : _weight);
            string? _spacing = ((Spacing) font.spacing).to_string();
            values[4].set_text(_spacing == null ? "Proportional" : _spacing);
            values[5].set_text(info.version);
            values[6].set_text(info.vendor);
            if (info.vendor == "Unknown Vendor") {
                prop_grid.get_child_at(0, 6).hide();
                values[6].hide();
            } else {
                values[6].show();
                prop_grid.get_child_at(0, 6).show();
            }
            values[7].set_text(info.filetype);
            values[8].set_text(info.filesize);
            if (info.designer != null && info.designer_url != null) {
                if (info.designer.length < 96)
                    design_link.set_label(info.designer);
                else
                    design_link.set_label(info.designer_url);
                design_link.set_uri(info.designer_url);
                design_link.show();
            } else if (info.designer != null) {
                design_label.set_text(info.designer);
                design_label.show();
            }
            return;
        }

    }

}
