/* Enums.vala
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

namespace FontConfig {

    public enum Hint {
        NONE,
        SLIGHT,
        MEDIUM,
        FULL;

        public string to_string () {
            switch (this) {
                case SLIGHT:
                    return "Slight";
                case MEDIUM:
                    return "Medium";
                case FULL:
                    return "Full";
                default:
                    return "None";
            }
        }

    }

    public enum LCD {
        NONE,
        DEFAULT,
        LIGHT,
        LEGACY;

        public string to_string () {
            switch (this) {
                case DEFAULT:
                    return "Default";
                case LIGHT:
                    return "Light";
                case LEGACY:
                    return "Legacy";
                default:
                    return "None";
            }
        }

    }

    public enum RGBA {
        UNKNOWN,
        RGB,
        BGR,
        VRGB,
        VBGR,
        NONE;

        public string to_string () {
            switch (this) {
                case UNKNOWN:
                    return "Unknown";
                case RGB:
                    return "RGB";
                case BGR:
                    return "BGR";
                case VRGB:
                    return "VRGB";
                case VBGR:
                    return "VBGR";
                default:
                    return "None";
            }
        }

    }

    public enum Spacing {
        PROPORTIONAL    = 0,
        DUAL            = 90,
        MONO            = 100,
        CHARCELL        = 110;

        public string? to_string () {
            switch (this) {
                case PROPORTIONAL:
                    return "Proportional";
                case DUAL:
                    return "Dual Width";
                case MONO:
                    return "Monospace";
                case CHARCELL:
                    return "Charcell";
                default:
                    return null;
            }
        }

    }

    public enum Slant {
        ROMAN    =  0,
        ITALIC   =  100,
        OBLIQUE  =  110;

        public string? to_string () {
            switch (this) {
                case ITALIC:
                    return "Italic";
                case OBLIQUE:
                    return "Oblique";
                default:
                    return null;
            }
        }

    }

    public enum Width {
        ULTRACONDENSED  =  50,
        EXTRACONDENSED  =  63,
        CONDENSED       =  75,
        SEMICONDENSED   =  87,
        NORMAL          =  100,
        SEMIEXPANDED    =  113,
        EXPANDED        =  125,
        EXTRAEXPANDED   =  150,
        ULTRAEXPANDED   =  200;

        public string? to_string () {
            switch (this) {
                case ULTRACONDENSED:
                    return "Ultra-Condensed";
                case EXTRACONDENSED:
                    return "Extra-Condensed";
                case CONDENSED:
                    return "Condensed";
                case SEMICONDENSED:
                    return "Semi-Condensed";
                case SEMIEXPANDED:
                    return "Semi-Expanded";
                case EXPANDED:
                    return "Expanded";
                case EXTRAEXPANDED:
                    return "Extra-Expanded";
                case ULTRAEXPANDED:
                    return "Ultra-Expanded";
                default:
                    return null;
            }
        }

    }

    public enum Weight {
        THIN        =  0,
        EXTRALIGHT  =  40,
        ULTRALIGHT  =  EXTRALIGHT,
        LIGHT       =  50,
        BOOK        =  75,
        REGULAR     =  80,
        NORMAL      =  REGULAR,
        MEDIUM      =  100,
        DEMIBOLD    =  180,
        SEMIBOLD    =  DEMIBOLD,
        BOLD        =  200,
        EXTRABOLD   =  205,
        BLACK       =  210,
        HEAVY       =  BLACK,
        EXTRABLACK  =  215,
        ULTRABLACK  =  EXTRABLACK;

        public string? to_string () {
            switch (this) {
                case THIN:
                    return "Thin";
                case ULTRALIGHT:
                    return "Ultra-Light";
                case LIGHT:
                    return "Light";
                case BOOK:
                    return "Book";
                case MEDIUM:
                    return "Medium";
                case SEMIBOLD:
                    return "Semi-Bold";
                case BOLD:
                    return "Bold";
                case EXTRABOLD:
                    return "Ultra-Bold";
                case HEAVY:
                    return "Heavy";
                case ULTRABLACK:
                    return "Ultra-Heavy";
                default:
                    return null;
            }
        }

    }

}
