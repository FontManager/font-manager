/* Fontconfig.vala
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
     * Fontconfig default font properties configuration
     */
    public class DefaultProperties : Properties {

        public DefaultProperties () {
            type = PropertiesType.DEFAULT;
            target_file = "19-DefaultProperties.conf";
            load();
        }

    }

    /**
     * Fontconfig display properties configuration
     */
    public class DisplayProperties : Properties {

        public DisplayProperties () {
            type = PropertiesType.DISPLAY;
            target_file = "19-DisplayProperties.conf";
            load();
        }

    }

    /**
     * Fontconfig font specific properties configuration
     */
    public class FontProperties : DefaultProperties {

        /**
         * Emitted whenever family or font changes.
         */
        public signal void changed ();

        /**
         * Name of font family this configuration will apply to.
         * If only family is set, configuration will apply to all variations.
         */
        public string? family { get; set; default = null; }

        /**
         * Font this configuration will apply to.
         * If font is set, configuration will apply only to that specific variation.
         */
        public Font? font { get; set; default = null; }

        public FontProperties () {
            notify["family"].connect((source, pspec) => {
                load();
                changed();
            });
            notify["font"].connect((s, p) => {
                family = font.is_valid() ? font.family : null;
            });
            load();
        }

        /**
         * Load saved settings
         */
        public override bool load () {
            /* Load global settings */
            target_file = "19-DefaultProperties.conf";
            base.load();
            /* Load any settings that apply to entire family */
            if (family != null) {
                target_file = "29-%s.conf".printf(family);
                base.load();
            }
            /* Load font specific settings */
            if (font.is_valid()) {
                target_file = "29-%s.conf".printf(FontManager.to_filename(font.description));
                base.load();
            }
            return true;
        }

        /**
         * Save settings to file
         */
        public override bool save () {
            if (font.is_valid())
                target_file = "29-%s.conf".printf(FontManager.to_filename(font.description));
            else if (family != null)
                target_file = "29-%s.conf".printf(family);
            return base.save();
        }

        protected override void add_match_criteria (XmlWriter writer) {
            if (family != null)
                writer.add_test_element("family", "contains", "string", family);
            if (font.is_valid()) {
                writer.add_test_element("slant", "eq", "int", font.slant.to_string());
                writer.add_test_element("weight", "eq", "int", font.weight.to_string());
                writer.add_test_element("width", "eq", "int", font.width.to_string());
            }
            base.add_match_criteria(writer);
            return;
        }

    }

    /**
     * Fonts that can not be disabled
     */
    public class Accept : Selections {

        public Accept () {
            config_dir = FontManager.get_user_fontconfig_directory();
            target_element = "acceptfont";
            target_file = "79-Accept.conf";
        }

    }

}

