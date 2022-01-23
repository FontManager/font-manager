/* Unsorted.vala
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

    public class Unsorted : Category {

        public Unsorted () {
            base(_("Unsorted"), _("Fonts not present in any collection"), "dialog-question-symbolic", "%s;".printf(SELECT_FROM_FONTS), CategoryIndex.UNSORTED);
        }

        public new async void update (StringSet sorted) {
            SourceFunc callback = update.callback;
            base.update.begin((obj, res) => {
                base.update.end(res);
                families.remove_all(sorted);
                Idle.add((owned) callback);
            });
            yield;
            return;
        }

    }

}
