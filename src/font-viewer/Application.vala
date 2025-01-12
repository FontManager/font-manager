/* Application.vala
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

    namespace FontViewer {

        [DBus (name = "com.github.FontManager.FontViewer")]
        public class Application : Gtk.Application {

            [DBus (visible = false)]
            public MainWindow? main_window { get; private set; default = null; }
            [DBus (visible = false)]
            public GLib.Settings? settings { get; private set; default = null; }

            uint dbus_id = 0;

            const OptionEntry[] options = {
                { "version", 'v', 0, OptionArg.NONE, null, "Show application version", null },
                { "debug", 0, 0, OptionArg.NONE, null, "Enable debug messages", null },
                { "", 0, 0, OptionArg.FILENAME_ARRAY, null, null, null },
                { null }
            };

            public Application (string app_id, ApplicationFlags app_flags) {
                Object(application_id : app_id, flags : app_flags);
                add_main_option_entries(options);
            }

            public bool ready ()
            throws DBusError, IOError {
                return main_window != null && main_window.is_visible();
            }

            public void show_uri (string uri, int index)
            throws DBusError, IOError {
                if (main_window == null || !main_window.is_visible())
                    activate();
                main_window.show_uri(uri, index);
                return;
            }

            public override void open (File [] files, string hint) {
                if (main_window == null || !main_window.is_visible())
                    activate();
                int index = hint != "" ? int.parse(hint) : 0;
                main_window.open(files[0], index);
                return;
            }

            protected override void activate () {
                register_session = true;
                if (main_window == null) {
                    settings = get_gsettings(BUS_ID);
                    main_window = new MainWindow(settings);
                    add_window(main_window);
                    main_window.restore_state();
                    // Why is this needed?
                    shutdown.connect(() => { quit(); });
                }
                main_window.present();
                main_window.update();
                return;
            }

            public override int command_line (ApplicationCommandLine cl) {
                hold();
                VariantDict options = cl.get_options_dict();
                if (options.contains("debug")) {
                    Environment.set_variable("G_MESSAGES_DEBUG", "[font-manager]", true);
                    stdout.printf("\n%s %s\n\n", _("Font Viewer"), Config.PACKAGE_VERSION);
                    print_os_info();
                    print_library_versions();
                }
                StringSet? filelist = get_command_line_files(cl);
                if (filelist != null) {
                    File [] files = { File.new_for_path(filelist[0]) };
                    open(files, "0");
                } else {
                    activate();
                }
                release();
                return 0;
            }

            public override int handle_local_options (VariantDict options) {

                int exit_status = -1;

                if (options.contains("version")) {
                    stdout.printf("%s %s\n", _("Font Viewer"), Config.PACKAGE_VERSION);
                    return 0;
                }

                return exit_status;
            }

            public override bool dbus_register (DBusConnection conn, string path)
            throws Error {
                base.dbus_register(conn, path);
                dbus_id = conn.register_object(BUS_PATH, this);
                if (dbus_id == 0)
                    critical("Could not register Font Viewer service ");
                return true;
            }

            public override void dbus_unregister (DBusConnection conn, string path) {
                if (dbus_id != 0)
                    conn.unregister_object(dbus_id);
                base.dbus_unregister(conn, path);
            }

            public static int main (string [] args) {
                setup_i18n();
                Environment.set_application_name(_("Font Viewer"));
#if HAVE_ADWAITA
                var settings = get_gsettings(FontManager.BUS_ID);
                if (settings != null)
                    if (settings.get_boolean("use-adwaita-stylesheet"))
                        Adw.init();
#endif
                ApplicationFlags FLAGS = (ApplicationFlags.HANDLES_COMMAND_LINE |
                                          ApplicationFlags.HANDLES_OPEN);
                return new Application(FontViewer.BUS_ID, FLAGS).run(args);
            }

        }

    }

}

