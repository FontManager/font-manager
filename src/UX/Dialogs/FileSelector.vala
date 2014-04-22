/* FileSelector.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    namespace FileSelector {

        public static string? [] run (Gtk.Window? parent) {
            string? [] arr = { };
            var dialog = new Gtk.FileChooserDialog("Select files to install",
                                                        parent,
                                                        Gtk.FileChooserAction.OPEN,
                                                        Gtk.Stock.CANCEL,
                                                        Gtk.ResponseType.CANCEL,
                                                        Gtk.Stock.OPEN,
                                                        Gtk.ResponseType.ACCEPT,
                                                        null);
            var filter = new Gtk.FileFilter();
            var archive_manager = new ArchiveManager();
            foreach (var mimetype in archive_manager.get_supported_types())
                if (!(mimetype in ARCHIVE_IGNORE_LIST))
                    filter.add_mime_type(mimetype);
            foreach (var mimetype in FONT_MIMETYPES)
                filter.add_mime_type(mimetype);
            dialog.set_filter(filter);
            dialog.set_select_multiple(true);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                ensure_ui_update();
                foreach (var uri in dialog.get_uris())
                    arr += uri;
            }
            dialog.destroy();
            return arr;
        }
    }

}
