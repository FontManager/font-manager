/* font-manager-fontconfig.h
 *
 * Copyright (C) 2009-2025 Jerry Casiano
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

#pragma once

#include <stdio.h>
#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib/gprintf.h>
#include <glib/gstdio.h>
#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>
#include <json-glib/json-glib.h>
#include <pango/pango-font.h>
#include <pango/pangofc-font.h>
#include <pango/pangofc-fontmap.h>
#include <pango/pango-utils.h>
#include <pango/pango-version-macros.h>

#include "font-manager-json.h"
#include "font-manager-utils.h"
#include "unicode-info.h"

/**
 * FontManagerFontconfigError:
 * @FONT_MANAGER_FONTCONFIG_ERROR_FAILED:     Call to Fontconfig library failed
 */
typedef enum
{
    FONT_MANAGER_FONTCONFIG_ERROR_FAILED
}
FontManagerFontconfigError;

GQuark font_manager_fontconfig_error_quark ();
#define FONT_MANAGER_FONTCONFIG_ERROR font_manager_fontconfig_error_quark()

void font_manager_clear_application_fonts (void);
gboolean font_manager_add_application_font (const gchar *filepath);
gboolean font_manager_add_application_font_directory (const gchar *dir);
gboolean font_manager_update_font_configuration (void);
GList * font_manager_list_available_font_files (void);
FontManagerStringSet * font_manager_get_files_for_family (const char *family);
FontManagerStringSet * font_manager_list_available_font_families (void);
GList * font_manager_get_langs_from_fontconfig_pattern (FcPattern *pattern);
JsonObject * font_manager_get_attributes_from_filepath (const gchar *filepath, GError **error);
JsonObject * font_manager_get_attributes_from_fontconfig_pattern (FcPattern *pattern);
JsonObject * font_manager_get_available_fonts (const gchar *family_name);
JsonObject * font_manager_get_available_fonts_for_chars (const gchar *chars);
JsonArray * font_manager_sort_json_font_listing (JsonObject *json_obj);

/**
 * FontManagerWeight:
 * @FONT_MANAGER_WEIGHT_THIN:           FC_WEIGHT_THIN
 * @FONT_MANAGER_WEIGHT_ULTRALIGHT:     FC_WEIGHT_ULTRALIGHT
 * @FONT_MANAGER_WEIGHT_LIGHT:          FC_WEIGHT_LIGHT
 * @FONT_MANAGER_WEIGHT_SEMILIGHT:      FC_WEIGHT_SEMILIGHT
 * @FONT_MANAGER_WEIGHT_BOOK:           FC_WEIGHT_BOOK
 * @FONT_MANAGER_WEIGHT_REGULAR:        FC_WEIGHT_REGULAR
 * @FONT_MANAGER_WEIGHT_MEDIUM:         FC_WEIGHT_MEDIUM
 * @FONT_MANAGER_WEIGHT_SEMIBOLD:       FC_WEIGHT_SEMIBOLD
 * @FONT_MANAGER_WEIGHT_BOLD:           FC_WEIGHT_BOLD
 * @FONT_MANAGER_WEIGHT_ULTRABOLD:      FC_WEIGHT_ULTRABOLD
 * @FONT_MANAGER_WEIGHT_HEAVY:          FC_WEIGHT_HEAVY
 * @FONT_MANAGER_WEIGHT_ULTRABLACK:     FC_WEIGHT_ULTRABLACK
 *
 * These weight values map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_WEIGHT_THIN = FC_WEIGHT_THIN,
    FONT_MANAGER_WEIGHT_ULTRALIGHT = FC_WEIGHT_ULTRALIGHT,
    FONT_MANAGER_WEIGHT_LIGHT = FC_WEIGHT_LIGHT,
    FONT_MANAGER_WEIGHT_SEMILIGHT = FC_WEIGHT_SEMILIGHT,
    FONT_MANAGER_WEIGHT_BOOK = FC_WEIGHT_BOOK,
    FONT_MANAGER_WEIGHT_REGULAR = FC_WEIGHT_REGULAR,
    FONT_MANAGER_WEIGHT_MEDIUM = FC_WEIGHT_MEDIUM,
    FONT_MANAGER_WEIGHT_SEMIBOLD = FC_WEIGHT_SEMIBOLD,
    FONT_MANAGER_WEIGHT_BOLD = FC_WEIGHT_BOLD,
    FONT_MANAGER_WEIGHT_ULTRABOLD = FC_WEIGHT_ULTRABOLD,
    FONT_MANAGER_WEIGHT_HEAVY = FC_WEIGHT_HEAVY,
    FONT_MANAGER_WEIGHT_ULTRABLACK = FC_WEIGHT_ULTRABLACK
}
FontManagerWeight;

GType font_manager_weight_get_type (void);
#define FONT_MANAGER_TYPE_WEIGHT (font_manager_weight_get_type ())

const gchar * font_manager_weight_to_string (FontManagerWeight weight);
gboolean font_manager_weight_defined (FontManagerWeight weight);

/**
 * FontManagerSlant:
 * @FONT_MANAGER_SLANT_ROMAN:       FC_SLANT_ROMAN
 * @FONT_MANAGER_SLANT_ITALIC:      FC_SLANT_ITALIC
 * @FONT_MANAGER_SLANT_OBLIQUE:     FC_SLANT_OBLIQUE
 *
 * These slant values map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_SLANT_ROMAN = FC_SLANT_ROMAN,
    FONT_MANAGER_SLANT_ITALIC = FC_SLANT_ITALIC,
    FONT_MANAGER_SLANT_OBLIQUE = FC_SLANT_OBLIQUE
}
FontManagerSlant;

GType font_manager_slant_get_type (void);
#define FONT_MANAGER_TYPE_SLANT (font_manager_slant_get_type ())

const gchar * font_manager_slant_to_string (FontManagerSlant slant);

/**
 * FontManagerWidth:
 * @FONT_MANAGER_WIDTH_ULTRACONDENSED:  FC_WIDTH_ULTRACONDENSED
 * @FONT_MANAGER_WIDTH_EXTRACONDENSED:  FC_WIDTH_EXTRACONDENSED
 * @FONT_MANAGER_WIDTH_CONDENSED:       FC_WIDTH_CONDENSED
 * @FONT_MANAGER_WIDTH_SEMICONDENSED:   FC_WIDTH_SEMICONDENSED
 * @FONT_MANAGER_WIDTH_NORMAL:          FC_WIDTH_NORMAL
 * @FONT_MANAGER_WIDTH_SEMIEXPANDED:    FC_WIDTH_SEMIEXPANDED
 * @FONT_MANAGER_WIDTH_EXPANDED:        FC_WIDTH_EXPANDED
 * @FONT_MANAGER_WIDTH_EXTRAEXPANDED:   FC_WIDTH_EXTRAEXPANDED
 * @FONT_MANAGER_WIDTH_ULTRAEXPANDED:   FC_WIDTH_ULTRAEXPANDED
 *
 * These widths map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_WIDTH_ULTRACONDENSED = FC_WIDTH_ULTRACONDENSED,
    FONT_MANAGER_WIDTH_EXTRACONDENSED = FC_WIDTH_EXTRACONDENSED,
    FONT_MANAGER_WIDTH_CONDENSED = FC_WIDTH_CONDENSED,
    FONT_MANAGER_WIDTH_SEMICONDENSED = FC_WIDTH_SEMICONDENSED,
    FONT_MANAGER_WIDTH_NORMAL = FC_WIDTH_NORMAL,
    FONT_MANAGER_WIDTH_SEMIEXPANDED = FC_WIDTH_SEMIEXPANDED,
    FONT_MANAGER_WIDTH_EXPANDED = FC_WIDTH_EXPANDED,
    FONT_MANAGER_WIDTH_EXTRAEXPANDED = FC_WIDTH_EXTRAEXPANDED,
    FONT_MANAGER_WIDTH_ULTRAEXPANDED = FC_WIDTH_ULTRAEXPANDED
}
FontManagerWidth;

GType font_manager_width_get_type (void);
#define FONT_MANAGER_TYPE_WIDTH (font_manager_width_get_type ())

const gchar * font_manager_width_to_string (FontManagerWidth width);
gboolean font_manager_width_defined (FontManagerWidth width);

/**
 * FontManagerSpacing:
 * @FONT_MANAGER_SPACING_PROPORTIONAL:      FC_PROPORTIONAL
 * @FONT_MANAGER_SPACING_DUAL:              FC_DUAL
 * @FONT_MANAGER_SPACING_MONO:              FC_MONO
 * @FONT_MANAGER_SPACING_CHARCELL:          FC_CHARCELL
 *
 * These spacing values map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_SPACING_PROPORTIONAL = FC_PROPORTIONAL,
    FONT_MANAGER_SPACING_DUAL = FC_DUAL,
    FONT_MANAGER_SPACING_MONO = FC_MONO,
    FONT_MANAGER_SPACING_CHARCELL = FC_CHARCELL
}
FontManagerSpacing;

GType font_manager_spacing_get_type (void);
#define FONT_MANAGER_TYPE_SPACING (font_manager_spacing_get_type ())

const gchar * font_manager_spacing_to_string (FontManagerSpacing spacing);

/**
 * FontManagerSubpixelOrder:
 * @FONT_MANAGER_SUBPIXEL_ORDER_UNKNOWN:    FC_RGBA_UNKNOWN
 * @FONT_MANAGER_SUBPIXEL_ORDER_RGB:        FC_RGBA_RGB
 * @FONT_MANAGER_SUBPIXEL_ORDER_BGR:        FC_RGBA_BGR
 * @FONT_MANAGER_SUBPIXEL_ORDER_VRGB:       FC_RGBA_VRGB
 * @FONT_MANAGER_SUBPIXEL_ORDER_VBGR:       FC_RGBA_VBGR
 * @FONT_MANAGER_SUBPIXEL_ORDER_NONE:       FC_RGBA_NONE
 *
 * These rgba values map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_SUBPIXEL_ORDER_UNKNOWN = FC_RGBA_UNKNOWN,
    FONT_MANAGER_SUBPIXEL_ORDER_RGB = FC_RGBA_RGB,
    FONT_MANAGER_SUBPIXEL_ORDER_BGR = FC_RGBA_BGR,
    FONT_MANAGER_SUBPIXEL_ORDER_VRGB = FC_RGBA_VRGB,
    FONT_MANAGER_SUBPIXEL_ORDER_VBGR = FC_RGBA_VBGR,
    FONT_MANAGER_SUBPIXEL_ORDER_NONE = FC_RGBA_NONE
}
FontManagerSubpixelOrder;

GType font_manager_subpixel_order_get_type (void);
#define FONT_MANAGER_TYPE_SUBPIXEL_ORDER (font_manager_subpixel_order_get_type ())

const gchar * font_manager_subpixel_order_to_string (FontManagerSubpixelOrder rgba);

/**
 * FontManagerHintStyle:
 * @FONT_MANAGER_HINT_STYLE_NONE:       FC_HINT_NONE
 * @FONT_MANAGER_HINT_STYLE_SLIGHT:     FC_HINT_SLIGHT
 * @FONT_MANAGER_HINT_STYLE_MEDIUM:     FC_HINT_MEDIUM
 * @FONT_MANAGER_HINT_STYLE_FULL:       FC_HINT_FULL
 *
 * These hinting values map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_HINT_STYLE_NONE = FC_HINT_NONE,
    FONT_MANAGER_HINT_STYLE_SLIGHT = FC_HINT_SLIGHT,
    FONT_MANAGER_HINT_STYLE_MEDIUM = FC_HINT_MEDIUM,
    FONT_MANAGER_HINT_STYLE_FULL = FC_HINT_FULL
}
FontManagerHintStyle;

GType font_manager_hint_style_get_type (void);
#define FONT_MANAGER_TYPE_HINT_STYLE (font_manager_hint_style_get_type ())

const gchar * font_manager_hint_style_to_string (FontManagerHintStyle hinting);

/**
 * FontManagerLCDFilter:
 * @FONT_MANAGER_LCD_FILTER_NONE:       FC_LCD_NONE
 * @FONT_MANAGER_LCD_FILTER_DEFAULT:    FC_LCD_DEFAULT
 * @FONT_MANAGER_LCD_FILTER_LIGHT:      FC_LCD_LIGHT
 * @FONT_MANAGER_LCD_FILTER_LEGACY:     FC_LCD_LEGACY
 *
 * These filter values map directly to those defined by Fontconfig.
 */
typedef enum
{
    FONT_MANAGER_LCD_FILTER_NONE = FC_LCD_NONE,
    FONT_MANAGER_LCD_FILTER_DEFAULT = FC_LCD_DEFAULT,
    FONT_MANAGER_LCD_FILTER_LIGHT = FC_LCD_LIGHT,
    FONT_MANAGER_LCD_FILTER_LEGACY = FC_LCD_LEGACY
}
FontManagerLCDFilter;

GType font_manager_lcd_filter_get_type (void);
#define FONT_MANAGER_TYPE_LCD_FILTER (font_manager_lcd_filter_get_type ())

const gchar * font_manager_lcd_filter_to_string (FontManagerLCDFilter filter);

