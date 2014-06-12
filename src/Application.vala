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

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
        }

        protected override void activate () {
            Main.instance.on_activate(this);
            return;
        }

        public void on_quit () {
            main_window.hide();
            remove_window(main_window);
            quit();
        }

        public void on_about () {
            show_about_dialog(main_window);
            return;
        }

        public void on_help () {
            Gtk.show_uri(null, "help:%s".printf(NAME), Gdk.CURRENT_TIME);
            return;
        }

        public static int main (string [] args) {
            //Log.set_always_fatal(LogLevelFlags.LEVEL_CRITICAL);
            Environment.set_application_name(About.NAME);
            Intl.setup(NAME);
            FontConfig.enable_user_config(false);
            Gtk.init(ref args);
            set_application_style();
            if (update_declined())
                return 0;
            var main = new Application(BUS_ID, (ApplicationFlags.FLAGS_NONE));
            int res = main.run(args);
            return res;
        }

    }

}
