/* License.vala
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
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontManager {

    namespace Metadata {

        public class License : Gtk.Overlay {

            Gtk.Grid grid;
            Gtk.EventBox blend;
            Gtk.LinkButton link;
            StaticTextView view;
            WelcomeLabel notice;

            public License () {
                grid = new Gtk.Grid();
                view = new StaticTextView(null);
                view.view.margin = 24;
                view.view.pixels_above_lines = 1;
                var tmpl = "<big>%s</big>";
                notice = new WelcomeLabel(tmpl.printf(_("File does not contain license information.")));
                notice.opacity = 0.5;
                link = new Gtk.LinkButton("");
                link.margin = 6;
                link.set_label("");
                link.halign = Gtk.Align.CENTER;
                link.valign = Gtk.Align.CENTER;
                blend = new Gtk.EventBox();
                blend.add(link);
                blend.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                view.expand = true;
                grid.attach(view, 0, 0, 1, 3);
                grid.attach(blend, 0, 3, 1 ,1);
                grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
                add(grid);
                add_overlay(notice);
            }

            public override void show () {
                link.show();
                view.show();
                notice.show();
                grid.show();
                blend.show();
                base.show();
                this.reset();
                return;
            }

            void reset () {
                view.buffer.set_text("");
                link.set_uri("");
                link.set_label("");
                blend.hide();
                view.hide();
                notice.show();
                return;
            }

            public void update (FontData? font_data) {
                this.reset();
                if (font_data == null || font_data.fontinfo == null)
                    return;
                var fontinfo = font_data.fontinfo;
                if (fontinfo.license_data == null && fontinfo.license_url == null)
                    return;
                if (fontinfo.license_url != null) {
                    link.set_uri(fontinfo.license_url);
                    link.set_label(fontinfo.license_url);
                    blend.show();
                }
                bool license_data = (fontinfo.license_data != null);
                if (license_data)
                    view.buffer.set_text("\n%s\n".printf(fontinfo.license_data));
                view.visible = license_data;
                link.expand = !license_data;
                if (!license_data && fontinfo.license_url == null)
                    notice.show();
                else
                    notice.hide();
                return;
            }

        }

    }

}
