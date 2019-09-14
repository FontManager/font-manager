/* OrthographyList.vala
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

internal double GET_COVERAGE (Json.Object o) { return o.get_double_member("coverage"); }
internal unowned string GET_NAME (Json.Object o) { return o.get_string_member("name"); }

internal string GET_ORTH_FOR (string f, int i) {
return """SELECT json_extract(Orthography.support, '$')
FROM Orthography WHERE json_valid(Orthography.support)
AND Orthography.filepath = "%s" AND Orthography.findex = "%i"; """.printf(f, i);
}

internal string GET_BASE_ORTH_FOR (string f) {
return """SELECT json_extract(Orthography.support, '$')
FROM Orthography WHERE json_valid(Orthography.support)
AND Orthography.filepath = "%s"; """.printf(f);
}

const string SELECT_NON_LATIN_FONTS = """
SELECT DISTINCT description, Orthography.sample FROM Fonts
JOIN Orthography USING (filepath, findex)
WHERE Orthography.sample IS NOT NULL;
""";

public struct BaseOrthographyData
{
    public string name;
    public string native;
}

const BaseOrthographyData [] Orthographies =
{
    { "Afrikaans", "Afrikaans" },
    { "Ahom", "Ahom" },
    { "Aleut Cyrillic", "Aleut Cyrillic" },
    { "Aleut Latin", "Unangan" },
    { "Arabic", "العربية" },
    { "Archaic Greek Letters", "Archaic Greek Letters" },
    { "Armenian", "Հայերեն" },
    { "Astronomy", "Astronomy" },
    { "Balinese", "Balinese" },
    { "Baltic", "Baltic" },
    { "Bamum", "ꚠꚡꚢꚣ" },
    { "Basic Cyrillic", "Кири́ллица" },
    { "Basic Greek", "Ελληνικό αλφάβητο" },
    { "Basic Latin", "Basic Latin" },
    { "Surat Batak", "Surat Batak" },
    { "Bengali", "বাংলা" },
    { "Brāhmī", "Brāhmī" },
    { "Buginese", "Buginese" },
    { "Unified Canadian Aboriginal Syllabics", "Unified Canadian Aboriginal Syllabics" },
    { "Carian", "Carian" },
    { "Catalan", "Català" },
    { "Central European", "Central European" },
    { "Chakma", "Chakma" },
    { "Cham", "Cham" },
    { "Cherokee", "ᏣᎳᎩ" },
    { "Chess Symbols", "Chess Symbols" },

    /* CJK entries added manually */
    { "CJK Unified", "CJK Unified" },
    { "CJK Unified Extension A", "CJK Unified Extension A" },
    { "CJK Unified Extension B", "CJK Unified Extension B" },
    { "CJK Unified Extension C", "CJK Unified Extension C" },
    { "CJK Unified Extension D", "CJK Unified Extension D" },
    { "CJK Unified Extension E", "CJK Unified Extension E" },
    { "CJK Compatibility Ideographs", "CJK Compatibility Ideographs" },
    { "CJK Compatibility Ideographs Supplement", "CJK Compatibility Ideographs Supplement" },
    /* End CJK entries */

    { "Claudian Letters", "Claudian Letters" },
    { "Coptic", "Ⲙⲉⲧⲣⲉⲙ̀ⲛⲭⲏⲙⲓ" },
    { "Currencies", "Currencies" },
    { "Cypriot Syllabary", "Cypriot Syllabary" },
    { "Devanagari", "देवनागरी" },
    { "Dutch", "Nederlands" },
    { "Egyptian Hieroglyphs", "Egyptian Hieroglyphs" },
    { "Emoticons", "Emoticons" },
    { "Ethiopic", "ግዕዝ" },

    /* This "orthography" contains only the euro symbol... */
    //{ "Euro", "Euro" },

    { "Farsi", "فارسی" },
    { "Food and Drink", "Food and Drink" },
    { "Georgian", "ქართული დამწერლობა" },
    { "Glagolitic", "hlaholika" },
    { "Gothic", "𐌲𐌿𐍄𐌹𐍃𐌺" },
    { "Gujarati", "ગુજરાતી લિપિ" },
    { "Gurmukhi", "ਗੁਰਮੁਖੀ" },
    { "Korean Hangul", "한글 / 조선글" },
    { "Hanunó'o", "Hanunó'o" },
    { "Hebrew", "עִבְרִית" },
    { "IPA", "aɪ pʰiː eɪ" },
    { "Igbo Onwu", "Asụsụ Igbo" },
    { "IPA", "aɪ pʰiː eɪ" },
    { "Korean Jamo", "자모" },
    { "Javanese", "Javanese" },
    { "Japanese Jinmeiyo", "日本人名用漢字" },
    { "Japanese Joyo", "日本常用漢字" },
    { "Kaithi", "Kaithi" },
    { "Japanese Kana", "仮名" },
    { "Kannada", "ಕನ್ನಡ" },
    { "Kayah Li", "Kayah Li" },
    { "Kazakh", "قازاق" },
    { "Kharoshthi", "Kharoshthi" },
    { "Khmer", "អក្សរខ្មែរ" },
    { "Japanese Kokuji", "日本国字 (和制汉字)" },
    { "Lao", "ພາສາລາວ" },
    { "Latin Ligatures", "Latin Ligatures" },
    { "Lepcha", "Lepcha" },
    { "Limbu", "Limbu" },
    { "Linear B Ideograms", "Linear B Ideograms" },
    { "Linear B Syllabary", "Linear B Syllabary" },
    { "Malayalam", "മലയാളം" },
    { "Mathematical Greek", "Mathematical Greek" },
    { "Mathematical Latin", "Mathematical Latin" },
    { "Mathematical Numerals", "Mathematical Numerals" },
    { "Mathematical Operators", "Mathematical Operators" },
    { "Meetei Mayak", "Meetei Mayak" },
    { "Mende Kikakui", "Mende Kikakui" },
    { "MeroiticCursive", "MeroiticCursive" },
    { "Meroitic Hieroglyphs", "Meroitic Hieroglyphs" },
    { "Miao", "Miao" },
    { "Mongolian", "Mongolian" },

    /* Medieval Unicode Font Initiative - http://folk.uib.no/hnooh/mufi/
     * Contains lots of duplicates, doubt many would find it useful
     */
    //{ "MUFI 3.0", "MUFI 3.0" },

    { "Myanmar", "မြန်မာအက္ခရာ" },
    { "New Tai Lue", "New Tai Lue" },
    { "N’Ko", "ߒߞߏ" },
    { "Ogham", "Ogham" },
    { "Ol Chiki", "Ol Chiki" },
    { "Old Italic", "Old Italic" },
    { "Old South Arabian", "Old South Arabian" },
    { "Oriya", "ଓଡ଼ିଆ" },
    { "Osmanya", "𐒋𐒘𐒈𐒑𐒛𐒒𐒕𐒀" },
    { "Pan African Latin", "Pan African Latin" },
    { "Pashto", "پښتو" },
    { "Phags Pa", "Phags Pa" },
    { "Pinyin", "汉语拼音" },
    { "Polynesian", "Polynesian" },
    { "Polytonic Greek", "Polytonic Greek" },
    { "Rejang", "Rejang" },
    { "Romanian", "Română" },
    { "Runic", "ᚠᚢᚦᛆᚱᚴ" },
    { "Saurashtra", "Saurashtra" },
    { "Simplified Chinese", "中文简体字" },
    { "Sindhi", "سنڌي" },
    { "Sinhala", "සිංහල" },
    { "South Korean Hanja", "한문교육용기초한자" },
    { "Sundanese", "Sundanese" },
    { "Syloti Nagri", "Syloti Nagri" },
    { "Syriac", "ܠܫܢܐ ܣܘܪܝܝܐ" },
    { "Tai Le", "Tai Le" },
    { "Tai Tham (Lanna)", "ᨲᩫ᩠ᩅᨾᩮᩥᩬᨦ" },
    { "Tai Viet", "Tai Viet" },
    { "Tamil", "தமிழ் அரிச்சுவடி " },
    { "Telugu", "తెలుగు" },
    { "Thaana", "ތާނަ" },
    { "Thai", "ภาษาไทย" },
    { "Tibetan", "དབུ་ཅན་" },
    { "Tifinagh", "ⵜⵉⴼⵉⵏⴰⵖ" },
    { "Traditional Chinese", "中文正體字" },
    { "Turkish", "Türkçe" },
    { "Uighur", "ئۇيغۇر" },
    { "Urdu", "اُردو" },
    { "Vai", "Vai" },
    { "Vedic Extensions", "Vedic Extensions" },
    { "Venda", "Tshivenḓa" },
    { "Vietnamese", "tiếng Việt" },
    { "Western European", "Western European" },
    { "Yi", "ꆈꌠꁱꂷ" },
    { "Chinese Zhuyin Fuhao", "注音符號" },
};

namespace FontManager {

    public Json.Object? get_non_latin_samples () {
        Json.Object? result = null;
        try {
            var db = get_database(DatabaseType.BASE);
            db.execute_query(SELECT_NON_LATIN_FONTS);
            result = new Json.Object();
            foreach (unowned Sqlite.Statement row in db)
                result.set_string_member(row.column_text(0), row.column_text(1));
        } catch (DatabaseError e) {
            message(e.message);
        }
        return result;
    }

    public class OrthographyListModel : Object, GLib.ListModel {

        public Font? font { get; set; default = null; }
        public Json.Object? orthography { get; private set; default = null; }
        public weak OrthographyList? parent { get; set; default = null; }

        GLib.List <unowned Json.Node>? entries;
        Json.Parser? parser = null;
        PlaceHolder updating;
        PlaceHolder unavailable;
        weak PlaceHolder current_placeholder;

        construct {
            parser = new Json.Parser();
            updating = new PlaceHolder(null, "emblem-synchronizing-symbolic");
            string update_txt = _("Update in progress");
            updating.label.set_markup("<b><big>%s</big></b>".printf(update_txt));
            updating.show();
            unavailable = new PlaceHolder(null, "action-unavailable-symbolic");
            unavailable.show();
            notify["parent"].connect(() => {
                parent.placeholder = updating;
                current_placeholder = updating;
            });
        }

        public Type get_item_type () {
            return typeof(Object);
        }

        public uint get_n_items () {
            return entries != null ? entries.length() : 0;
        }

        public new Object? get_item (uint position) {
            return_val_if_fail(entries != null, null);
            return_val_if_fail(position < entries.length(), null);
            Json.Node entry = entries.nth_data(position);
            return new Orthography(entry.get_object());
        }

        public bool update_orthography () {
            entries = null;
            orthography = null;
            if (!is_valid_source(font))
                return false;
            try {
                Database? db = get_database(DatabaseType.BASE);
                string query = GET_ORTH_FOR(font.filepath, font.findex);
                db.execute_query(query);
                if (db.stmt.step() == Sqlite.ROW)
                    parse_json_result(db.stmt.column_text(0));
                else {
                    query = GET_BASE_ORTH_FOR(font.filepath);
                    db.execute_query(query);
                    if (db.stmt.step() == Sqlite.ROW)
                        parse_json_result(db.stmt.column_text(0));
                }
                Idle.add(() => {
                    if (current_placeholder == updating) {
                        parent.placeholder = unavailable;
                        current_placeholder = unavailable;
                    }
                    return false;
                });
            } catch (DatabaseError e) {
                Idle.add(() => {
                    if (current_placeholder != updating) {
                        parent.placeholder = updating;
                        current_placeholder = updating;
                    }
                    return false;
                });
            }
            update_entries();
            if (orthography == null)
                return false;
            return true;
        }

        void parse_json_result (string? json) {
            return_if_fail(json != null);
            try {
                parser.load_from_data(json);
            } catch (Error e) {
                warning(e.message);
                return;
            }
            Json.Node root = parser.get_root();
            if (root.get_node_type() == Json.NodeType.OBJECT)
                orthography = root.get_object();
            return;
        }

        void update_entries () {
            if (orthography == null)
                return;
            /* Remove anything which isn't an object representing an orthography */
            if (orthography.has_member("sample"))
                orthography.remove_member("sample");
            GLib.List <unowned Json.Node>? _entries = orthography.get_values();
            /* Basic Latin is always present but can be empty */
            foreach (var entry in _entries)
                if (GET_COVERAGE(entry.get_object()) > 0)
                    entries.prepend(entry);
            entries.sort((a, b) => {
                Json.Object orth_a = a.get_object();
                Json.Object orth_b = b.get_object();
                int result = (int) GET_COVERAGE(orth_b) - (int) GET_COVERAGE(orth_a);
                if (result == 0)
                    result = natural_sort(GET_NAME(orth_a), GET_NAME(orth_b));
                return result;
            });
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-orthography-list-box-row.ui")]
    public class OrthographyListBoxRow : Gtk.Grid {

        public Orthography orthography { get; private set; }

        [GtkChild] Gtk.Label C_name;
        [GtkChild] Gtk.Label native_name;
        [GtkChild] Gtk.LevelBar coverage;

        public OrthographyListBoxRow (Orthography orth) {
            orthography = orth;
            C_name.set_text(orth.name);
            bool have_native_name = orth.native_name != null && orth.native_name != "";
            string _native = have_native_name ? orth.native_name : orth.name;
            native_name.set_markup("<big>%s</big>".printf(_native));
            double cov_val = ((double) orth.coverage / 100);
            coverage.set_value(cov_val);
            string tooltip = _("Coverage");
            set_tooltip_text("%s : %0.f%%".printf(tooltip, orth.coverage));
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-orthography-list.ui")]
    public class OrthographyList : Gtk.Box {

        public signal void orthography_selected (Orthography? orth);

        public Font? selected_font { get; set; default = null; }

        public PlaceHolder? placeholder {
            set {
                list.set_placeholder(value);
            }
        }

        bool _visible_ = false;
        bool update_pending = false;

        [GtkChild] Gtk.Label header;
        [GtkChild] Gtk.ListBox list;
        [GtkChild] Gtk.Button clear;
        [GtkChild] Gtk.Revealer clear_revealer;

        OrthographyListModel model;

        public OrthographyList () {
            model = new OrthographyListModel();
            model.parent = this;
            var tmpl = "<b><big>%s</big></b>";
            header.set_markup(tmpl.printf(_("Supported Orthographies")));
            bind_property("selected-font", model, "font", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            clear.clicked.connect(() => { list.unselect_all(); });
            map.connect(() => { _visible_ = true; update_if_needed(); });
            unmap.connect(() => { _visible_ = false; });
            notify["selected-font"].connect(() => { update_pending = true; update_if_needed(); });
            list.row_selected.connect((r) => {
                clear_revealer.set_reveal_child(r != null);
                if (r == null) {
                    orthography_selected(null);
                    return;
                }
                var row = ((Gtk.Bin) r).get_child() as OrthographyListBoxRow;
                orthography_selected(row.orthography);
            });
        }

        void update_if_needed () {
            if (_visible_ && update_pending) {
                list.bind_model(null, null);
                if (!model.update_orthography())
                    return;
                list.bind_model(model, (item) => {
                    return new OrthographyListBoxRow(item as Orthography);
                });
                /* Show all available characters by default */
                Idle.add(() => {
                    list.unselect_all();
                    return false;
                });
                update_pending = false;
            }
            return;
        }

    }

}
