/* font-manager-orthography.h
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

#ifndef __ORTHOGRAPHY_DATA_H__
#define __ORTHOGRAPHY_DATA_H__

#include <glib.h>
#include <json-glib/json-glib.h>

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

#define N_ARABIC G_N_ELEMENTS(ArabicOrthographies)
#define N_CHINESE G_N_ELEMENTS(ChineseOrthographies)
#define N_GREEK G_N_ELEMENTS(GreekOrthographies)
#define N_JAPANESE G_N_ELEMENTS(JapaneseOrthographies)
#define N_KOREAN G_N_ELEMENTS(KoreanOrthographies)
#define N_LATIN G_N_ELEMENTS(LatinOrthographies)
#define N_MISC G_N_ELEMENTS(UncategorizedOrthographies)

JsonObject * font_manager_get_orthography_results (JsonObject *font);
gchar * font_manager_get_sample_string_for_orthography (JsonObject *orthography, GList *charset);

#endif /* __ORTHOGRAPHY_DATA_H__ */

