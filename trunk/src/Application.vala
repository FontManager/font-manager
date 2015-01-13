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
        public Viewer? font_viewer { get; private set; default = null; }

        private const OptionEntry[] options = {
            { "about", 'a', 0, OptionArg.NONE, ref ABOUT, "About the application", null },
            { "version", 'v', 0, OptionArg.NONE, ref VERSION, "Show application version", null },
            { "debug", 'd', 0, OptionArg.NONE, ref DEBUG, "Enable debug logging", null },
            { null }
        };

        private static bool ABOUT = false;
        private static bool VERSION = false;
        private static bool DEBUG = false;

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
            if (font_viewer == null)
                font_viewer = new Viewer();
            font_viewer.font_data = FontData(files[0]);
            font_viewer.show();
            return;
        }

        public override int handle_local_options (VariantDict options) {
            int exit_status = -1;

            if (ABOUT)
                show_about();

            if (VERSION)
                show_version();

            if (DEBUG)
                Logger.DisplayLevel = LogLevel.VERBOSE;

            if (ABOUT || VERSION)
                exit_status = 0;

            return exit_status;
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
            Log.set_always_fatal(LogLevelFlags.LEVEL_CRITICAL);
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
