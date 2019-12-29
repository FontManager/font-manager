/* Metadata.vala
 *
 * Copyright (C) 2009 - 2019 Jerry Casiano
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

    public class Metadata : Object {

        public Font? selected_font { get; set; default = null; }
        public FontInfo? info { get; private set; default = null; }

        public PropertiesPane properties { get; private set; }
        public LicensePane license { get; private set; }

        bool update_pending = false;

        public Metadata () {
            properties = new PropertiesPane();
            license = new LicensePane();
            info = new FontInfo();
            connect_signals();
            properties.show();
            license.show();
        }

        void connect_signals () {
            notify["selected-font"].connect(() => { update_pending = true; update_if_needed(); });
            properties.notify["is-mapped"].connect(() => { update_if_needed(); });
            license.notify["is-mapped"].connect(() => { update_if_needed(); });
            return;
        }

        public void update () {
            if (selected_font.is_valid()) {
                info = new FontInfo();
                try {
                    Database db = get_database(DatabaseType.BASE);
                    string select = "SELECT * FROM Metadata WHERE filepath='%s' AND findex='%i'";
                    string query = select.printf(selected_font.filepath, selected_font.findex);
                    info.source_object = db.get_object(query);
                } catch (DatabaseError e) { }
                if (info.source_object == null)
                    info.source_object = get_metadata(selected_font.filepath, selected_font.findex);
            }
            properties.update(selected_font, info);
            license.update(info);
            return;
        }

        void update_if_needed () {
            if (!properties.is_mapped && !license.is_mapped)
                return;
            if (update_pending) {
                info = null;
                update();
                update_pending = false;
            }
            return;
        }

    }

}
