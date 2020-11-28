/* Weight.vala
 *
 * Copyright (C) 2020 Jerry Casiano
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

#if HAVE_WEBKIT

namespace FontManager.GoogleFonts {

    public enum Weight {

        THIN = 100,
        EXTRA_LIGHT = 200,
        LIGHT = 300,
        REGULAR = 400,
        MEDIUM = 500,
        SEMI_BOLD = 600,
        BOLD = 700,
        EXTRA_BOLD = 800,
        BLACK = 900;

        public string to_string () {
            switch (this) {
                case THIN:
                    return "Thin";
                case EXTRA_LIGHT:
                    return "ExtraLight";
                case LIGHT:
                    return "Light";
                case REGULAR:
                    return "Regular";
                case MEDIUM:
                    return "Medium";
                case SEMI_BOLD:
                    return "SemiBold";
                case BOLD:
                    return "Bold";
                case EXTRA_BOLD:
                    return "ExtraBold";
                case BLACK:
                    return "Black";
                default:
                    assert_not_reached();
            }
        }

        public string to_translatable_string () {
            switch (this) {
                case THIN:
                    return _("Thin");
                case EXTRA_LIGHT:
                    return _("ExtraLight");
                case LIGHT:
                    return _("Light");
                case REGULAR:
                    return _("Regular");
                case MEDIUM:
                    return _("Medium");
                case SEMI_BOLD:
                    return _("SemiBold");
                case BOLD:
                    return _("Bold");
                case EXTRA_BOLD:
                    return _("ExtraBold");
                case BLACK:
                    return _("Black");
                default:
                    assert_not_reached();
            }
        }

    }

}

#endif /* HAVE_WEBKIT */
