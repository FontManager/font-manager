/* Application.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    [DBus (name = "org.gnome.FontManager")]
    public class Application: Gtk.Application  {

        [DBus (visible = false)]
        public MainWindow? main_window { get; set; default = null; }
        [DBus (visible = false)]
        public Gtk.Builder? builder { get; set; default = null; }
        [DBus (visible = false)]
        public Viewer? font_viewer {
            get {
                if (fv == null)
                    fv = new Viewer();
                return fv;
            }
        }

        private const OptionEntry[] options = {
            { "about", 'a', 0, OptionArg.NONE, null, "About the application", null },
            { "version", 'v', 0, OptionArg.NONE, null, "Show application version", null },
            { "install", 'i', 0, OptionArg.NONE, null, "Space separated list of files to install.", null },
            { "debug", 'd', 0, OptionArg.NONE, null, "Enable logging. Fatal errors.", null },
            { "verbose", 'V', 0, OptionArg.NONE, null, "Verbose logging. Lots of output.", null },
            { "", 0, 0, OptionArg.FILENAME_ARRAY, null, null, null },
            { null }
        };

        private uint fv_dbus_id = 0;
        private Viewer? fv = null;

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
            add_main_option_entries(options);
        }

        public override void startup () {
            base.startup();
            Logging.show_version_information();
            return;
        }

        public override void open (File [] files, string hint) {
            font_viewer.fontdata = FontData(files[0]);
            font_viewer.show();
            return;
        }

        [DBus (visible = false)]
        public void install (File [] files) {
            Library.Install.from_file_array(files);
            return;
        }

        private File []? get_command_line_files (ApplicationCommandLine cl) {
            VariantDict options = cl.get_options_dict();
            Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
            if (argv == null)
                return null;
            string* [] filelist = argv.get_bytestring_array();
            if (filelist.length == 0)
                return null;
            File [] files = null;
            foreach (var file in filelist)
                files += cl.create_file_for_arg(file);
            return files;
        }

        public override int command_line (ApplicationCommandLine cl) {
            hold();
            VariantDict options = cl.get_options_dict();
            File []? filelist = get_command_line_files(cl);
            if (filelist == null) {
                release();
                activate();
                return 0;
            } else if (options.contains("install")) {
                install(filelist);
            } else {
                try {
                    register();
                } catch (Error e) {
                    critical(e.message);
                }
                open(filelist, "");
            }
            release();
            return 0;
        }


        public override int handle_local_options (VariantDict options) {
            int exit_status = -1;

            if (options.contains("about")) {
                show_about();
                exit_status = 0;
            }

            if (options.contains("version")) {
                show_version();
                exit_status = 0;
            }

            if (options.contains("debug")) {
                Logger.DisplayLevel = LogLevel.DEBUG;
                Log.set_always_fatal(LogLevelFlags.LEVEL_CRITICAL);
            }

            if (options.contains("verbose"))
                Logger.DisplayLevel = LogLevel.VERBOSE;

            return exit_status;
        }

        public override bool dbus_register (DBusConnection conn, string path) throws Error {
            base.dbus_register(conn, path);
            fv_dbus_id = conn.register_object ("/org/gnome/FontManager/FontViewer", font_viewer);
            if (fv_dbus_id == 0)
                critical("Could not register Font Viewer service ");
            return true;
        }

        public override void dbus_unregister (DBusConnection conn, string path) {
            if (fv_dbus_id != 0)
                conn.unregister_object(fv_dbus_id);
            base.dbus_unregister(conn, path);
        }

        protected override void activate () {
            builder = new Gtk.Builder();
        #if GTK_314_OR_LATER
            if (prefers_app_menu())
        #else
            if (Gnome3())
        #endif
                set_g_app_menu(this, builder);
            Main.instance.on_activate();
            return;
        }

        public new void quit () {
            Main.instance.settings.apply();
            main_window.hide();
            remove_window(main_window);
            base.quit();
        }

        public void about () {
            show_about_dialog(main_window);
            return;
        }

        public void help () {
            show_help_dialog();
            return;
        }

        public static int main (string [] args) {
            Environment.set_application_name(About.NAME);
            Environment.set_variable("XDG_CONFIG_HOME", "", true);
            FontConfig.enable_user_config(false);
            Logging.setup();
            Intl.setup();
            Gtk.init(ref args);
            set_application_style();
            if (update_declined())
                return 0;
            var main = new Application(BUS_ID, (ApplicationFlags.HANDLES_OPEN | ApplicationFlags.HANDLES_COMMAND_LINE));
            int res = main.run(args);
            return res;
        }

    }

}
