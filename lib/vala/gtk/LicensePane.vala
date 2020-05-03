/* LicensePane.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    /**
     * LicensePane:
     *
     * Widget which displays any available licensing information for the selected file.
     */
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
            license.hide();
            license_url.hide();
            notice.show();
            return;
        }

        public void update (FontInfo? info) {
            reset();
            if (!info.is_valid())
                return;
            fsType.set_text(((Embedding) info.fsType).to_string());
            if (info.license_data == null && info.license_url == null)
                return;
            bool license_data = (info.license_data != null);
            if (license_data)
                license.set_text(info.license_data);
            license.set_visible(license_data);
            license_url.expand = !license_data;
            if (info.license_url != null) {
                license_url.set_uri(info.license_url);
                license_url.set_label(info.license_url);
                license_url.show();
            }
            notice.set_visible(!license_data);
            return;
        }

    }

}
