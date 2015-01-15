/* Main.vala
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

void queue_reload () {
    /* Note : There's a 2 second delay built into FontConfig */
    Timeout.add_seconds(3, () => {
        FontManager.Main.instance.update();
        return false;
    });
    return;
}

namespace FontManager {

    public class Main : Object {

        public static Main instance {
            get {
                if (_instance == null)
                    _instance = new Main();
                return _instance;
            }
        }

        public weak Application? application { get; set; }

        public signal void progress (string? message, int processed, int total);

        public Database database { get; private set; }
        public Settings settings { get; private set; }
        public FontConfig.Main fontconfig { get; private set; }
        public Collections collections { get; private set; }
        public CategoryModel category_model { get; set; }
        public CollectionModel collection_model { get; set; }
        public FontModel font_model { get; set; }

        private static Main? _instance = null;
        private bool init_called = false;
        private bool update_in_progress = false;
        private bool queue_update = false;

        public Main () {
            try {
                database = get_database();
            } catch (DatabaseError e) {
                critical("Failed to initialize database : %s", e.message);
            }
            fontconfig = new FontConfig.Main();
            fontconfig.progress.connect((m, p, t) => { progress(m, p, t); });
            collections = load_collections();
            settings = new GLib.Settings(SCHEMA_ID);
            fontconfig.changed.connect((f, ev) => {
                message("Filesystem change detected");
                update();
            });
        }

        public void init () {
            if (init_called)
                return;
            fontconfig.init();
            try {
                sync_fonts_table(database, FontConfig.list_fonts(), (m, p, t) => { progress(m, p, t); });
            } catch (DatabaseError e) {
                critical("Database synchronization failed : %s", e.message);
            }
            init_called = true;
            return;
        }

        public void init_ui () {
            if (!init_called)
                init();
            category_model = new CategoryModel();
            collection_model = new CollectionModel();
            font_model = new FontModel();
            category_model.database = database;
            collection_model.collections = collections;
            font_model.families = fontconfig.families;
            return;
        }

        private void end_update () {
            try {
                sync_fonts_table(database, FontConfig.list_fonts(), (m, p, t) => { progress(m, p, t); });
            } catch (DatabaseError e) {
                critical("Database synchronization failed : %s", e.message);
            }
            category_model.update();
            font_model.update();
            application.main_window.loading = false;
            application.main_window.set_all_models();
            update_in_progress = false;
            if (queue_update)
                Idle.add(() => { update(); return false; });
            return;
        }

        public void update () {
            if (!init_called) {
                init();
                return;
            }
            if (update_in_progress) {
                queue_update = true;
                return;
            } else {
                queue_update = false;
            }
            update_in_progress = true;
            message("Updating font configuration");
            FontConfig.update_cache();
            fontconfig.async_update.begin((obj, res) => {
                try {
                    application.main_window.unset_all_models();
                    application.main_window.loading = true;
                    fontconfig.async_update.end(res);
                    end_update();
                    message("Font configuration update complete");
                } catch (ThreadError e) {
                    critical("Thread error : %s", e.message);
                    end_update();
                }
            });
            return;
        }

        public void on_activate () {
            if (application != null && application.main_window != null) {
                application.main_window.present();
                return;
            }
            application = (Application) GLib.Application.get_default();
            application.main_window = new MainWindow();
            application.main_window.set_icon_name(About.ICON);
            application.add_window(application.main_window);
            application.main_window.loading = true;
            application.main_window.present();
            progress.connect((m, p, t) => {
                application.main_window.progress = ((float) p /(float) t);
                ensure_ui_update();
                }
            );
            init_ui();
            application.main_window.reject = fontconfig.reject;
            application.main_window.set_all_models();
            application.main_window.loading = false;
            application.main_window.state.bind_settings();
            application.main_window.state.post_activate();
            return;
        }

    }

}
