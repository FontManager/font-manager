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

namespace FontManager {

    public class Main : Object {

        public static Main instance {
            get {
                if (_instance == null)
                    _instance = new Main();
                return _instance;
            }
        }

        public unowned Application? application { get; set; }

        public signal void progress (string? message, int processed, int total);

        public Database database { get; private set; }
        public Settings settings { get; private set; }
        public FontConfig.Main fontconfig { get; private set; }
        public Collections collections { get; private set; }
        public CategoryModel category_model { get; set; }
        public CollectionModel collection_model { get; set; }
        public FontModel font_model { get; set; }
        public UserSourceModel user_source_model { get; private set; }

        private static Main? _instance = null;
        internal bool init_called = false;
        internal bool update_in_progress = false;
        internal bool queue_update = false;

        public Main () {
            database = get_database();
            fontconfig = new FontConfig.Main();
            fontconfig.progress.connect((m, p, t) => { progress(m, p, t); });
            collections = load_collections();
            category_model = new CategoryModel();
            collection_model = new CollectionModel();
            font_model = new FontModel();
            user_source_model = new UserSourceModel();
            settings = new GLib.Settings(SCHEMA_ID);
            fontconfig.changed.connect((f, ev) => { update(); });
        }

        public void init () {
            if (init_called)
                return;
            fontconfig.init();
            sync_fonts_table(database, FontConfig.list_fonts(), (m, p, t) => { progress(m, p, t); });
            category_model.database = database;
            collection_model.collections = collections;
            font_model.families = fontconfig.families;
            user_source_model.sources = fontconfig.sources;
            init_called = true;
            return;
        }

        internal void end_update () {
            sync_fonts_table(database, FontConfig.list_fonts(), (m, p, t) => { progress(m, p, t); });
            category_model.update();
            font_model.update();
            application.main_window.loading = false;
            application.main_window.set_all_models();
            update_in_progress = false;
            if (queue_update)
                update();
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
            FontConfig.update_cache();
            fontconfig.update.begin((obj, res) => {
                try {
                    application.main_window.unset_all_models();
                    application.main_window.loading = true;
                    fontconfig.update.end(res);
                    end_update();
                } catch (ThreadError e) {
                    critical("Thread error : %s", e.message);
                    end_update();
                }
            });
            return;
        }

        public void on_activate (Application application) {
            if (application.main_window != null) {
                application.main_window.present();
                return;
            }
            this.application = application;
            application.main_window = new MainWindow();
            application.add_window(application.main_window);
            application.main_window.loading = true;
            application.main_window.restore_state();
            application.main_window.present();
            progress.connect((m, p, t) => {
                application.main_window.progress = ((float) p /(float) t);
                ensure_ui_update();
                }
            );
            init();
            application.main_window.reject = fontconfig.reject;
            application.main_window.set_all_models();
            application.main_window.loading = false;
            application.main_window.bind_settings();
            application.main_window.post_activate();
            return;
        }

    }

}
