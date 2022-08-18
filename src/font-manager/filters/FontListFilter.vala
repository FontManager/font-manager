/* FontListFilter.vala
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

    public int filter_sort (FontListFilter a, FontListFilter b) {
        return (a.index - b.index);
    }

    public class BaseFontListFilterListModel : Object, ListModel {

        public GenericArray <FontListFilter>? items { get; set; default = null; }

        public Type get_item_type () {
            return typeof(FontListFilter);
        }

        public uint get_n_items () {
            return items != null ? items.length : 0;
        }

        public Object? get_item (uint position) {
            return_val_if_fail(items[position] != null, null);
            return items[position];
        }

    }

    public class FontListFilter : Cacheable {

        public virtual string name { owned get; set; }
        public virtual string icon { owned get; set; }
        public virtual string comment { owned get; set; }
        public virtual int index { get; set; default = 0; }
        public virtual int size { get { return 0; } }
        public virtual int depth { get; set; default = 0; }

        public bool requires_update { get; set; default = true; }

        public virtual async void update (StringSet? available_fonts) {
            return;
        }

        public virtual bool matches (Object? item) {
            return item != null ? true : false;
        }

    }

}
