/* Dialogs.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public void set_default_dialog_size (Gtk.Window parent,
                                         Gtk.Window dialog,
                                         int w_percentage,
                                         int h_percentage) {
        int width = (int) ((parent.get_width() / 10) * (w_percentage / 10));
        int height = (int) ((parent.get_height() / 10) * (h_percentage / 10));
        dialog.set_default_size(width, height);
        return;
    }

    namespace FileSelector {

        public Gtk.FileDialog get_executable () {
            var dialog = new Gtk.FileDialog() {
                modal = true,
                accept_label = _("_Select"),
                title = _("Select Executable"),
            };
            File bindir = File.new_for_path(BINDIR);
            dialog.set_initial_folder(bindir);
            return dialog;
        }

        public Gtk.FileDialog get_target_directory () {
            var dialog = new Gtk.FileDialog() {
                modal = true,
                accept_label = _("_Select"),
                title = _("Select a Directory"),
            };
            return dialog;
        }

        public Gtk.FileDialog get_selections () {
            var filter = new Gtk.FileFilter();
            var file_roller = new ArchiveManager();
            if (file_roller.available)
                foreach (string mimetype in file_roller.get_supported_types())
                    filter.add_mime_type(mimetype);
            foreach (var mimetype in FONT_MIMETYPES)
                filter.add_mime_type(mimetype);
            var dialog = new Gtk.FileDialog() {
                modal = true,
                title = _("Select Files to Install"),
            };
            dialog.set_default_filter(filter);
            return dialog;
        }

        public Gtk.FileDialog get_selected_sources () {
            var dialog = new Gtk.FileDialog() {
                modal = true,
                title = _("Select Source Directories"),
            };
            return dialog;
        }

    }

    namespace UserData {

        void copy_config (string config_name, string destdir, FileCopyFlags flags) {
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

        public class ExportSettings : PreferenceList {

            public Gtk.Switch settings { get; private set; }
            public Gtk.Switch collections { get; private set; }
            public Gtk.Switch sources { get; private set; }
            public Gtk.Switch fonts { get; private set; }
            public Gtk.Switch actions { get; private set; }

            public ExportSettings () {
                controls.set_visible(false);
                settings = add_preference_switch(_("Font Configuration"));
                collections = add_preference_switch(_("Font Collections"));
                sources = add_preference_switch(_("Font Sources"));
                fonts = add_preference_switch(_("Installed Fonts"));
                actions = add_preference_switch(_("Custom Actions"));
                Gtk.Switch [] switches = { settings, collections, sources, fonts, actions };
                foreach (var widget in switches)
                    widget.set_active(true);
            }

        }

        [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-export-dialog.ui")]
        public class ExportDialog : Gtk.Window {

            public ExportSettings export_settings { get; private set; }

            public ExportDialog (Gtk.Window? parent) {
                set_transient_for(parent);
                set_default_dialog_size(parent, this, 50, 70);
                export_settings = new ExportSettings();
                set_child(export_settings);
            }

            [GtkCallback]
            void on_cancel_clicked () {
                destroy();
                return;
            }

            [GtkCallback]
            void on_export_clicked () {
                hide();
                var dialog = FileSelector.get_target_directory();
                dialog.select_folder.begin(get_transient_for(), null, on_directory_selected);
                return;
            }

            void export_to (File target_directory) {
                FileCopyFlags flags = FileCopyFlags.OVERWRITE |
                                      FileCopyFlags.ALL_METADATA |
                                      FileCopyFlags.TARGET_DEFAULT_PERMS;
                DateTime date = new DateTime.now_local();
                string dirname = "%s_%s".printf(Config.PACKAGE_NAME, date.format("%F"));
                string dest = Path.build_filename(target_directory.get_path(), dirname);
                File destination = File.new_for_path(dest);
                try {
                    destination.make_directory_with_parents();
                } catch (Error e) {
                    critical(e.message);
                }
                if (export_settings.actions.active)
                    copy_config("Actions.json", destination.get_path(), flags);
                if (export_settings.sources.active)
                    copy_config("Sources.xml", destination.get_path(), flags);
                if (export_settings.collections.active) {
                    copy_config("Collections.json", destination.get_path(), flags);
                    copy_config("Comparisons.json", destination.get_path(), flags);
                }
                if (export_settings.settings.active) {
                    var settings_dir = get_user_fontconfig_directory();
                    var dest_dir = Path.build_filename(destination.get_path(), "fontconfig", "conf.d");
                    copy_directory(File.new_for_path(settings_dir), File.new_for_path(dest_dir), flags);
                }
                if (export_settings.fonts.active) {
                    var font_dir = get_user_font_directory();
                    var dest_dir = Path.build_filename(destination.get_path(), "fonts");
                    copy_directory(File.new_for_path(font_dir), File.new_for_path(dest_dir), flags);
                }
                return;
            }

            void on_directory_selected (Object? object, AsyncResult result) {
                try {
                    var dialog = (Gtk.FileDialog) object;
                    File? target_directory = dialog.select_folder.end(result);
                    export_to(target_directory);
                } catch (Error e) {
                    if (e.code == Gtk.DialogError.FAILED)
                        warning("FileDialog : %s", e.message);
                }
                return;
            }

        }

        public class ImportDialog : Object {

            Gtk.Window? parent;
            Gtk.FileDialog file_dialog;

            public ImportDialog (Gtk.Window? parent) {
                file_dialog = FileSelector.get_target_directory();
                this.parent = parent;
            }

            public void present () {
                file_dialog.select_folder.begin(parent, null, on_directory_selected);
                return;
            }

            void import_from (File target_directory) {
                FileCopyFlags flags = FileCopyFlags.OVERWRITE |
                                      FileCopyFlags.ALL_METADATA |
                                      FileCopyFlags.TARGET_DEFAULT_PERMS;
                try {
                    FileInfo fileinfo;
                    StringSet? filelist = null;
                    var enumerator = target_directory.enumerate_children(FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);
                    string root = target_directory.get_path();
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
                                filelist = new StringSet();
                                filelist.add(Path.build_filename(root, name));
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
                    if (filelist != null) {
                        var installer = new Library.Installer();
                        installer.process.begin(filelist, (obj, res) => {
                            installer.process.end(res);
                            get_default_application().reload();
                        });
                    } else {
                        Timeout.add_seconds(4, () => {
                            get_default_application().reload();
                            return GLib.Source.REMOVE;
                        });
                    }
                } catch (Error e) {
                    critical(e.message);
                }
                return;
            }

            void on_directory_selected (Object? object, AsyncResult result) {
                try {
                    var dialog = (Gtk.FileDialog) object;
                    File? target_directory = dialog.select_folder.end(result);
                    import_from(target_directory);
                } catch (Error e) {
                    if (e.code == Gtk.DialogError.FAILED)
                        warning("FileDialog : %s", e.message);
                }
                return;
            }

        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-language-settings-dialog.ui")]
    public class LanguageSettingsDialog : Gtk.Window {

        public LanguageFilterSettings? settings { get; set; default = null; }

        [GtkChild] unowned Gtk.ToggleButton search_toggle;

        public LanguageSettingsDialog (Gtk.Window? parent, LanguageFilterSettings settings) {
            Object(settings: settings);
            set_transient_for(parent);
            set_child(settings);
            if (parent != null)
                set_default_dialog_size(parent, this, 60, 80);
            BindingFlags flags = BindingFlags.BIDIRECTIONAL;
            search_toggle.bind_property("active", settings.search_bar, "search-mode-enabled", flags);
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-progress-dialog.ui")]
    public class ProgressDialog : Gtk.Window {

        public bool show_app_icon {
            get {
                return app_icon.visible;
            }
            set {
                app_icon.set_visible(value);
            }
        }

        [GtkChild] public unowned Gtk.Label title_label { get; }
        [GtkChild] public unowned Gtk.Label message_label { get; }
        [GtkChild] public unowned Gtk.Overlay overlay { get; }
        [GtkChild] public unowned Gtk.ProgressBar progress_bar { get; }

        [GtkChild] unowned Gtk.Image app_icon;

        public ProgressDialog (Gtk.Window? parent, string? title) {
            set_transient_for(parent);
            widget_set_name(this, "FontManagerProgressDialog");
            widget_set_expand(progress_bar, true);
            add_css_class("dialog");
            title_label.set_label(title != null ? title : "");
            if (parent != null)
                set_default_dialog_size(parent, this, 50, 20);
        }

        public void update (ProgressData data) {
            message_label.set_label(data.message);
            progress_bar.set_fraction(data.progress);
            return;
        }

    }

    [GtkTemplate (ui = "/com/github/FontManager/FontManager/ui/font-manager-remove-dialog.ui")]
    public class RemoveDialog : Gtk.Window {

        public signal void start_removal ();
        public signal void end_removal ();

        [GtkChild] public unowned Gtk.Button cancel_button { get; }
        [GtkChild] public unowned Gtk.Button delete_button { get; }
        [GtkChild] public unowned RemoveListView remove_list { get; }

        public RemoveDialog (Gtk.Window? parent) {
            set_transient_for(parent);
            set_default_dialog_size(parent, this, 70, 70);
            var fonts = get_available_fonts(null);
            var sorted_fonts = sort_json_font_listing(fonts);
            sorted_fonts.foreach_element((a, i, n) => {
                Json.Object family = n.get_object();
                family.set_boolean_member("active", false);
                Json.Array variations = family.get_array_member("variations");
                variations.foreach_element((a, i, n) => {
                    n.get_object().set_boolean_member("active", false);
                });
            });
            update_item_preview_text(sorted_fonts);
            remove_list.available_fonts = sorted_fonts;
            delete_button.set_sensitive(false);
            remove_list.changed.connect(() => {
                bool sensitive = remove_list.selected_files.size > 0;
                delete_button.set_sensitive(sensitive);
                if (sensitive) {
                    cancel_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
                    delete_button.add_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
                } else {
                    cancel_button.remove_css_class(STYLE_CLASS_SUGGESTED_ACTION);
                    delete_button.remove_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
                }
            });
        }

        [GtkCallback]
        void on_cancel_clicked () {
            destroy();
            return;
        }

        [GtkCallback]
        void on_delete_clicked () {
            hide();
            start_removal();
            Library.remove.begin(remove_list.selected_files,(obj, res) => {
                Library.remove.end(res);
                end_removal();
                destroy();
            });
            return;
        }

    }

}

