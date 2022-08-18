/* Dialogs.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

    public const string [] FONT_MIMETYPES = {
        "application/x-font-ttf",
        "application/x-font-ttc",
        "application/x-font-otf",
        "application/x-font-type1",
        "font/ttf",
        "font/ttc",
        "font/otf",
        "font/type1",
        "font/collection"
    };

    namespace FileSelector {

        public Gtk.FileChooserNative get_executable (Gtk.Window? parent) {
            var dialog = new Gtk.FileChooserNative(_("Select executable"),
                                                    parent,
                                                    Gtk.FileChooserAction.OPEN,
                                                    _("_Select"),
                                                    _("_Cancel")) {
                                                        modal = true,
                                                        select_multiple = false
                                                    };
            try {
                dialog.set_current_folder(File.new_for_path("/usr/bin"));
            } catch (Error e) {
                critical(e.message);
            }
            return dialog;
        }

        public Gtk.FileChooserNative get_target_directory (Gtk.Window? parent) {
            var dialog = new Gtk.FileChooserNative(_("Select Destination"),
                                                    parent,
                                                    Gtk.FileChooserAction.SELECT_FOLDER,
                                                    _("_Select"),
                                                    _("_Cancel")) {
                                                        modal = true,
                                                        select_multiple = false,
                                                        create_folders = true
                                                    };
            return dialog;
        }

        public Gtk.FileChooserNative get_selections (Gtk.Window? parent) {
            var filter = new Gtk.FileFilter();
            var file_roller = new ArchiveManager();
            if (file_roller.available)
                foreach (string mimetype in file_roller.get_supported_types())
                    filter.add_mime_type(mimetype);
            foreach (var mimetype in FONT_MIMETYPES)
                filter.add_mime_type(mimetype);
            var dialog = new Gtk.FileChooserNative(_("Select files to install"),
                                                    parent,
                                                    Gtk.FileChooserAction.OPEN,
                                                    _("_Open"),
                                                    _("_Cancel")) {
                                                        modal = true,
                                                        filter = filter,
                                                        select_multiple = true
                                                    };
            return dialog;
        }

        public Gtk.FileChooserNative get_selected_sources (Gtk.Window? parent) {
            var dialog = new Gtk.FileChooserNative(_("Select source folders"),
                                                    parent,
                                                    Gtk.FileChooserAction.SELECT_FOLDER,
                                                    _("_Open"),
                                                    _("_Cancel")) {
                                                        modal = true,
                                                        select_multiple = true
                                                    };
            return dialog;
        }

    }

    namespace ProgressDialog {

        public Gtk.MessageDialog create (Gtk.Window? parent, string? title) {
            var dialog = new Gtk.MessageDialog(parent,
                                               Gtk.DialogFlags.MODAL |
                                               Gtk.DialogFlags.DESTROY_WITH_PARENT |
                                               Gtk.DialogFlags.USE_HEADER_BAR,
                                               Gtk.MessageType.INFO,
                                               Gtk.ButtonsType.NONE,
                                               "%s", title != null ? title : "");
            var progress = new Gtk.ProgressBar();
            var box = dialog.get_message_area() as Gtk.Box;
            box.append(progress);
            dialog.set_default_size(475, 125);
            return dialog;
        }

        public void update (Gtk.MessageDialog dialog, ProgressData data) {
            var child = dialog.get_message_area().get_last_child();
            return_if_fail(child is Gtk.ProgressBar);
            var progress_bar = child as Gtk.ProgressBar;
            dialog.secondary_text = data.message;
            progress_bar.set_fraction(data.progress);
            return;
        }

    }

}
