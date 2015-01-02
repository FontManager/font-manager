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

        public string? [] source_selection (Gtk.Window? parent) {
            string? [] arr = { };
            var dialog = new Gtk.FileChooserDialog(_("Select source folders"),
                                                        parent,
                                                        Gtk.FileChooserAction.SELECT_FOLDER,
                                                        _("_Cancel"),
                                                        Gtk.ResponseType.CANCEL,
                                                        _("_Open"),
                                                        Gtk.ResponseType.ACCEPT,
                                                        null);
            dialog.set_select_multiple(true);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                foreach (var uri in dialog.get_uris())
                    arr += uri;
            }
            dialog.destroy();
            return arr;
        }

        public string? [] run_install (Gtk.Window? parent) {
            string? [] arr = { };
            var dialog = new Gtk.FileChooserDialog(_("Select files to install"),
                                                        parent,
                                                        Gtk.FileChooserAction.OPEN,
                                                        _("_Cancel"),
                                                        Gtk.ResponseType.CANCEL,
                                                        _("_Open"),
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
                foreach (var uri in dialog.get_uris())
                    arr += uri;
            }
            dialog.destroy();
            return arr;
        }

        public File? [] run_removal (Gtk.Window? parent, UserFontModel font_model) {
            File? [] res = null;
            var dialog = new Gtk.Dialog();
            var cancel = new Gtk.Button.with_mnemonic(_("_Cancel"));
            var remove = new Gtk.Button.with_mnemonic(_("_Delete"));
            var header = new Gtk.HeaderBar();
            var content_area = dialog.get_content_area();
            var scroll = new Gtk.ScrolledWindow(null, null);
            var tree = new UserFontTree(font_model);
            header.set_title(_("Select fonts to remove"));
            header.pack_start(cancel);
            header.pack_end(remove);
            dialog.set_titlebar(header);
            dialog.modal = true;
            dialog.destroy_with_parent = true;
            dialog.set_size_request(540, 480);
            dialog.set_transient_for(parent);
            tree.hexpand = tree.vexpand = true;
            scroll.add(tree);
            content_area.pack_start(scroll, true, true, 0);
            scroll.show_all();
            header.show_all();
            cancel.clicked.connect(() => { dialog.response(Gtk.ResponseType.CANCEL); });
            remove.clicked.connect(() => { dialog.response(Gtk.ResponseType.ACCEPT); });
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                res = tree.to_file_array();
            }
            dialog.destroy();
            return res;
        }

    }

}
