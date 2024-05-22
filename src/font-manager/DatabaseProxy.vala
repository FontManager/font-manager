/* DatabaseProxy.vala
 *
 * Copyright (C) 2020-2024 Jerry Casiano
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

    public class DatabaseProxy : Object {

        public signal void update_started ();
        public signal void update_complete ();

        GLib.Cancellable? cancellable = null;
        ProgressCallback? progress = null;

        static Database? db = null;

        public static unowned Database get_default_db () {
            if (db == null)
                db = new Database();
            return db;
        }

        public void set_cancellable (Cancellable? cancellable) {
            this.cancellable = cancellable;
            return;
        }

        public void set_progress_callback (ProgressCallback? progress) {
            this.progress = progress;
            return;
        }

        public void update (Json.Array available_fonts) {
            update_started();
            Database db = new Database();
            update_database.begin(
                db,
                available_fonts,
                progress,
                cancellable,
                (obj, res) => {
                    try {
                        update_database.end(res);
                        update_complete();
                        db.close();
                    } catch (Error e) {
                        critical(e.message);
                    }
                }
            );
            return;
        }

    }

}


