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

        public void set_cancellable (Cancellable? cancellable) {
            this.cancellable = cancellable;
            return;
        }

        public void set_progress_callback (ProgressCallback? progress) {
            this.progress = progress;
            return;
        }

        public void update (Json.Object available_fonts) {
            update_started();
            try {
                var child = new Database();
                update_database.begin(
                    child,
                    available_fonts,
                    progress,
                    cancellable,
                    (obj, res) => {
                        try {
                            bool result = update_database.end(res);
                            update_complete();
                        } catch (Error e) {
                            critical(e.message);
                        }
                    }
                );
            } catch (Error e) {
                critical(e.message);
            }
            return;
        }

    }

}

