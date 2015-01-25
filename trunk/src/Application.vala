/* Application.vala
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

    [DBus (name = "org.gnome.FontManager")]
    public class Application: Gtk.Application  {

        [DBus (visible = false)]
        public MainWindow main_window { get; set; }
        [DBus (visible = false)]
        public Gtk.Builder builder { get; set; }
        [DBus (visible = false)]
        public Viewer? font_viewer {
            get {
                if (fontviewer == null)
                    fontviewer = new Viewer();
                return fontviewer;
            }
        }

        private const OptionEntry[] options = {
            { "about", 'a', 0, OptionArg.NONE, ref ABOUT, "About the application", null },
            { "version", 'v', 0, OptionArg.NONE, ref VERSION, "Show application version", null },
            { "debug", 'd', 0, OptionArg.NONE, ref DEBUG, "Useful for debugging. Verbose logging. Fatal errors.", null },
            { null }
        };

        private static bool ABOUT = false;
        private static bool VERSION = false;
        private static bool DEBUG = false;

        private uint fv_dbus_id = 0;
        private Viewer? fontviewer = null;

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

        public override int handle_local_options (VariantDict options) {
            int exit_status = -1;

            if (ABOUT)
                show_about();

            if (VERSION)
                show_version();

            if (DEBUG) {
                Logger.DisplayLevel = LogLevel.VERBOSE;
                Log.set_always_fatal(LogLevelFlags.LEVEL_CRITICAL);
            }

            if (ABOUT || VERSION)
                exit_status = 0;

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
                if (!conn.unregister_object(fv_dbus_id))
                    warning("Failed to unregister Font Viewer");
            base.dbus_unregister(conn, path);
        }

        protected override void activate () {
            builder = new Gtk.Builder();
        #if GTK_314
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
            var main = new Application(BUS_ID, (ApplicationFlags.HANDLES_OPEN));
            int res = main.run(args);
            return res;
        }

    }

}
