/* About.vala
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

    namespace About {

        public const string NAME = _("Font Manager");
        public const string ICON = "font-x-generic";
        public const string COMMENT = _("Simple font management for GTK+ desktop environments");
        public const string VERSION = "0.7.1";
        public const string HOMEPAGE = "http://code.google.com/p/font-manager/";
        public const string COPYRIGHT = "Copyright © 2009 - 2014 Jerry Casiano";
        public const string LICENSE = _("""
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    """);

        public const string [] AUTHORS = {
            AUTHOR,
            null
        };

        public const string [] DOCUMENTERS = {
            AUTHOR,
            null
        };

        public const string [] ARTISTS = {
            null
        };

        public const string TRANSLATORS = "translator-credits";

    }

    void show_version () {
        stdout.printf("%s %s\n", About.NAME, About.VERSION);
        return;
    }

    void show_about () {
        stdout.printf("\n    %s - %s\n\n\t\t  %s\n%s\n",
                                    About.NAME,
                                    About.COMMENT,
                                    About.COPYRIGHT,
                                    About.LICENSE);
        return;
    }

    void show_about_dialog (Gtk.Window? parent = null) {
        Gtk.show_about_dialog(parent,
                            "program-name", About.NAME,
                            "logo-icon-name", About.ICON,
                            "version", About.VERSION,
                            "copyright", About.COPYRIGHT,
                            "comments", About.COMMENT,
                            "website", About.HOMEPAGE,
                            "authors", About.AUTHORS,
                            "license", About.LICENSE,
                            //"artists", About.ARTISTS,
                            "translator-credits", About.TRANSLATORS,
                            null);
        return;
    }

}
