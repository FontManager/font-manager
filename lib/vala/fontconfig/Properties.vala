/* Properties.vala
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

    /**
     * {@inheritDoc}
     */
    public class DefaultProperties : Properties {

        public DefaultProperties () {
            type = PropertiesType.DEFAULT;
            target_file = "19-DefaultProperties.conf";
            load();
        }

    }

    /**
     * {@inheritDoc}
     */
    public class DisplayProperties : Properties {

        public DisplayProperties () {
            type = PropertiesType.DISPLAY;
            target_file = "19-DisplayProperties.conf";
            load();
        }

    }

    /**
     * {@inheritDoc}
     */
    public class FontProperties : DefaultProperties {

        /**
         * FontProperties:changed:
         *
         * Emitted whenever family or font changes.
         */
        public signal void changed ();

        /**
         * FontProperties:family:
         *
         * Name of font family this configuration will apply to.
         * If only family is set, configuration will apply to all variations.
         */
        public string? family { get; set; default = null; }

        /**
         * FontProperties:font:
         *
         * #Font this configuration will apply to.
         * If font is set, configuration will apply only to that specific variation.
         */
        public Font? font { get; set; default = null; }

        public FontProperties () {
            type = PropertiesType.DEFAULT;
            target_file = "19-DefaultProperties.conf";
            notify["family"].connect((source, pspec) => {
                load();
                changed();
            });
            notify["font"].connect((s, p) => {
                family = is_valid_source(font) ? font.family : null;
            });
            load();
        }

        /**
         * {@inheritDoc}
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
            if (is_valid_source(font)) {
                target_file = "29-%s.conf".printf(FontManager.to_filename(font.description));
                base.load();
            }
            return true;
        }

        /**
         * {@inheritDoc}
         */
        protected override void add_match_criteria (XmlWriter writer) {
            if (family != null)
                writer.add_test_element("family", "contains", "string", family);
            if (is_valid_source(font)) {
                writer.add_test_element("slant", "eq", "int", font.slant.to_string());
                writer.add_test_element("weight", "eq", "int", font.weight.to_string());
                writer.add_test_element("width", "eq", "int", font.width.to_string());
            }
            base.add_match_criteria(writer);
            return;
        }

    }

}

