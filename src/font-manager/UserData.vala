/* UserData.vala
 *
 * Copyright (C) 2019 - 2020 Jerry Casiano
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

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-user-data.ui")]
    public class UserDataDialog : Gtk.Dialog {

        [GtkChild] public Gtk.CheckButton settings { get; }
        [GtkChild] public Gtk.CheckButton collections { get; }
        [GtkChild] public Gtk.CheckButton sources { get; }
        [GtkChild] public Gtk.CheckButton fonts { get; }
        [GtkChild] public Gtk.CheckButton actions { get; }

        public UserDataDialog (string action) {
            set_transient_for(main_window);
            if (main_window.use_csd) {
                var header = new Gtk.HeaderBar();
                header.set_title(_("User Data"));
                var cancel = new Gtk.Button.with_mnemonic(_("_Cancel"));
                var accept = new Gtk.Button.with_mnemonic(action);
                accept.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                cancel.clicked.connect(() => { response(Gtk.ResponseType.CANCEL); });
                accept.clicked.connect(() => { response(Gtk.ResponseType.ACCEPT); });
                header.pack_start(cancel);
                header.pack_end(accept);
                set_titlebar(header);
                header.show_all();
            } else {
                set_title(_("User Data"));
                add_buttons(_("_Cancel"), Gtk.ResponseType.CANCEL, action, Gtk.ResponseType.ACCEPT, null);
            }
        }
    }

    public void import_user_data () {
        var dialog = new Gtk.FileChooserNative(_("Select Exported Data"),
                                                main_window,
                                                Gtk.FileChooserAction.SELECT_FOLDER,
                                                _("_Select"),
                                                _("_Cancel"));
        dialog.set_select_multiple(false);
        File? directory = null;
        if (dialog.run() == Gtk.ResponseType.ACCEPT)
            directory = dialog.get_file();
        dialog.destroy();
        while(Gtk.events_pending())
            Gtk.main_iteration();
        if (directory == null)
            return;
        return_if_fail(directory.query_exists());
        FileCopyFlags flags = FileCopyFlags.OVERWRITE |
                              FileCopyFlags.ALL_METADATA |
                              FileCopyFlags.TARGET_DEFAULT_PERMS;
        try {
            FileInfo fileinfo;
            var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
            string root = directory.get_path();
            while ((fileinfo = enumerator.next_file()) != null) {
                var source_type = fileinfo.get_file_type();
                string name = fileinfo.get_name();
                if (source_type == GLib.FileType.DIRECTORY) {
                    if (name == "fontconfig") {
                        string confd = Path.build_filename(root, name, "conf.d");
                        File config_files = File.new_for_path(confd);
                        File config_dir = File.new_for_path(get_user_fontconfig_directory());
                        copy_directory(config_files, config_dir, flags);
                    } else if (name == "fonts") {
                        var filelist = new StringSet();
                        filelist.add(Path.build_filename(root, name));
                        main_window.install_fonts(filelist);
                    }
                } else if (source_type == GLib.FileType.REGULAR) {
                    string [] config_files = { "Collections.json", "Comparisons.json", "Sources.xml", "Actions.json" };
                    if (name in config_files) {
                        File config = File.new_for_path(Path.build_filename(root, name));
                        string config_dir = get_package_config_directory();
                        File target = File.new_for_path(Path.build_filename(config_dir, name));
                        config.copy(target, flags);

                    }
                }
            }
        } catch (Error e) {
            critical(e.message);
        }
        main_window.sidebar.collection_model.collections = Collections.load();
        main_window.compare.pinned.load();
        Signal.emit_by_name(main_window.compare.pinned, "closed");
        ((UserSourceList) main_window.preference_pane["Sources"]).model = new UserSourceModel();
        return;
    }

    internal void copy_config (string config_name, string destdir, FileCopyFlags flags) {
        string config_dir = get_package_config_directory();
        string filepath = Path.build_filename(config_dir, config_name);
        File config = File.new_for_path(filepath);
        if (config.query_exists()) {
            File target = File.new_for_path(Path.build_filename(destdir, config_name));
            try {
                config.copy(target, flags);
            } catch (Error e) {
                critical(e.message);
            }
        }
        return;
    }

    public void export_user_data () {
        FileCopyFlags flags = FileCopyFlags.OVERWRITE |
                              FileCopyFlags.ALL_METADATA |
                              FileCopyFlags.TARGET_DEFAULT_PERMS;
        var dialog = new UserDataDialog(_("Export"));
        if (dialog.run() == Gtk.ResponseType.ACCEPT) {
            dialog.hide();
            string temp_dir;
            try {
                temp_dir = DirUtils.make_tmp(TMP_TMPL);
                temp_files.add(temp_dir);
            } catch (Error e) {
                critical(e.message);
                return;
            }
            DateTime date = new DateTime.now_local();
            string dirname = "%s_%s".printf(Config.PACKAGE_NAME, date.format("%F"));
            string dest = Path.build_filename(temp_dir, dirname);
            File destination = File.new_for_path(dest);
            try {
                destination.make_directory_with_parents();
            } catch (Error e) {
                critical(e.message);
            }
            if (dialog.settings.active) {
                var settings_dir = get_user_fontconfig_directory();
                var dest_dir = Path.build_filename(destination.get_path(), "fontconfig", "conf.d");
                copy_directory(File.new_for_path(settings_dir), File.new_for_path(dest_dir), flags);
            }
            if (dialog.sources.active)
                copy_config("Sources.xml", destination.get_path(), flags);
            if (dialog.collections.active) {
                copy_config("Collections.json", destination.get_path(), flags);
                copy_config("Comparisons.json", destination.get_path(), flags);
            }
            if (dialog.actions.active)
                copy_config("Actions.json", destination.get_path(), flags);
            if (dialog.fonts.active) {
                var font_dir = get_user_font_directory();
                var dest_dir = Path.build_filename(destination.get_path(), "fonts");
                copy_directory(File.new_for_path(font_dir), File.new_for_path(dest_dir), flags);
            }
            /* Ensure our initial dialog is hidden before putting up another one */
            while (Gtk.events_pending())
                Gtk.main_iteration();
            string target_dir = FileSelector.get_target_directory();
            string _target = Path.build_filename(target_dir, dirname);
            File target = File.new_for_path(_target);
            copy_directory(destination, target, flags);
        }
        dialog.destroy();
        return;
    }

}
