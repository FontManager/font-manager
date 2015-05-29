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

        const OptionEntry[] options = {
            { "about", 'a', 0, OptionArg.NONE, ref ABOUT, "About the application", null },
            { "version", 'V', 0, OptionArg.NONE, ref VERSION, "Show application version", null },
            { "debug", 'd', 0, OptionArg.NONE, ref DEBUG, "Enable debug logging", null },
            { "verbose", 'v', 0, OptionArg.NONE, ref VERBOSE, "Enable verbose logging", null },
            { null }
        };

        static bool ABOUT = false;
        static bool VERSION = false;
        static bool DEBUG = false;
        static bool VERBOSE = false;

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
        }

        public override void startup () {
            base.startup ();
            Logging.show_version_information();
            builder = new Gtk.Builder();
            if (Gnome3())
                set_gnome_app_menu(this, builder);
            return;
        }

        public override void open (File [] files, string hint) {
            return;
        }

        public override bool local_command_line (ref unowned string[] args, out int exit_status) {
            bool result = false;
            exit_status = 0;

            var context = new OptionContext(null);
            context.add_main_entries(options, NAME);
            context.add_group(Gtk.get_option_group(false));

            try {
                unowned string [] _args = args;
                context.parse(ref _args);
            } catch (OptionError e) {
                printerr("%s\n", e.message);
                exit_status = 1;
                result = true;
            }

            if (ABOUT) {
                show_about();
                result = true;
            }

            if (VERSION) {
                show_version();
                result = true;
            }

            if (VERBOSE)
                Logger.DisplayLevel = LogLevel.VERBOSE;
            else if (DEBUG)
                Logger.DisplayLevel = LogLevel.DEBUG;

            return (result ? result : base.local_command_line(ref args, out exit_status));
        }

        protected override void activate () {
            Main.instance.on_activate();
            return;
        }

        public void on_quit () {
            Main.instance.settings.apply();
            main_window.hide();
            remove_window(main_window);
            quit();
        }

        public void on_about () {
            show_about_dialog(main_window);
            return;
        }

        public void on_help () {
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
