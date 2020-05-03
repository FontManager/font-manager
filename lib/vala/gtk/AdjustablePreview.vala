/* AdjustablePreview.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    /**
     * AdjustablePreview:
     *
     * Base class for zoomable text previews
     */
    public abstract class AdjustablePreview : Gtk.Box {

        public double preview_size {
            get {
                return adjustment.value;
            }
            set {
                adjustment.value = value;
            }
        }

        public Gtk.Adjustment adjustment {
            get {
                return fontscale.adjustment;
            }
            set {
                fontscale.adjustment = value;
                value.value_changed.connect(() => { notify_property("preview-size"); });
            }
        }

        protected FontScale fontscale;

        construct {
            name = "AdjustablePreview";
            fontscale = new FontScale();
            adjustment = fontscale.adjustment;
            pack_end(fontscale, false, true, 0);
            fontscale.show();
        }

    }

}
