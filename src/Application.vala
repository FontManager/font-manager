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

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
            startup.connect(() => {
                builder = new Gtk.Builder();
                if (Gnome3()) {
                    set_gnome_app_menu();
                    string? version = get_command_line_output("gnome-shell --version");
                    if (version != null)
                        message("Running on %s", version);
                } else {
                    string? de = Environment.get_variable("XDG_CURRENT_DESKTOP");
                    if (de != null)
                        message("Running on %s", de);
                }
            });
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
            try {
                Gtk.show_uri(null, "help:%s".printf(NAME), Gdk.CURRENT_TIME);
            } catch (Error e) {
                error("Error launching uri handler : %s", e.message);
            }
            return;
        }

        public static int main (string [] args) {
            //Log.set_always_fatal(LogLevelFlags.LEVEL_CRITICAL);
            Environment.set_application_name(About.NAME);
            /* XXX : Workaround : XDG : FontConfig ignores EnableHome
             * Fixed in master : dab60e4476ada4ad4639599ea24dd012d4a79584
             * Need FontConfig > 2.11.1
             */
            Environment.set_variable("XDG_CONFIG_HOME", "", true);
            FontConfig.enable_user_config(false);
            Logging.setup();
            Intl.setup(NAME);
            Gtk.init(ref args);
            set_application_style();
            if (update_declined())
                return 0;
            var main = new Application(BUS_ID, (ApplicationFlags.FLAGS_NONE));
            int res = main.run(args);
            return res;
        }

        internal void set_gnome_app_menu () {
            try {
                builder.add_from_resource("/org/gnome/FontManager/ApplicationMenu.ui");
                app_menu = builder.get_object("ApplicationMenu") as GLib.MenuModel;
            } catch (Error e) {
                warning("Failed to set application menu : %s", e.message);
            }
            return;
        }

    }

}
