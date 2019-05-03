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

    enum Embedding {

        INSTALLABLE = 0,
        RESTRICTED_LICENSE = 2,
        PREVIEW_AND_PRINT = 4,
        EDITABLE = 8,
        PREVIEW_AND_PRINT_NO_SUBSET = 260,
        EDITABLE_NO_SUBSET = 264,
        PREVIEW_AND_PRINT_BITMAP_ONLY = 516,
        EDITABLE_BITMAP_ONLY = 520,
        PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY = 772,
        EDITABLE_NO_SUBSET_BITMAP_ONLY = 776;

        public string to_string () {
            switch (this) {
                case RESTRICTED_LICENSE:
                    return _("Restricted License Embedding");
                case PREVIEW_AND_PRINT:
                    return _("Preview & Print Embedding");
                case EDITABLE:
                    return _("Editable Embedding");
                case PREVIEW_AND_PRINT_NO_SUBSET:
                    return _("Preview & Print Embedding | No Subsetting");
                case EDITABLE_NO_SUBSET:
                    return _("Editable Embedding | No Subsetting");
                case PREVIEW_AND_PRINT_BITMAP_ONLY:
                    return _("Preview & Print Embedding | Bitmap Embedding Only");
                case EDITABLE_BITMAP_ONLY:
                    return _("Editable Embedding | Bitmap Embedding Only");
                case PREVIEW_AND_PRINT_NO_SUBSET_BITMAP_ONLY:
                    return _("Preview & Print Embedding | No Subsetting | Bitmap Embedding Only");
                case EDITABLE_NO_SUBSET_BITMAP_ONLY:
                    return _("Editable Embedding | No Subsetting | Bitmap Embedding Only");
                default:
                    return _("Installable Embedding");
            }
        }

    }

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
            properties.show();
            license.show();
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
            if (update_pending) {
                info = null;
                update();
                update_pending = false;
            }
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-license-pane.ui")]
    public class LicensePane : Gtk.Overlay {

        public bool is_mapped { get; private set; default = false; }

        [GtkChild] Gtk.Label fsType;
        [GtkChild] Gtk.Label license;
        [GtkChild] Gtk.LinkButton license_url;

        PlaceHolder notice;

        public override void constructed () {
            var tmpl = "<big>%s</big>";
            var msg = _("File does not contain license information.");
            notice = new PlaceHolder(tmpl.printf(msg), "dialog-question-symbolic");
            add_overlay(notice);
            map.connect(() => { is_mapped = true; });
            unmap.connect(() => { is_mapped = false; });
            base.constructed();
            return;
        }

        void reset () {
            fsType.set_text("");
            license.set_text("");
            license_url.set_uri("");
            license_url.set_label("");
            fsType.hide();
            license.hide();
            license_url.hide();
            notice.show();
            return;
        }

        public void update (FontInfo? info) {
            reset();
            if (!is_valid_source(info) || info.license_data == null && info.license_url == null)
                return;
            bool license_data = (info.license_data != null);
            if (license_data)
                license.set_text(info.license_data);
            fsType.set_text(((Embedding) info.fsType).to_string());
            fsType.show();
            license.set_visible(license_data);
            license_url.expand = !license_data;
            if (info.license_url != null) {
                license_url.set_uri(info.license_url);
                license_url.set_label(info.license_url);
                license_url.show();
            }
            notice.hide();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-properties-pane.ui")]
    public class PropertiesPane : Gtk.Box {

        public bool is_mapped { get; private set; default = false; }

        [GtkChild] Gtk.Label psname;
        [GtkChild] Gtk.Label width;
        [GtkChild] Gtk.Label slant;
        [GtkChild] Gtk.Label weight;
        [GtkChild] Gtk.Label __spacing;
        [GtkChild] Gtk.Label version;
        [GtkChild] Gtk.Label _vendor;
        [GtkChild] Gtk.Label vendor;
        [GtkChild] Gtk.Label filetype;
        [GtkChild] Gtk.Label filesize;
        [GtkChild] Gtk.Label copyright;
        [GtkChild] Gtk.Label description;
        [GtkChild] Gtk.Label design_label;
        [GtkChild] Gtk.LinkButton design_link;

        Gtk.Label [] values;

        public override void constructed () {
            map.connect(() => { is_mapped = true; });
            unmap.connect(() => { is_mapped = false; });
            values = { psname, width, slant, weight, __spacing, version, vendor,
                        filetype, filesize, copyright, description, design_label };
            base.constructed();
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
            reset();
            if (!is_valid_source(font) || !is_valid_source(info))
                return;
            psname.set_text(info.psname);
            string? _width = ((Width) font.width).to_string();
            width.set_text(_width == null ? "Normal" : _width);
            string? _slant = ((Slant) font.slant).to_string();
            slant.set_text(_slant == null ? "Normal" : _slant);
            string? _weight = ((Weight) font.weight).to_string();
            weight.set_text(_weight == null ? "Regular" : _weight);
            string? _spacing = ((Spacing) font.spacing).to_string();
            __spacing.set_text(_spacing == null ? "Proportional" : _spacing);
            version.set_text(info.version);
            vendor.set_text(info.vendor);
            bool vendor_visibility = (info.vendor != "Unknown Vendor");
            _vendor.set_visible(vendor_visibility);
            vendor.set_visible(vendor_visibility);
            filetype.set_text(info.filetype);
            filesize.set_text(info.filesize);
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
            if (info.copyright != null)
                copyright.set_text(info.copyright);
            if (info.description != null && info.description.length > 10)
                description.set_text(info.description);
            return;
        }

    }

}
