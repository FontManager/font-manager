/* PropertiesPane.vala
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

    /**
     * LicensePane:
     *
     * Widget which displays common properties for the selected file.
     */
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
            if (info.designer_url != null) {
                design_link.set_label(info.designer_url);
                design_link.set_uri(info.designer_url);
                design_link.show();
                if (info.designer != null)
                    design_link.set_label(info.designer);
                /* XXX : GtkLinkButton label seems to be created / destroyed on demand? */
                List <weak Gtk.Widget>? children = design_link.get_children();
                if (children != null) {
                    Gtk.Widget? label = children.nth_data(0);
                    if (label != null && label is Gtk.Label)
                        ((Gtk.Label) label).set("ellipsize", Pango.EllipsizeMode.END, null);
                }
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
