/* UserSourceModel.vala
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

    int sort_font_source (FontConfig.FontSource a, FontConfig.FontSource b) {
        if (a.filetype != b.filetype)
            return a.filetype - b.filetype;
        else
            return natural_cmp(a.name, b.name);
    }

    public class UserSourceModel : Gtk.TreeStore {

        public FontConfig.Sources sources {
            get {
                return _sources;
            }
            set {
                _sources = value;
                this.update();
                _sources.changed.connect(() => { this.update(); });
            }
        }

        internal FontConfig.Sources _sources;

        construct {
            set_column_types({typeof(Object), typeof(string)});
        }

        Gee.ArrayList <FontConfig.FontSource> sort_sources () {
            var sorted = new Gee.ArrayList <FontConfig.FontSource> ();
            sorted.add_all(sources);
            sorted.sort((CompareDataFunc) sort_font_source);
            return sorted;
        }

        public void update () {
            clear();
            if (sources == null)
                return;
            var sorted = sort_sources();
            foreach (var source in sorted) {
                Gtk.TreeIter iter;
                this.append(out iter, null);
                this.set(iter, 0, source, 1, source.name, -1);
            }
            return;
        }

        public void init () {
            update();
            return;
        }

        public void add_source_from_uri (string uri) {
            var source = new FontConfig.FontSource(File.new_for_uri(uri));
            sources.add(source);
            Gtk.TreeIter iter;
            this.append(out iter, null);
            this.set(iter, 0, source, 1, source.name, -1);
            sources.save();
            return;
        }

    }

}
