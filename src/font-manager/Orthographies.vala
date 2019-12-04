/* Orthographies.vala
 *
 * Copyright (C) 2019 Jerry Casiano
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

    public struct BaseOrthographyData
    {
        public string name;
        public string native;
    }

    public const BaseOrthographyData [] Orthographies =
    {
        { N_("Afrikaans"), "Afrikaans" },
        { N_("Ahom"), "Ahom" },
        { N_("Aleut Cyrillic"), "Aleut Cyrillic" },
        { N_("Aleut Latin"), "Unangan" },
        { N_("Arabic"), "العربية" },
        { N_("Archaic Greek Letters"), "Archaic Greek Letters" },
        { N_("Armenian"), "Հայերեն" },
        { N_("Astronomy"), "Astronomy" },
        { N_("Balinese"), "Balinese" },
        { N_("Baltic"), "Baltic" },
        { N_("Bamum"), "ꚠꚡꚢꚣ" },
        { N_("Basic Cyrillic"), "Кири́ллица" },
        { N_("Basic Greek"), "Ελληνικό αλφάβητο" },
        { N_("Basic Latin"), "Basic Latin" },
        { N_("Surat Batak"), "Surat Batak" },
        { N_("Bengali"), "বাংলা" },
        { N_("Brāhmī"), "Brāhmī" },
        { N_("Buginese"), "Buginese" },
        { N_("Unified Canadian Aboriginal Syllabics"), "Unified Canadian Aboriginal Syllabics" },
        { N_("Carian"), "Carian" },
        { N_("Catalan"), "Català" },
        { N_("Central European"), "Central European" },
        { N_("Chakma"), "Chakma" },
        { N_("Cham"), "Cham" },
        { N_("Cherokee"), "ᏣᎳᎩ" },
        { N_("Chess Symbols"), "Chess Symbols" },

        /* CJK entries added manually */
        { N_("CJK Unified"), "CJK Unified" },
        { N_("CJK Unified Extension A"), "CJK Unified Extension A" },
        { N_("CJK Unified Extension B"), "CJK Unified Extension B" },
        { N_("CJK Unified Extension C"), "CJK Unified Extension C" },
        { N_("CJK Unified Extension D"), "CJK Unified Extension D" },
        { N_("CJK Unified Extension E"), "CJK Unified Extension E" },
        { N_("CJK Compatibility Ideographs"), "CJK Compatibility Ideographs" },
        { N_("CJK Compatibility Ideographs Supplement"), "CJK Compatibility Ideographs Supplement" },
        /* End CJK entries */

        { N_("Claudian Letters"), "Claudian Letters" },
        { N_("Coptic"), "Ⲙⲉⲧⲣⲉⲙ̀ⲛⲭⲏⲙⲓ" },
        { N_("Currencies"), "Currencies" },
        { N_("Cypriot Syllabary"), "Cypriot Syllabary" },
        { N_("Devanagari"), "देवनागरी" },
        { N_("Dutch"), "Nederlands" },
        { N_("Egyptian Hieroglyphs"), "Egyptian Hieroglyphs" },
        { N_("Emoticons"), "Emoticons" },
        { N_("Ethiopic"), "ግዕዝ" },

        /* This "orthography" contains only the euro symbol... */
        //{ N_("Euro"), "Euro" },

        { N_("Farsi"), "فارسی" },
        { N_("Food and Drink"), "Food and Drink" },
        { N_("Georgian"), "ქართული დამწერლობა" },
        { N_("Glagolitic"), "hlaholika" },
        { N_("Gothic"), "𐌲𐌿𐍄𐌹𐍃𐌺" },
        { N_("Gujarati"), "ગુજરાતી લિપિ" },
        { N_("Gurmukhi"), "ਗੁਰਮੁਖੀ" },
        { N_("Korean Hangul"), "한글 / 조선글" },
        { N_("Hanunó'o"), "Hanunó'o" },
        { N_("Hebrew"), "עִבְרִית" },
        { N_("IPA"), "aɪ pʰiː eɪ" },
        { N_("Igbo Onwu"), "Asụsụ Igbo" },
        { N_("IPA"), "aɪ pʰiː eɪ" },
        { N_("Korean Jamo"), "자모" },
        { N_("Javanese"), "Javanese" },
        { N_("Japanese Jinmeiyo"), "日本人名用漢字" },
        { N_("Japanese Joyo"), "日本常用漢字" },
        { N_("Kaithi"), "Kaithi" },
        { N_("Japanese Kana"), "仮名" },
        { N_("Kannada"), "ಕನ್ನಡ" },
        { N_("Kayah Li"), "Kayah Li" },
        { N_("Kazakh"), "قازاق" },
        { N_("Kharoshthi"), "Kharoshthi" },
        { N_("Khmer"), "អក្សរខ្មែរ" },
        { N_("Japanese Kokuji"), "日本国字 (和制汉字)" },
        { N_("Lao"), "ພາສາລາວ" },
        { N_("Latin Ligatures"), "Latin Ligatures" },
        { N_("Lepcha"), "Lepcha" },
        { N_("Limbu"), "Limbu" },
        { N_("Linear B Ideograms"), "Linear B Ideograms" },
        { N_("Linear B Syllabary"), "Linear B Syllabary" },
        { N_("Malayalam"), "മലയാളം" },
        { N_("Mathematical Greek"), "Mathematical Greek" },
        { N_("Mathematical Latin"), "Mathematical Latin" },
        { N_("Mathematical Numerals"), "Mathematical Numerals" },
        { N_("Mathematical Operators"), "Mathematical Operators" },
        { N_("Meetei Mayak"), "Meetei Mayak" },
        { N_("Mende Kikakui"), "Mende Kikakui" },
        { N_("MeroiticCursive"), "MeroiticCursive" },
        { N_("Meroitic Hieroglyphs"), "Meroitic Hieroglyphs" },
        { N_("Miao"), "Miao" },
        { N_("Mongolian"), "Mongolian" },

        /* Medieval Unicode Font Initiative - http://folk.uib.no/hnooh/mufi/
         * Contains lots of duplicates, doubt many would find it useful
         */
        //{ N_("MUFI 3.0"), "MUFI 3.0" },

        { N_("Myanmar"), "မြန်မာအက္ခရာ" },
        { N_("New Tai Lue"), "New Tai Lue" },
        { N_("N’Ko"), "ߒߞߏ" },
        { N_("Ogham"), "Ogham" },
        { N_("Ol Chiki"), "Ol Chiki" },
        { N_("Old Italic"), "Old Italic" },
        { N_("Old South Arabian"), "Old South Arabian" },
        { N_("Oriya"), "ଓଡ଼ିଆ" },
        { N_("Osmanya"), "𐒋𐒘𐒈𐒑𐒛𐒒𐒕𐒀" },
        { N_("Pan African Latin"), "Pan African Latin" },
        { N_("Pashto"), "پښتو" },
        { N_("Phags Pa"), "Phags Pa" },
        { N_("Pinyin"), "汉语拼音" },
        { N_("Polynesian"), "Polynesian" },
        { N_("Polytonic Greek"), "Polytonic Greek" },
        { N_("Rejang"), "Rejang" },
        { N_("Romanian"), "Română" },
        { N_("Runic"), "ᚠᚢᚦᛆᚱᚴ" },
        { N_("Saurashtra"), "Saurashtra" },
        { N_("Simplified Chinese"), "中文简体字" },
        { N_("Sindhi"), "سنڌي" },
        { N_("Sinhala"), "සිංහල" },
        { N_("South Korean Hanja"), "한문교육용기초한자" },
        { N_("Sundanese"), "Sundanese" },
        { N_("Syloti Nagri"), "Syloti Nagri" },
        { N_("Syriac"), "ܠܫܢܐ ܣܘܪܝܝܐ" },
        { N_("Tai Le"), "Tai Le" },
        { N_("Tai Tham (Lanna)"), "ᨲᩫ᩠ᩅᨾᩮᩥᩬᨦ" },
        { N_("Tai Viet"), "Tai Viet" },
        { N_("Tamil"), "தமிழ் அரிச்சுவடி " },
        { N_("Telugu"), "తెలుగు" },
        { N_("Thaana"), "ތާނަ" },
        { N_("Thai"), "ภาษาไทย" },
        { N_("Tibetan"), "དབུ་ཅན་" },
        { N_("Tifinagh"), "ⵜⵉⴼⵉⵏⴰⵖ" },
        { N_("Traditional Chinese"), "中文正體字" },
        { N_("Turkish"), "Türkçe" },
        { N_("Uighur"), "ئۇيغۇر" },
        { N_("Urdu"), "اُردو" },
        { N_("Vai"), "Vai" },
        { N_("Vedic Extensions"), "Vedic Extensions" },
        { N_("Venda"), "Tshivenḓa" },
        { N_("Vietnamese"), "tiếng Việt" },
        { N_("Western European"), "Western European" },
        { N_("Yi"), "ꆈꌠꁱꂷ" },
        { N_("Chinese Zhuyin Fuhao"), "注音符號" },
    };

}
