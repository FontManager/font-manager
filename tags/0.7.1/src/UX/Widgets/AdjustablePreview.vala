/* AdjustablePreview.vala
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

    public abstract class AdjustablePreview : Gtk.Box {

        public double preview_size {
            get {
                return _preview_size;
            }
            set {
                _preview_size = value.clamp(MIN_FONT_SIZE, MAX_FONT_SIZE);
                fontscale.adjustment.value = _preview_size;
                set_preview_size_internal(_preview_size);
            }
        }

        public Gtk.Adjustment adjustment {
            get {
                return fontscale.adjustment;
            }
            set {
                fontscale.adjustment = value;
                fontscale.adjustment.value_changed.connect((adj) => {
                    preview_size = adj.get_value();
                });
            }
        }

        protected double _preview_size;

        protected FontScale fontscale;

        protected abstract void set_preview_size_internal (double new_size);

        protected virtual void init () {
            fontscale = new FontScale();
            fontscale.adjustment.value_changed.connect((adj) => {
                preview_size = adj.get_value();
            });
            return;
        }

        protected double get_desc_size () {
            if (preview_size <= 10)
                return preview_size;
            else if (preview_size <= 20)
                return preview_size / 1.25;
            else if (preview_size <= 30)
                return preview_size / 1.5;
            else if (preview_size <= 50)
                return preview_size / 1.75;
            else
                return preview_size / 2;
        }

    }

}
