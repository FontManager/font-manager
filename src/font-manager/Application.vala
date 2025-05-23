/* Application.vala */
public const string DISPLAY_NAME = _("Font Manager");
public const string COMMENT = _("Simple font management for GTK+ desktop environments");
public const string COPYRIGHT = "Copyright © 2009-2025 Jerry Casiano";
public const string LICENSE = _("""
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.

    If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
""");

namespace FontManager {

    FontManager.Application get_default_application () {
        return ((FontManager.Application) GLib.Application.get_default());
    }

    [DBus (name = "com.github.FontManager.FontManager")]
    public class Application: Gtk.Application  {

        [DBus (visible = false)]
        public bool update_in_progress { get; private set; default = false; }
        [DBus (visible = false)]
        public GLib.Settings? settings { get; private set; default = null; }
        [DBus (visible = false)]
        public Json.Array? available_fonts { get; set; default = null; }
        [DBus (visible = false)]
        public MainWindow? main_window { get; private set; default = null; }
        [DBus (visible = false)]
        public DatabaseProxy? db { get; private set; default = new DatabaseProxy(); }
        [DBus (visible = false)]
        public Reject? disabled_families { get; private set; default = new Reject(); }

        const OptionEntry[] options = {
            { "about", 'a', 0, OptionArg.NONE, null, "About the application", null },
            { "version", 'v', 0, OptionArg.NONE, null, "Show application version", null },
            { "debug", 0, 0, OptionArg.NONE, null, "Enable debug messages", null },
            { "install", 'i', 0, OptionArg.NONE, null, "Space separated list of files to install.", null },
            { "enable", 'e', 0, OptionArg.NONE, null, "Space separated list of font families to enable. Empty list to enable all.", null },
            { "disable", 'd', 0, OptionArg.NONE, null, "Space separated list of font families to disable", null },
            { "keep", 0, 0, OptionArg.NONE, null, "Space separated list of font families to keep enabled, disables all others.", null },
            { "list", 'l', 0, OptionArg.NONE, null, "List available font families.", null },
            { "list-full", 0, 0, OptionArg.NONE, null, "Full listing including face information. (JSON)", null },
            { "update", 'u', 0, OptionArg.NONE, null, "Update application database", null },
            { "", 0, 0, OptionArg.FILENAME_ARRAY, null, null, null },
            { null }
        };

        uint dbus_id = 0;
        SearchProvider? gs_search_provider = null;

        ~ Application () {
            free_gsettings();
        }

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
            add_main_option_entries(options);
        }

        public override void startup () {
            base.startup();
            disabled_families.load();
            settings = get_gsettings(application_id);
            if (settings != null) {
                Gtk.Settings gtk = Gtk.Settings.get_default();
                bool prefer_dark_theme = settings.get_boolean("prefer-dark-theme");
#if HAVE_ADWAITA
                if (settings.get_boolean("use-adwaita-stylesheet")) {
                    Adw.StyleManager style_manager = Adw.StyleManager.get_default();
                    Adw.ColorScheme color_scheme = prefer_dark_theme ?
                                                   Adw.ColorScheme.PREFER_DARK :
                                                   Adw.ColorScheme.PREFER_LIGHT;
                    style_manager.set_color_scheme(color_scheme);
                } else
                    gtk.gtk_application_prefer_dark_theme = prefer_dark_theme;
#else
                gtk.gtk_application_prefer_dark_theme = prefer_dark_theme;
#endif
                gtk.gtk_enable_animations = settings.get_boolean("enable-animations");
            }
            notify["update-in-progress"].connect(progress_visible);
            db.update_started.connect(() => { update_in_progress = true; });
            db.update_complete.connect(() => { update_in_progress = false; });
            return;
        }

        public override void open (File [] files, string hint) {
            int index = hint != "" ? int.parse(hint) : 0;
            try {
                DBusConnection conn = Bus.get_sync(BusType.SESSION);
                conn.call_sync(FontViewer.BUS_ID,
                                FontViewer.BUS_PATH,
                                FontViewer.BUS_ID,
                                "ShowUri",
                                new Variant("(si)", files[0].get_uri(), index),
                                null,
                                DBusCallFlags.NONE,
                                -1,
                                null);
            } catch (Error e) {
                critical("Method call to %s failed : %s", FontViewer.BUS_ID, e.message);
            }
            return;
        }

        public override int command_line (ApplicationCommandLine cl) {
            hold();

            VariantDict options = cl.get_options_dict();
            StringSet? filelist = get_command_line_files(cl);

            if (options.contains("install") || options.contains("update")) {
                if (options.contains("install") && filelist != null) {
                    if (main_window != null) {
                        main_window.install_selections(filelist);
                    } else {
                        var installer = new Library.Installer();
                        installer.progress.connect((m, p, t) => {
                            var data = new ProgressData(m, p, t);
                            data.print();
                        });
                        GLib.stdout.printf("%s\n", _("Installing Font Files…"));
                        installer.process_sync(filelist);
                        stdout.printf("\n");
                    }
                }
                if (main_window != null) {
                    reload();
                } else {
                    update_font_configuration();
                    available_fonts = get_sorted_font_list(null);
                    db.update_started.connect(() => { hold(); });
                    db.update_complete.connect(() => { GLib.stdout.printf("\n"); release(); });
                    db.set_progress_callback(ProgressData.print);
                    GLib.stdout.printf("%s\n", _("Updating Database…"));
                    db.update(available_fonts);
                }
            } else if (filelist != null) {
                File [] files = { File.new_for_path(filelist[0]) };
                open(files, "0");
            } else {
                activate();
            }

            release();
            return 0;
        }

        public string list () throws GLib.DBusError, GLib.IOError {
            update_font_configuration();
            load_user_font_resources();
            var families = list_available_font_families();
            StringBuilder builder = new StringBuilder();
            foreach (string family in families)
                builder.append(@"$family\n");
            return builder.str;
        }

        public string list_full () throws GLib.DBusError, GLib.IOError {
            Json.Array sorted_fonts = get_sorted_font_list(null);
            return print_json_array(sorted_fonts, true);
        }

        public void enable (string [] families) throws GLib.DBusError, GLib.IOError {
            disabled_families.load();
            foreach (var family in families)
                if (family in disabled_families)
                    disabled_families.remove(family);
            disabled_families.save();
            return;
        }

        public void disable (string [] families) throws GLib.DBusError, GLib.IOError {
            foreach (var family in families)
                disabled_families.add(family);
            disabled_families.save();
            return;
        }

        public void install (string [] filepaths) throws GLib.DBusError, GLib.IOError {
            StringSet filelist = new StringSet();
            foreach (var path in filepaths)
                filelist.add(path);
            var installer = new Library.Installer();
            installer.process_sync(filelist);
            return;
        }

        public void search (string needle) throws GLib.DBusError, GLib.IOError {
            if (main_window == null || !main_window.is_visible())
                activate();
            main_window.search(needle);
            return;
        }

        public override int handle_local_options (VariantDict options) {

            int exit_status = -1;

            if (options.contains("version")) {
                stdout.printf("%s %s\n", Config.PACKAGE_NAME, Config.PACKAGE_VERSION);
                return 0;
            }

            if (options.contains("about")) {
                stdout.printf("\n    %s - %s\n\n\t\t  %s\n%s\n", Config.PACKAGE_NAME, COMMENT, COPYRIGHT, LICENSE);
                return 0;
            }

            if (options.contains("enable")) {
                var accept = get_command_line_input(options);
                if (accept == null || accept.size < 1) {
                    disabled_families.clear();
                    disabled_families.save();
                    exit_status = 0;
                } else {
                    try {
                        enable(accept.to_strv());
                        exit_status = 0;
                    } catch (Error e) {
                        critical(e.message);
                        exit_status = 1;
                    }
                }
            }

            if (options.contains("disable")) {
                var rejects = get_command_line_input(options);
                if (rejects == null || rejects.size < 1) {
                    stdout.printf("\nGot empty list. Exiting...\n\n");
                    exit_status = 1;
                } else {
                    try {
                        disable(rejects.to_strv());
                        exit_status = 0;
                    } catch (Error e) {
                        critical(e.message);
                        exit_status = 1;
                    }
                }
                exit_status = 0;
            }

            if (options.contains("keep")) {
                var keep = get_command_line_input(options);
                if (keep == null || keep.size < 1) {
                    stdout.printf("\nGot empty list. Disabling all installed fonts is not a good idea...\n\n");
                    exit_status = 1;
                } else {
                    update_font_configuration();
                    load_user_font_resources();
                    var families = list_available_font_families();
                    var matches = new StringSet();
                    foreach (string family in keep)
                        foreach (string entry in families) {
                            string a = entry.down();
                            string b = family.down();
                            if (a == b || a.contains(b))
                                matches.add(entry);
                        }
                    if (matches.size < 1) {
                        stdout.printf("\nNo valid families specified. Disabling all installed fonts is not a good idea...\n\n");
                        exit_status = 1;
                    } else {
                        families.remove_all(matches);
                        try {
                            disable(families.to_strv());
                            exit_status = 0;
                        } catch (Error e) {
                            critical(e.message);
                            exit_status = 1;
                        }
                    }
                }
                exit_status = 0;
            }

            if (options.contains("list")) {
                try {
                    stdout.printf(list());
                } catch (Error e) {
                    critical(e.message);
                    return e.code;
                }
                exit_status = 0;
            }

            if (options.contains("list-full")) {
                try {
                    stdout.printf("\n%s\n\n", list_full());
                } catch (Error e) {
                    critical(e.message);
                    return e.code;
                }
                exit_status = 0;
            }

            return exit_status;
        }

        void progress_visible () {
            if (main_window != null)
                main_window.progress.set_visible(update_in_progress);
            return;
        }

        [DBus (visible = false)]
        public void reload ()
        requires (main_window != null) {
            if (update_in_progress)
                return;
            var ctx = main_window.get_pango_context();
            available_fonts = get_sorted_font_list(ctx);
            main_window.present();
            db.update(available_fonts);
            return;
        }

        protected override void activate () {
            if (main_window == null) {
                main_window = new MainWindow(settings);
                main_window.present();
                add_window(main_window);
                BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
                bind_property("available-fonts", main_window, "available-fonts", flags);
                bind_property("disabled-families", main_window, "disabled-families", flags);
            }
            db.update_complete.connect(() => {
                update_item_preview_text(available_fonts);
                if (main_window.mode == Mode.BROWSE)
                    main_window.browse_pane.queue_update();
                Idle.add(() => {
                    main_window.category_model.update_items();
                    if (main_window.mode != Mode.BROWSE)
                        main_window.select_first_font();
                    return GLib.Source.REMOVE;
                });
            });
            db.set_progress_callback((data) => {
                return get_default_application().main_window.progress_update(data);
            });
            reload();
            return;
        }

        public override bool dbus_register (DBusConnection conn, string path) throws Error {
            bool result = base.dbus_register(conn, path);
            dbus_id = conn.register_object (BUS_PATH, this);
            if (dbus_id == 0)
                critical("Could not register Font Manager service ");
            if (gs_search_provider == null)
                gs_search_provider = new SearchProvider();
            gs_search_provider.dbus_register(conn);
            return result;
        }

        public override void dbus_unregister (DBusConnection conn, string path) {
            if (dbus_id != 0)
                conn.unregister_object(dbus_id);
            gs_search_provider.dbus_unregister(conn);
            base.dbus_unregister(conn, path);
            return;
        }

        static void set_debug_level (string [] args) {
            foreach (var arg in args) {
                if (!arg.contains("debug"))
                    continue;
                Environment.set_variable("G_MESSAGES_DEBUG", "[font-manager]", true);
                stdout.printf("\n%s %s\n\n", DISPLAY_NAME, Config.PACKAGE_VERSION);
                print_os_info();
                print_library_versions();
                break;
            }
            return;
        }

        public static int main (string [] args) {
            setup_i18n();
            set_debug_level(args);
            Environment.set_application_name(DISPLAY_NAME);
#if HAVE_ADWAITA
            var settings = get_gsettings(BUS_ID);
            if (settings != null)
                if (settings.get_boolean("use-adwaita-stylesheet"))
                    Adw.init();
#endif
            ApplicationFlags FLAGS = (ApplicationFlags.HANDLES_OPEN |
                                      ApplicationFlags.HANDLES_COMMAND_LINE);
            return new Application(BUS_ID, FLAGS).run(args);
        }

    }

}

