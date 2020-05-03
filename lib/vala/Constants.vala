/* Constants.vala
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

    public const string AUTHOR = "Jerry Casiano <JerryCasiano@gmail.com>";

    public const string BUS_ID = "org.gnome.FontManager";
    public const string BUS_PATH = "/org/gnome/FontManager";

    namespace FontViewer {
        public const string BUS_ID = "org.gnome.FontViewer";
        public const string BUS_PATH = "/org/gnome/FontViewer";
    }

    public const int MINIMUM_MARGIN_SIZE = 2;
    public const int DEFAULT_MARGIN_SIZE = 18;

    public const double DEFAULT_PREVIEW_SIZE = 10;
    public const double MIN_FONT_SIZE = 6.0;
    public const double MAX_FONT_SIZE = 96.0;

    public const string SELECT_FROM_FONTS = "SELECT DISTINCT family, description FROM Fonts";
    public const string SELECT_FROM_METADATA_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Metadata USING (filepath, findex) WHERE";
    public const string SELECT_FROM_PANOSE_WHERE = "SELECT DISTINCT Fonts.family, Fonts.description FROM Fonts JOIN Panose USING (filepath, findex) WHERE";

    public const string TMP_TMPL = "font-manager_XXXXXX";

    public const string DEFAULT_FONT = "Sans";

    public const string DEFAULT_PREVIEW_TEXT = """
    %s

    ABCDEFGHIJKLMNOPQRSTUVWXYZ
    abcdefghijklmnopqrstuvwxyz
    1234567890.:,;(*!?')

    """;

    public const string LOREM_IPSUM = """Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent sed tristique nunc. Sed augue dolor, posuere a auctor quis, dignissim sed est. Aliquam convallis, orci nec posuere lacinia, risus libero mattis velit, a consectetur orci felis venenatis neque. Praesent id lacinia massa. Nam risus diam, faucibus vitae pulvinar eget, scelerisque nec nisl. Integer dolor ligula, placerat id elementum id, venenatis sed massa. Vestibulum at convallis libero. Curabitur at molestie justo.

Mauris convallis odio rutrum elit aliquet quis fermentum velit tempus. Ut porttitor lectus at dui iaculis in vestibulum eros tristique. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec ut dui massa, at aliquet leo. Cras sagittis pulvinar nunc. Fusce eget felis ut dolor blandit scelerisque non eget risus. Nunc elementum ipsum id lacus porttitor accumsan. Suspendisse at quam ligula, ultrices bibendum massa.

Mauris feugiat, orci non fermentum congue, libero est rutrum sem, non dignissim justo urna at turpis. Donec non varius augue. Fusce id enim ligula, sit amet mattis urna. Ut sodales augue tristique tortor lobortis vestibulum. Maecenas quis tortor lacus. Etiam varius hendrerit bibendum. Nullam pretium nulla in sem blandit vel facilisis felis fermentum. Integer aliquet leo nec nunc sollicitudin congue. In hac habitasse platea dictumst. Curabitur mattis nibh ac velit euismod condimentum. Pellentesque volutpat, neque ac congue fermentum, turpis metus posuere turpis, ac facilisis velit lectus sed diam. Etiam dui diam, tempus vitae fringilla quis, tincidunt ac libero.

Quisque sollicitudin eros sit amet lorem semper nec imperdiet ante vehicula. Proin a vulputate sem. Aliquam erat volutpat. Vestibulum congue pulvinar eros eu vestibulum. Phasellus metus mauris, suscipit tristique ullamcorper laoreet, viverra eget libero. Donec id nibh justo. Aliquam sagittis ultricies erat. Integer sed purus felis. Pellentesque leo nisi, sagittis non tincidunt vitae, porta quis eros. Pellentesque ut ornare erat. Vivamus semper sodales suscipit. Praesent placerat eleifend nibh quis tristique. Aenean ullamcorper pellentesque ultrices. Nunc eu risus turpis, in condimentum dui. Aliquam erat volutpat. Phasellus sagittis mattis diam, sit amet pharetra lacus cursus non.

Vestibulum sed est id velit rhoncus imperdiet. Aliquam dictum, arcu at tincidunt condimentum, metus ligula molestie lorem, eget congue tortor est ut massa. Duis ut pulvinar nisl. Aenean sodales purus id risus hendrerit sit amet mattis sem blandit. Aenean feugiat dapibus mattis. Praesent non nibh magna. Nulla facilisi. Nam elementum malesuada sagittis. Cras et tellus augue, non rhoncus libero. Suspendisse ut nulla mauris.

Suspendisse potenti. Nulla neque leo, condimentum nec posuere non, elementum sit amet lorem. Integer ut ante libero, a tristique quam. Nulla libero nibh, bibendum eget blandit non, viverra in velit. Duis sit amet ipsum in massa imperdiet interdum. Phasellus venenatis consequat lectus eget facilisis. Quisque ullamcorper rutrum erat at egestas. Integer pharetra pulvinar odio, sagittis imperdiet ligula aliquam suscipit. Aenean rutrum convallis felis, at rhoncus lectus tincidunt et. Morbi mattis risus eu quam suscipit ut tempus nunc pellentesque. Ut adipiscing, nibh nec pharetra fringilla, diam diam hendrerit neque, quis pretium tellus ligula ut dolor. Nullam dictum, libero in molestie convallis, nunc arcu imperdiet risus, vitae laoreet risus ipsum in ligula. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec molestie, quam ut adipiscing consequat, risus sem facilisis nisi, ut aliquet sapien est a sapien. Quisque sed enim justo, sit amet volutpat urna.""";

    public const string [] TYPE1_METRICS = {
        ".afm",
        ".pfa",
        ".pfm"
    };

    public const string [] FONT_MIMETYPES = {
        "application/x-font-ttf",
        "application/x-font-ttc",
        "application/x-font-otf",
        "application/x-font-type1",
        "font/ttf",
        "font/ttc",
        "font/otf",
        "font/type1",
        "font/collection"
    };

    namespace About {

        public const string DISPLAY_NAME = _("Font Manager");
        public const string ICON = "font-x-generic";
        public const string COMMENT = _("Simple font management for GTK+ desktop environments");
        public const string NAME = Config.PACKAGE_NAME;
        public const string VERSION = Config.PACKAGE_VERSION;
        public const string HOMEPAGE = Config.PACKAGE_URL;
        public const string BUG_TRACKER = Config.PACKAGE_BUGREPORT;
        public const string COPYRIGHT = "Copyright © 2009 - 2019 Jerry Casiano";
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
    along with this program.

    If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
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

        public const string TRANSLATORS = _("translator-credits");

    }

}

