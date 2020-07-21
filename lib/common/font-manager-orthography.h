/* font-manager-orthography.h
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

#ifndef __FONT_MANAGER_ORTHOGRAPHY_H__
#define __FONT_MANAGER_ORTHOGRAPHY_H__

#include <glib.h>
#include <json-glib/json-glib.h>
#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>
#include <pango/pango-language.h>

#include "font-manager-json-proxy.h"
#include "unicode-info.h"

G_BEGIN_DECLS

JsonObject * font_manager_get_orthography_results (JsonObject *font);
gchar * font_manager_get_sample_string_for_orthography (JsonObject *orthography, GList *charset);

static const FontManagerJsonProxyProperties OrthographyProperties [] =
{
    { "RESERVED", G_TYPE_RESERVED_GLIB_FIRST, NULL },
    { "name", G_TYPE_STRING, "English name for orthography" },
    { "native", G_TYPE_STRING, "Native name for orthography" },
    { "sample", G_TYPE_STRING, "Pangram or sample string"},
    { "coverage", G_TYPE_DOUBLE, "Coverage as a percentage" },
    { FONT_MANAGER_JSON_PROXY_SOURCE, G_TYPE_RESERVED_USER_FIRST, "JsonObject source for this class" }
};


#define FONT_MANAGER_TYPE_ORTHOGRAPHY (font_manager_orthography_get_type ())
G_DECLARE_FINAL_TYPE(FontManagerOrthography, font_manager_orthography, FONT_MANAGER, ORTHOGRAPHY, FontManagerJsonProxy)

FontManagerOrthography * font_manager_orthography_new (JsonObject *orthography);
GList * font_manager_orthography_get_filter (FontManagerOrthography *self);


#define FONT_MANAGER_START_RANGE_PAIR 0x0002
#define FONT_MANAGER_END_OF_DATA 0x0000

typedef struct
{
    const gchar *name;
    const gchar *native;
    const gunichar key;
    const gchar *sample;
    const gchar *pangram [10];
    const gunichar values [4096];
}
FontManagerOrthographyData;

static const FontManagerOrthographyData ArabicOrthographies [] = {
#include "Arabic"
#include "Farsi"
#include "Urdu"
#include "Kazakh"
#include "Pashto"
#include "Sindhi"
#include "Uighur"
};

static const FontManagerOrthographyData ChineseOrthographies [] = {
#include "SimplifiedChinese"
#include "TraditionalChinese"
#include "ZhuYinFuHao"
#include "CJKUnified"
};

static const FontManagerOrthographyData GreekOrthographies [] = {
#include "BasicGreek"
#include "PolytonicGreek"
#include "ArchaicGreekLetters"
};

static const FontManagerOrthographyData JapaneseOrthographies [] = {
#include "Kana"
#include "Joyo"
#include "Jinmeiyo"
#include "Kokuji"
};

static const FontManagerOrthographyData KoreanOrthographies [] = {
#include "Jamo"
#include "Hangul"
#include "SouthKoreanHanja"
};

static const FontManagerOrthographyData LatinOrthographies [] = {
#include "BasicLatin"
#include "WesternEuropean"
// Only contains one symbol
//#include "Euro"
#include "Catalan"
#include "Baltic"
#include "Turkish"
#include "CentralEuropean"
#include "Romanian"
#include "Vietnamese"
#include "PanAfricanLatin"
#include "Dutch"
#include "Afrikaans"
#include "Pinyin"
#include "IPA"
#include "LatinLigatures"
#include "ClaudianLetters"
#include "Venda"
#include "IgboOnwu"
};

static const FontManagerOrthographyData UncategorizedOrthographies [] = {

//
// The Rest: (In Latin alphabetic order for now ... )
//
#include "Ahom"
#include "AleutCyrillic"
#include "AleutLatin"
#include "Armenian"
#include "Astronomy"
#include "BasicCyrillic"
#include "CanadianSyllabics"
#include "Carian"
#include "Chakma"
#include "Cherokee"
#include "Coptic"
#include "Currencies"
#include "Food"
#include "Georgian"
#include "Hebrew"
#include "Khmer"
#include "Lao"
#include "MendeKikakui"
#include "Miao"
// Not very useful?
//#include "MUFI"
#include "Myanmar"
#include "Ogham"
#include "Polynesian"
#include "Runic"
#include "Syriac"
#include "Thaana"
#include "Thai"
#include "Tibetan"
#include "Yi"

//
// Symbols -- Divide Unicode blocks
// into meaningful groups such as "chess symbols"
// as necessary.
//
#include "MathematicalGreek"
#include "MathematicalLatin"
#include "MathematicalNumerals"
#include "MathematicalOperators"
#include "ChessSymbols"
#include "Emoticons"

//
// Indic:
//
#include "Bengali"
#include "Devanagari"
#include "Kannada"
#include "Tamil"
#include "Sinhala"
#include "Telugu"
#include "Malayalam"
#include "Gujarati"
#include "Gurmukhi"
#include "Oriya"
#include "Kaithi"
#include "Kharoshthi"
#include "Lepcha"
#include "Limbu"
#include "MeeteiMayak"
#include "OlChiki"
#include "Saurashtra"
#include "SylotiNagri"
#include "VedicExtensions"

//
// Philippine scripts
//
#include "Hanunoo"

//
// African scripts
//
#include "Nko"
#include "Osmanya"
#include "Tifinagh"
#include "Vai"
#include "Ethiopic"

// 2009.08.27.ET Additions:
#include "TaiLe"
#include "NewTaiLue"
#include "PhagsPa"
#include "Mongolian"
#include "TaiTham"

// 2011.04.19,20.ET Addenda:
#include "Glagolitic"
#include "Gothic"
#include "Bamum"
#include "Brahmi"

#include "Batak"
#include "Balinese"
#include "Buginese"
#include "Cham"
#include "Javanese"
#include "KayahLi"

#include "Rejang"
#include "Sundanese"
#include "TaiViet"

//////////////////////
//
// Historic:
//
//////////////////////
#include "OldSouthArabian"
#include "LinearBIdeograms"
#include "LinearBSyllabary"
#include "CypriotSyllabary"
#include "MeroiticHieroglyphs"
#include "MeroiticCursive"
#include "EgyptianHieroglyphs"

};

G_END_DECLS

#endif /* __FONT_MANAGER_ORTHOGRAPHY_H__ */

