/* Description.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <https://opensource.org/licenses/GPL-3.0>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/


namespace FontManager {

    namespace Metadata {

        public class Description : StaticTextView {

            public Description () {
                base(null);
                hexpand = true;
                view.margin = DEFAULT_MARGIN_SIZE / 2;
                view.justification = Gtk.Justification.LEFT;
                view.pixels_above_lines = 1;
                set_size_request(0, 0);
                get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                expand = true;
            }

            void reset () {
                buffer.set_text("");
                return;
            }

            public void update (FontData? font_data) {
                this.reset();
                if (font_data == null || font_data.fontinfo == null)
                    return;
                var fontinfo = font_data.fontinfo;
                if (fontinfo.copyright != null)
                    view.buffer.set_text("%s".printf(fontinfo.copyright));
                if (fontinfo.description != null && fontinfo.description.length > 10)
                    view.buffer.set_text("%s\n\n%s".printf(get_buffer_text(), fontinfo.description));
                return;
            }

        }

    }

}

