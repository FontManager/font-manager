/* Private.h
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
 */



#ifndef _____SRC_GLUE_PRIVATE_H__
#define _____SRC_GLUE_PRIVATE_H__

#include <glib.h>
#include <glib-object.h>
#include <json-glib/json-glib.h>
#include <json-glib/json-gobject.h>
#include <stdlib.h>
#include <string.h>
#include <gee.h>
#include <gio/gio.h>

G_BEGIN_DECLS


#define TYPE_CACHEABLE (cacheable_get_type ())
#define CACHEABLE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_CACHEABLE, Cacheable))
#define CACHEABLE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_CACHEABLE, CacheableClass))
#define IS_CACHEABLE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_CACHEABLE))
#define IS_CACHEABLE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_CACHEABLE))
#define CACHEABLE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_CACHEABLE, CacheableClass))

typedef struct _Cacheable Cacheable;
typedef struct _CacheableClass CacheableClass;
typedef struct _CacheablePrivate CacheablePrivate;

#define FONT_MANAGER_TYPE_FONT_INFO (font_manager_font_info_get_type ())
#define FONT_MANAGER_FONT_INFO(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), FONT_MANAGER_TYPE_FONT_INFO, FontManagerFontInfo))
#define FONT_MANAGER_FONT_INFO_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), FONT_MANAGER_TYPE_FONT_INFO, FontManagerFontInfoClass))
#define FONT_MANAGER_IS_FONT_INFO(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FONT_MANAGER_TYPE_FONT_INFO))
#define FONT_MANAGER_IS_FONT_INFO_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), FONT_MANAGER_TYPE_FONT_INFO))
#define FONT_MANAGER_FONT_INFO_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), FONT_MANAGER_TYPE_FONT_INFO, FontManagerFontInfoClass))

typedef struct _FontManagerFontInfo FontManagerFontInfo;
typedef struct _FontManagerFontInfoClass FontManagerFontInfoClass;
typedef struct _FontManagerFontInfoPrivate FontManagerFontInfoPrivate;

#define TYPE_MENU_ENTRY (menu_entry_get_type ())

#define TYPE_MENU_CALLBACK_WRAPPER (menu_callback_wrapper_get_type ())
#define MENU_CALLBACK_WRAPPER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_MENU_CALLBACK_WRAPPER, MenuCallbackWrapper))
#define MENU_CALLBACK_WRAPPER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_MENU_CALLBACK_WRAPPER, MenuCallbackWrapperClass))
#define IS_MENU_CALLBACK_WRAPPER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_MENU_CALLBACK_WRAPPER))
#define IS_MENU_CALLBACK_WRAPPER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_MENU_CALLBACK_WRAPPER))
#define MENU_CALLBACK_WRAPPER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_MENU_CALLBACK_WRAPPER, MenuCallbackWrapperClass))

typedef struct _MenuCallbackWrapper MenuCallbackWrapper;
typedef struct _MenuCallbackWrapperClass MenuCallbackWrapperClass;
typedef struct _MenuEntry MenuEntry;
typedef struct _MenuCallbackWrapperPrivate MenuCallbackWrapperPrivate;

#define FONT_CONFIG_TYPE_FONT (font_config_font_get_type ())
#define FONT_CONFIG_FONT(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), FONT_CONFIG_TYPE_FONT, FontConfigFont))
#define FONT_CONFIG_FONT_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), FONT_CONFIG_TYPE_FONT, FontConfigFontClass))
#define FONT_CONFIG_IS_FONT(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FONT_CONFIG_TYPE_FONT))
#define FONT_CONFIG_IS_FONT_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), FONT_CONFIG_TYPE_FONT))
#define FONT_CONFIG_FONT_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), FONT_CONFIG_TYPE_FONT, FontConfigFontClass))

typedef struct _FontConfigFont FontConfigFont;
typedef struct _FontConfigFontClass FontConfigFontClass;
typedef struct _FontConfigFontPrivate FontConfigFontPrivate;

#define FONT_CONFIG_TYPE_HINT (font_config_hint_get_type ())

#define FONT_CONFIG_TYPE_LCD (font_config_lcd_get_type ())

#define FONT_CONFIG_TYPE_RGBA (font_config_rgba_get_type ())

#define FONT_CONFIG_TYPE_SPACING (font_config_spacing_get_type ())

#define FONT_CONFIG_TYPE_SLANT (font_config_slant_get_type ())

#define FONT_CONFIG_TYPE_WIDTH (font_config_width_get_type ())

#define FONT_CONFIG_TYPE_WEIGHT (font_config_weight_get_type ())

struct _Cacheable {
	GObject parent_instance;
	CacheablePrivate * priv;
};

struct _CacheableClass {
	GObjectClass parent_class;
	gboolean (*deserialize_property) (Cacheable* self, const gchar* prop_name, GValue* val, GParamSpec* pspec, JsonNode* node);
	JsonNode* (*serialize_property) (Cacheable* self, const gchar* prop_name, GValue* val, GParamSpec* pspec);
};

struct _FontManagerFontInfo {
	Cacheable parent_instance;
	FontManagerFontInfoPrivate * priv;
	gint status;
};

struct _FontManagerFontInfoClass {
	CacheableClass parent_class;
};

typedef void (*ReloadFunc) (void* user_data);
typedef void (*MenuCallback) (void* user_data);
typedef void (*ProgressCallback) (const gchar* message, gint processed, gint total, void* user_data);
struct _MenuEntry {
	gchar* action_name;
	gchar* display_name;
	gchar* detailed_action_name;
	gchar* accelerator;
	MenuCallbackWrapper* method;
};

struct _MenuCallbackWrapper {
	GTypeInstance parent_instance;
	volatile int ref_count;
	MenuCallbackWrapperPrivate * priv;
	MenuCallback run;
	gpointer run_target;
	GDestroyNotify run_target_destroy_notify;
};

struct _MenuCallbackWrapperClass {
	GTypeClass parent_class;
	void (*finalize) (MenuCallbackWrapper *self);
};

struct _FontConfigFont {
	Cacheable parent_instance;
	FontConfigFontPrivate * priv;
};

struct _FontConfigFontClass {
	CacheableClass parent_class;
};

typedef enum  {
	FONT_CONFIG_HINT_NONE,
	FONT_CONFIG_HINT_SLIGHT,
	FONT_CONFIG_HINT_MEDIUM,
	FONT_CONFIG_HINT_FULL
} FontConfigHint;

typedef enum  {
	FONT_CONFIG_LCD_NONE,
	FONT_CONFIG_LCD_DEFAULT,
	FONT_CONFIG_LCD_LIGHT,
	FONT_CONFIG_LCD_LEGACY
} FontConfigLCD;

typedef enum  {
	FONT_CONFIG_RGBA_UNKNOWN,
	FONT_CONFIG_RGBA_RGB,
	FONT_CONFIG_RGBA_BGR,
	FONT_CONFIG_RGBA_VRGB,
	FONT_CONFIG_RGBA_VBGR,
	FONT_CONFIG_RGBA_NONE
} FontConfigRGBA;

typedef enum  {
	FONT_CONFIG_SPACING_PROPORTIONAL = 0,
	FONT_CONFIG_SPACING_DUAL = 90,
	FONT_CONFIG_SPACING_MONO = 100,
	FONT_CONFIG_SPACING_CHARCELL = 110
} FontConfigSpacing;

typedef enum  {
	FONT_CONFIG_SLANT_ROMAN = 0,
	FONT_CONFIG_SLANT_ITALIC = 100,
	FONT_CONFIG_SLANT_OBLIQUE = 110
} FontConfigSlant;

typedef enum  {
	FONT_CONFIG_WIDTH_ULTRACONDENSED = 50,
	FONT_CONFIG_WIDTH_EXTRACONDENSED = 63,
	FONT_CONFIG_WIDTH_CONDENSED = 75,
	FONT_CONFIG_WIDTH_SEMICONDENSED = 87,
	FONT_CONFIG_WIDTH_NORMAL = 100,
	FONT_CONFIG_WIDTH_SEMIEXPANDED = 113,
	FONT_CONFIG_WIDTH_EXPANDED = 125,
	FONT_CONFIG_WIDTH_EXTRAEXPANDED = 150,
	FONT_CONFIG_WIDTH_ULTRAEXPANDED = 200
} FontConfigWidth;

typedef enum  {
	FONT_CONFIG_WEIGHT_THIN = 0,
	FONT_CONFIG_WEIGHT_EXTRALIGHT = 40,
	FONT_CONFIG_WEIGHT_ULTRALIGHT = FONT_CONFIG_WEIGHT_EXTRALIGHT,
	FONT_CONFIG_WEIGHT_LIGHT = 50,
	FONT_CONFIG_WEIGHT_BOOK = 75,
	FONT_CONFIG_WEIGHT_REGULAR = 80,
	FONT_CONFIG_WEIGHT_NORMAL = FONT_CONFIG_WEIGHT_REGULAR,
	FONT_CONFIG_WEIGHT_MEDIUM = 100,
	FONT_CONFIG_WEIGHT_DEMIBOLD = 180,
	FONT_CONFIG_WEIGHT_SEMIBOLD = FONT_CONFIG_WEIGHT_DEMIBOLD,
	FONT_CONFIG_WEIGHT_BOLD = 200,
	FONT_CONFIG_WEIGHT_EXTRABOLD = 205,
	FONT_CONFIG_WEIGHT_BLACK = 210,
	FONT_CONFIG_WEIGHT_HEAVY = FONT_CONFIG_WEIGHT_BLACK,
	FONT_CONFIG_WEIGHT_EXTRABLACK = 215,
	FONT_CONFIG_WEIGHT_ULTRABLACK = FONT_CONFIG_WEIGHT_EXTRABLACK
} FontConfigWeight;


GType cacheable_get_type (void) G_GNUC_CONST;
GType font_manager_font_info_get_type (void) G_GNUC_CONST;
FontManagerFontInfo* font_manager_font_info_new_from_filepath (const gchar* filepath, gint index);
FontManagerFontInfo* font_manager_font_info_construct_from_filepath (GType object_type, const gchar* filepath, gint index);
FontManagerFontInfo* font_manager_font_info_new (void);
FontManagerFontInfo* font_manager_font_info_construct (GType object_type);
gint font_manager_font_info_get_owner (FontManagerFontInfo* self);
void font_manager_font_info_set_owner (FontManagerFontInfo* self, gint value);
const gchar* font_manager_font_info_get_filetype (FontManagerFontInfo* self);
void font_manager_font_info_set_filetype (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_filesize (FontManagerFontInfo* self);
void font_manager_font_info_set_filesize (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_checksum (FontManagerFontInfo* self);
void font_manager_font_info_set_checksum (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_version (FontManagerFontInfo* self);
void font_manager_font_info_set_version (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_psname (FontManagerFontInfo* self);
void font_manager_font_info_set_psname (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_description (FontManagerFontInfo* self);
void font_manager_font_info_set_description (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_vendor (FontManagerFontInfo* self);
void font_manager_font_info_set_vendor (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_copyright (FontManagerFontInfo* self);
void font_manager_font_info_set_copyright (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_license_type (FontManagerFontInfo* self);
void font_manager_font_info_set_license_type (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_license_data (FontManagerFontInfo* self);
void font_manager_font_info_set_license_data (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_license_url (FontManagerFontInfo* self);
void font_manager_font_info_set_license_url (FontManagerFontInfo* self, const gchar* value);
const gchar* font_manager_font_info_get_panose (FontManagerFontInfo* self);
void font_manager_font_info_set_panose (FontManagerFontInfo* self, const gchar* value);
void intl_setup (const gchar* name);
GType menu_entry_get_type (void) G_GNUC_CONST;
gpointer menu_callback_wrapper_ref (gpointer instance);
void menu_callback_wrapper_unref (gpointer instance);
GParamSpec* param_spec_menu_callback_wrapper (const gchar* name, const gchar* nick, const gchar* blurb, GType object_type, GParamFlags flags);
void value_set_menu_callback_wrapper (GValue* value, gpointer v_object);
void value_take_menu_callback_wrapper (GValue* value, gpointer v_object);
gpointer value_get_menu_callback_wrapper (const GValue* value);
GType menu_callback_wrapper_get_type (void) G_GNUC_CONST;
MenuEntry* menu_entry_dup (const MenuEntry* self);
void menu_entry_free (MenuEntry* self);
void menu_entry_copy (const MenuEntry* self, MenuEntry* dest);
void menu_entry_destroy (MenuEntry* self);
void menu_entry_init (MenuEntry *self, const gchar* name, const gchar* label, const gchar* detailed_signal, const gchar* accel, MenuCallbackWrapper* cbw);
MenuCallbackWrapper* menu_callback_wrapper_new (MenuCallback c, void* c_target);
MenuCallbackWrapper* menu_callback_wrapper_construct (GType object_type, MenuCallback c, void* c_target);
gchar* get_command_line_output (const gchar* cmd);
gchar* get_user_font_dir (void);
gchar* get_localized_pangram (void);
gchar* get_localized_preview_text (void);
gchar* get_local_time (void);
gint natural_cmp (const gchar* a, const gchar* b);
gchar* get_file_extension (const gchar* path);
GeeArrayList* sorted_list_from_collection (GeeCollection* iter);
void builder_append (GString* builder, const gchar* val);
void add_action_from_menu_entry (GActionMap* map, MenuEntry* entry);
gboolean remove_directory_tree_if_empty (GFile* dir);
gboolean remove_directory (GFile* dir, gboolean recursive);
GType font_config_font_get_type (void) G_GNUC_CONST;
gint font_config_sort_fonts (FontConfigFont* a, FontConfigFont* b);
gchar* font_config_font_to_filename (FontConfigFont* self);
gchar* font_config_font_to_string (FontConfigFont* self);
FontConfigFont* font_config_font_new (void);
FontConfigFont* font_config_font_construct (GType object_type);
const gchar* font_config_font_get_filepath (FontConfigFont* self);
void font_config_font_set_filepath (FontConfigFont* self, const gchar* value);
gint font_config_font_get_index (FontConfigFont* self);
void font_config_font_set_index (FontConfigFont* self, gint value);
const gchar* font_config_font_get_family (FontConfigFont* self);
void font_config_font_set_family (FontConfigFont* self, const gchar* value);
const gchar* font_config_font_get_style (FontConfigFont* self);
void font_config_font_set_style (FontConfigFont* self, const gchar* value);
gint font_config_font_get_slant (FontConfigFont* self);
void font_config_font_set_slant (FontConfigFont* self, gint value);
gint font_config_font_get_weight (FontConfigFont* self);
void font_config_font_set_weight (FontConfigFont* self, gint value);
gint font_config_font_get_width (FontConfigFont* self);
void font_config_font_set_width (FontConfigFont* self, gint value);
gint font_config_font_get_spacing (FontConfigFont* self);
void font_config_font_set_spacing (FontConfigFont* self, gint value);
gint font_config_font_get_owner (FontConfigFont* self);
void font_config_font_set_owner (FontConfigFont* self, gint value);
const gchar* font_config_font_get_description (FontConfigFont* self);
void font_config_font_set_description (FontConfigFont* self, const gchar* value);
GType font_config_hint_get_type (void) G_GNUC_CONST;
gchar* font_config_hint_to_string (FontConfigHint self);
GType font_config_lcd_get_type (void) G_GNUC_CONST;
gchar* font_config_lcd_to_string (FontConfigLCD self);
GType font_config_rgba_get_type (void) G_GNUC_CONST;
gchar* font_config_rgba_to_string (FontConfigRGBA self);
GType font_config_spacing_get_type (void) G_GNUC_CONST;
gchar* font_config_spacing_to_string (FontConfigSpacing self);
GType font_config_slant_get_type (void) G_GNUC_CONST;
gchar* font_config_slant_to_string (FontConfigSlant self);
GType font_config_width_get_type (void) G_GNUC_CONST;
gchar* font_config_width_to_string (FontConfigWidth self);
GType font_config_weight_get_type (void) G_GNUC_CONST;
gchar* font_config_weight_to_string (FontConfigWeight self);
gint free_type_num_faces (const gchar* filepath);
gint free_type_query_file_info (FontManagerFontInfo* fileinfo, const gchar* filepath, gint index);
gchar* font_config_get_version_string (void);
gboolean font_config_update_cache (void);
FontConfigFont* font_config_get_font_from_file (const gchar* filepath, gint index);
GeeArrayList* font_config_list_fonts (const gchar* family_name);
GeeArrayList* font_config_list_families (void);
GeeArrayList* font_config_list_files (void);
GeeArrayList* font_config_list_dirs (gboolean recursive);
GeeArrayList* font_config_list_user_dirs (void);
gboolean font_config_enable_user_config (gboolean enable);
gboolean font_config_add_app_font (const gchar* filepath);
gboolean font_config_add_app_font_dir (const gchar* dir);
void font_config_clear_app_fonts (void);
gboolean font_config_load_config (const gchar* filepath);
gboolean cacheable_deserialize_property (Cacheable* self, const gchar* prop_name, GValue* val, GParamSpec* pspec, JsonNode* node);
GParamSpec** cacheable_list_properties (Cacheable* self, int* result_length1);
JsonNode* cacheable_serialize_property (Cacheable* self, const gchar* prop_name, GValue* val, GParamSpec* pspec);
Cacheable* cacheable_new (void);
Cacheable* cacheable_construct (GType object_type);


/* Open source license information courtesy of
 *
 *  //
 *  // The Fontaine Font Analysis Project
 *  //
 *  // Copyright (c) 2009 by Edward H. Trager
 *  // All Rights Reserved
 *  //
 *  // Released under the GNU GPL version 2.0 or later.
 *  //
 *
 * See http://www.unifont.org/fontaine/ for more information.
 *
 * Special thanks to Edward H. Trager, and of course everyone
 * involved with the Open Font Library for all their efforts. :-)
 *
 * http://www.openfontlibrary.org/
 */


#define MAX_KEYWORD_ENTRIES 25

static const struct
{
    const gchar   *license;
    const gchar   *license_url;
    const gchar   *keywords[MAX_KEYWORD_ENTRIES];
}

LicenseData[] =
{

    {
        "Aladdin Free Public License",
        "http://pages.cs.wisc.edu/~ghost/doc/AFPL/6.01/Public.htm",
        {
            "Aladdin",
            NULL
        }
    },

    {
        "Apache 2.0",
        "http://www.apache.org/licenses/LICENSE-2.0",
        {
            "Apache",
            "Apache License",
            "Apache 2 License",
            NULL
        }
    },

    {
        "Arphic Public License",
        "http://ftp.gnu.org/gnu/non-gnu/chinese-fonts-truetype/LICENSE",
        {
            "ARPHIC PUBLIC LICENSE",
            "Arphic Public License",
            "文鼎公眾授權書",
            "Arphic",
            NULL
        }
    },

    {
        "Bitstream Vera License",
        "http://www-old.gnome.org/fonts/#Final_Bitstream_Vera_Fonts",
        {
            "Bitstream",
            "Vera",
            "DejaVu",
            NULL
        }
    },

    {
        "CC-BY-SA",
        "http://creativecommons.org/licenses/by-sa/3.0/",
        {
            "Creative Commons Attribution ShareAlike",
            "Creative-Commons-Attribution-ShareAlike",
            "Creative Commons Attribution Share Alike",
            "Creative-Commons-Attribution-Share-Alike",
            "Creative Commons BY SA",
            "Creative-Commons-BY-SA",
            "CC BY SA",
            "CC-BY-SA",
            NULL
        }
    },

    {
        "CC-BY",
        "http://creativecommons.org/licenses/by/3.0/",
        {
            "Creative Commons Attribution",
            "Creative-Commons-Attribution",
            "CC BY",
            "CC-BY",
            NULL
        }
    },

    {
        "CC-0",
        "http://creativecommons.org/publicdomain/zero/1.0/",
        {
            "Creative Commons Zero",
            "Creative-Commons-Zero",
            "Creative Commons 0",
            "Creative-Commons-0",
            "CC Zero",
            "CC-Zero",
            "CC 0",
            "CC-0",
            NULL
        }
    },

    {
        "Freeware",
        "http://en.wikipedia.org/wiki/Freeware",
        {
            "freeware",
            "free ware",
            NULL
        }
    },

    {
        "GPL with font exception",
        "http://www.gnu.org/copyleft/gpl.html",
        {
            "LiberationFontLicense",
            "with font exception",
            "Liberation font software",
            "LIBERATION is a trademark of Red Hat",
            "this font does not by itself cause the resulting document to be covered by the GNU",
            NULL
        }
    },

    {
        "GNU General Public License",
        "http://www.gnu.org/copyleft/gpl.html",
        {
            "GPL",
            "GNU Public License",
            "GNU GENERAL PUBLIC LICENSE",
            "GNU General Public License",
            "General Public License",
            "GNU copyleft",
            "GNU",
            "www.gnu.org",
            "Licencia Pública General de GNU",
            "free as in free-speech",
            "free as in free speech",
            "languagegeek.com",
            NULL
        }
    },

    {
        "GNU Lesser General Public License",
        "http://www.gnu.org/licenses/lgpl.html",
        {
            "LGPL",
            "GNU Lesser General Public License",
            "Lesser General Public License",
            NULL
        }
    },

    {
        "GUST Font License",
        "http://tug.org/fonts/licenses/GUST-FONT-LICENSE.txt",
        {
            "GUST",
            NULL
        }
    },

    {
        "IPA",
        "http://opensource.org/licenses/ipafont.html",
        {
            "IPA License",
            "Information-technology Promotion Agency",
            "(IPA)",
            " IPA ",
            NULL
        }
    },

    {
        "M+ Fonts Project License",
        "http://mplus-fonts.sourceforge.jp/webfonts/#license",
        {
            "M+ FONTS PROJECT",
            NULL
        }
    },

    {
        "Magenta Open License",
        "http://www.ellak.gr/pub/fonts/mgopen/index.en.html#license",
        {
            "MgOpen",
            NULL
        }
    },

    {
        "Monotype Imaging EULA",
        "http://www.fonts.com/info/legal/eula/monotype-imaging",
        {
            "valuable asset of Monotype",
            "Monotype Typography",
            "www.monotype.com",
            NULL
        }
    },

    {
        "SIL Open Font License",
        "http://scripts.sil.org/OFL",
        {
            "OFL",
            "Open Font License",
            "scripts.sil.org/OFL",
            "openfont",
            "open font",
            "NHN Corporation",
            "American Mathematical Society",
            "http://www.ams.org",
            NULL
        }
    },

    {
        "Public Domain (not a license)",
        "http://en.wikipedia.org/wiki/Public_domain",
        {
            "public domain",
            "Public Domain",
            NULL
        }
    },

    {
        "STIX Font License",
        "http://www.aip.org/stixfonts/user_license.html",
        {
            "2007 by the STI Pub Companies",
            "the derivative work will carry a different name",
            NULL
        }
    },

    {
        "Ubuntu Font License 1.0",
        "http://font.ubuntu.com/ufl/ubuntu-font-licence-1.0.txt",
        {
            "Ubuntu Font Licence 1.0",
            "UBUNTU FONT LICENCE Version 1.0",
            NULL
        }
    },

    {
        "License to TeX Users Group for the Utopia Typeface",
        "http://tug.org/fonts/utopia/LICENSE-utopia.txt",
        {
            "The Utopia fonts are freely available; see http://tug.org/fonts/utopia",
            NULL
        }
    },

    {
        "XFree86 License",
        "http://www.xfree86.org/legal/licenses.html",
        {
            "XFree86",
            NULL
        }
    },

    {
        "MIT (X11) License",
        "http://www.opensource.org/licenses/mit-license.php",
        {
            "MIT",
            "X11",
            NULL
        }
    },

    {
        "Unknown License",
        NULL,
        {
            NULL
        }
    },
};

#define LICENSE_ENTRIES G_N_ELEMENTS(LicenseData)

gint get_license_type(const gchar *license, const gchar *copyright, const gchar * url);
gchar * get_license_name (gint license_type);
gchar * get_license_url (gint license_type);



#define MAX_VENDOR_ID_LENGTH 5
#define MAX_VENDOR_LENGTH 100

static const struct
{
    const gchar vendor_id[MAX_VENDOR_LENGTH];
    const gchar vendor[MAX_VENDOR_LENGTH];
}
/* Order is significant. */
NoticeData [] =
{
    /* Notice data sourced from fcfreetype.c */
    {"Bigelow", "Bigelow & Holmes"},
    {"Adobe", "Adobe"},
    {"Bitstream", "Bitstream"},
    {"Monotype", "Monotype Imaging"},
    {"Linotype", "Linotype GmbH"},
    {"LINOTYPE-HELL", "Linotype GmbH"},
    {"IBM", "IBM"},
    {"URW", "URW"},
    {"International Typeface Corporation", "ITC"},
    {"Tiro Typeworks", "Tiro Typeworks"},
    {"XFree86", "XFree86"},
    {"Microsoft", "Microsoft Corporation"},
    {"Omega", "Omega"},
    {"Font21", "Hwan"},
    {"HanYang System", "HanYang Information & Communication"}
};

static const struct
{
    const gchar vendor_id[MAX_VENDOR_ID_LENGTH];
    const gchar vendor[MAX_VENDOR_LENGTH];
}
VendorData[] =
{

    /* Courtesy of Microsoft Typography */
    {"!ETF", "!Exclamachine Type Foundry"},
    {"$pro", "CheapProFonts"},
    {"1ASC", "Ascender Corporation"},
    {"1BOU", "Boutros International"},
    {"2DLT", "2D Typo"},
    {"2REB", "2Rebels"},
    {"39BC", "Finley's Barcode Fonts"},
    {"3ip", "Three Islands Press"},
    {"4FEB", "4th february"},
    {"5PTS", "Five Points Technology"},
    {"918", "RavenType"},
    {"A&S;", "Art&Sign; Studio"},
    {"A2", "A2-Type"},
    {"aaff", "AstroAcademia Font Foundry"},
    {"ABBO", "Arabic Dictionary Lab"},
    {"ABC", "Altek Instruments"},
    {"ABOU", "Aboutype, Inc."},
    {"ACUT", "Acute Type"},
    {"ADBE", "Adobe"},
    {"ADBO", "Adobe"},
    {"ADG", "Apply Design Group"},
    {"AEF", "Altered Ego Fonts"},
    {"AGFA", "Monotype Imaging (replaced by MONO)"},
    {"AID", "Artistic Imposter Design"},
    {"AJPT", "Alan Jay Prescott Typography"},
    {"AKOF", "AKOFAType"},
    {"ALFA", "Alphabets"},
    {"ALPH", "Alphameric Broadcast Solutions Limited"},
    {"ALPN", "Alpona Portal"},
    {"ALS", "Art. Lebedev Studio"},
    {"alte", "Altemus"},
    {"ALTS", "Altsys / Made with Fontographer"},
    {"AMUT", "Kwesi Amuti"},
    {"ANDO", "Osam Ando"},
    {"anty", "Anatoletype"},
    {"AOP", "an Art Of Pengwyn"},
    {"APLY", "Apply Interactive"},
    {"APOS", "Apostrophic Laboratories"},
    {"APPL", "Apple"},
    {"ARBX", "Arabetics"},
    {"ARCH", "Architext"},
    {"ARPH", "Arphic Technology Co."},
    {"ARS", "EN ARS Ltd."},
    {"ArTy", "Archive Type"},
    {"ASL", "Abneil Software Ltd fonts"},
    {"ASSA", "astype"},
    {"ASYM", "Applied Symbols"},
    {"ATEC", "Page Technology Marketing, Inc."},
    {"ATF", "American Type Founders Collection"},
    {"ATF1", "Australian Type Foundry"},
    {"ATFS", "Andrew Tyler's fonts"},
    {"AURE", "Aure Font Design"},
    {"AUTO", "Autodidakt"},
    {"AVFF", "Agustín Varela Font Factory"},
    {"AVP", "Aviation Partners"},
    {"AZLS", "Azalea Software, Inc."},
    {"B&H;", "Bigelow & Holmes"},
    {"BARS", "CIA (BAR CODES) UK"},
    {"BASE", "Baseline Fonts"},
    {"BAT", "BUREAU DES AFFAIRES TYPOGRAPHIQUES"},
    {"BCP", "Barcode Products Ltd"},
    {"BDX", "Studio Christian Bordeaux"},
    {"BERT", "Berthold"},
    {"BITM", "Bitmap Software"},
    {"BITS", "Bitstream"},
    {"bizf", "Bizfonts.com"},
    {"BLAB", "BaseLab"},
    {"BLAH", "Mister Bla's Fontworx"},
    {"BLI", "Blissym Language Institute"},
    {"BOLD", "Bold Monday"},
    {"BORW", "em2 Solutions"},
    {"BOYB", "BoyBeaver Fonts"},
    {"BRDV", "BoardVantage, Inc."},
    {"BREM", "Mark Bremmer"},
    {"BROS", "Michael Brosnan"},
    {"BRTC", "ITSCO - Bar Code Fonts"},
    {"BS", "Barcodesoft"},
    {"BUBU", "BUBULogix"},
    {"BWFW", "B/W Fontworks"},
    {"C&B;", "Coppers & Brasses"},
    {"C&C;", "Carter & Cone"},
    {"C21", "Club 21"},
    {"CAK", "pluginfonts.com"},
    {"CANO", "Canon"},
    {"CASL", "H.W. Caslon & Company Ltd."},
    {"CB", "Christian Büning"},
    {"CBDO", "Borges Lettering & Design"},
    {"CDAC", "Centre for Development of Advanced Computing"},
    {"cdd", "Crazy Diamond Design"},
    {"CDFP", "VT2000 Technical Services"},
    {"CELB", "Celebrity Fontz"},
    {"CF", "Colophon Foundry"},
    {"CFA", "Computer Fonts Australia"},
    {"CFF", "Characters Font Foundry"},
    {"CJCJ", "Creative Juncture"},
    {"CKTP", "CakeType"},
    {"CLM", "Culmus Project"},
    {"CMJK", "Slanted Hall"},
    {"COMM", "Commercial Type"},
    {"CONR", "Connare.com"},
    {"COOL", "Cool Fonts"},
    {"CORD", "corduroy"},
    {"CR8", "CR8 Software Solutions"},
    {"CRRT", "Carrot Type"},
    {"CT", "CastleType"},
    {"CTDL", "China Type Designs Ltd."},
    {"CTL", "Chaitanya Type Library"},
    {"cwwf", "Computers World Wide/AC Capital Funding"},
    {"CYPE", "Club Type"},
    {"DADA", "Dada Studio"},
    {"DAMA", "Dalton Maag Limited"},
    {"DB", "Daniel Bruce"},
    {"DBFF", "DesignBase"},
    {"DD", "Devon DeLapp"},
    {"Deco", "DecoType (replaced by DT)"},
    {"DELV", "Delve Fonts"},
    {"dezc", "Dezcom"},
    {"DFS", "Datascan Font Service Ltd"},
    {"DGL", "Digital Graphic Labs foundry"},
    {"DOM", "Dukom Design"},
    {"DS", "Dainippon Screen Mfg. Co., Inc."},
    {"DSBV", "Datascan bv"},
    {"DSCI", "Design Science Inc."},
    {"DSGN", "DizajnDesign"},
    {"DSKY", "Jacek Dziubinski"},
    {"DSSR", "Dresser Johnson"},
    {"DSST", "Dubina Nikolay"},
    {"DST", "DSType"},
    {"DT", "DecoType"},
    {"DTC", "Digital Typeface Corp."},
    {"DTF", "Dunwich Type Founders"},
    {"DTL", "Dutch Type Library"},
    {"DTPS", "DTP-Software"},
    {"dtpT", "dtpTypes Limited"},
    {"DUXB", "Duxbury Systems, Inc."},
    {"DYNA", "DynaComware"},
    {"EDBI", "edilbiStudio"},
    {"EDGE", "Rivers Edge Corp."},
    {"EF", "Elsner+Flake"},
    {"EFF", "Electronic Font Foundry"},
    {"EFI", "Elfring Fonts Inc."},
    {"EFNT", "E Fonts L.L.C."},
    {"EFWS", "eFilm World"},
    {"EKIO", "Ekioh"},
    {"ELSE", "Elseware"},
    {"EMGR", "Emigre"},
    {"EPSN", "Epson"},
    {"ESIG", "E-Signature"},
    {"ETIO", "Ethiopian Font Foundry"},
    {"EVER", "Evertype"},
    {"FA", "FontArte Type Foundry"},
    {"FAT", "Fatype"},
    {"FBI", "The Font Bureau, Inc."},
    {"FCAB", "The Font Cabinet"},
    {"FCAN", "fontage canada"},
    {"FCTP", "Facetype"},
    {"FDI", "FDI fonts.info"},
    {"FeoN", "Feòrag NìcBhrìde"},
    {"FGOD", "FontGod"},
    {"FJTY", "Frank Jonen - Illustration & Typography"},
    {"FMFO", "Fontmill Foundry"},
    {"FMST", "Formist"},
    {"FNTF", "Fontfoundry"},
    {"FoFa", "FontFabrik"},
    {"FONT", "Font Source"},
    {"FORM", "Formation Type Foundry"},
    {"FOUN", "The Foundry"},
    {"FRML", "formlos"},
    {"FRTH", "Forthcome"},
    {"FS", "Formula Solutions"},
    {"FSE", "Font Source Europe"},
    {"FSI", "FontShop International"},
    {"FSL", "FontSurfer Ltd"},
    {"fsmi", "Fontsmith"},
    {"FTFT", "FontFont"},
    {"FTGD", "Font Garden"},
    {"FTH", "For the Hearts"},
    {"FTN", "Fountain"},
    {"FTPT", "Fontpartners"},
    {"FWKS", "Fontworks"},
    {"FWRE", "Fontware Limited"},
    {"FY", "Fontyou"},
    {"GAF", "Glifo Art Fonts Inc."},
    {"GALA", "Galápagos Design Group, Inc."},
    {"GALO", "Gerald Gallo"},
    {"GARI", "Gary Ritchie"},
    {"GATF", "Greater Albion Typefounders"},
    {"GD", "GD Fonts"},
    {"GF", "GarageFonts"},
    {"GIA", "Georgian Internet Avenue"},
    {"GLCF", "GLC foundry"},
    {"GLYF", "Glyph Systems"},
    {"GNU", "Free Software Foundation, Inc."},
    {"GOAT", "Dingbat Dungeon"},
    {"GOGO", "Fonts-A-Go-Go"},
    {"GOHE", "GoHebrew, division of GoME2.com Inc."},
    {"GOOG", "Google"},
    {"GPI", "Gamma Productions, Inc."},
    {"GRAF", "Grafikarna d.o.o."},
    {"GREY", "Greyletter"},
    {"GRIL", "Grilled cheese"},
    {"GRIM", "Legacy publishing"},
    {"grro", "grafikk RØren"},
    {"GT", "Graphity!"},
    {"GTYP", "G-Type"},
    {"H", "Hurme Design"},
    {"H&FJ;", "Hoefler & Frere-Jones"},
    {"HA", "HoboArt"},
    {"HAD", "Hoffmann Angelic Design"},
    {"HAIL", "Hail Design"},
    {"HanS", "HanStyle"},
    {"HAUS", "TypeHaus"},
    {"HEB", "Sivan Toledo"},
    {"HFJ", "Hoefler & Frere-Jones (replaced by H&FJ;)"},
    {"HIH", "HiH Retrofonts"},
    {"HILL", "Hill Systems"},
    {"HJZ", "Hans J. Zinken"},
    {"HL", "High-Logic"},
    {"HM", "Haiku Monkey"},
    {"HoP", "House of Pretty"},
    {"HOUS", "House Industries"},
    {"HP", "Hewlett-Packard"},
    {"HS", "HermesSOFT Company"},
    {"HT", "Huerta Tipográfica"},
    {"HTF", "The Hoefler Type Foundry, Inc."},
    {"HXTP", "Hexatype"},
    {"HY", "HanYang Information & Communication"},
    {"IBM", "IBM"},
    {"IDAU", "IDAutomation.com, Inc."},
    {"IDEE", "IDEE TYPOGRAFICA"},
    {"IDF", "International Digital Fonts"},
    {"IFF", "Indian Font Factory"},
    {"IKOF", "IKOffice GmbH"},
    {"ILP", "Indigenous Languages Project"},
    {"IMPR", "Impress"},
    {"INGT", "Ingrimayne Type"},
    {"INRA", "INRAY Inc."},
    {"INTR", "Interstitial Entertainment"},
    {"INVC", "Invoice Central"},
    {"INVD", "TYPE INVADERS"},
    {"ISE", "ISE-Aditi Info. Pvt . Ltd."},
    {"ITC", "ITC"},
    {"ITF", "Red Rooster Collection (ITF, Inc.)"},
    {"ITFO", "Indian Type Foundry"},
    {"JABM", "JAB'M Foundry"},
    {"JAF", "Just Another Foundry"},
    {"JAKE", "Jake Tilson Studio"},
    {"JBLT", "JEAN-BAPTISTE LEVÉE TYPOGRAPHY"},
    {"JDB", "Jeff Bensch"},
    {"JF", "Jan Fromm"},
    {"JHA", "Jan Henrik Arnold"},
    {"JHF", "JH Fonts"},
    {"JPTT", "Jeremy Tankard Typography Ltd"},
    {"JWTM", "Type Matters"},
    {"JY", "JIYUKOBO Ltd."},
    {"KATF", "Kingsley/ATF"},
    {"KBNT", "Kombinat-Typefounders"},
    {"KDW", "Kataoka Design Works"},
    {"KF", "Karakta Fonthome"},
    {"KLIM", "Klim Typographic Design"},
    {"KLTF", "Karsten Luecke"},
    {"KNST", "Konst.ru"},
    {"KOP", "Leo Koppelkamm"},
    {"KORK", "Khork OÜ"},
    {"KOVL", "Koval Type Foundry"},
    {"KrKo", "Kreative Software"},
    {"KRND", "Karandash Type & Graphics Foundry"},
    {"KTF", "Kustomtype"},
    {"KUBA", "Kuba Tatarkiewicz"},
    {"LAIT", "la laiterie"},
    {"LANS", "Lanston Type Company"},
    {"LARA", "Larabiefonts"},
    {"LAUD", "Carolina Laudon"},
    {"LAYT", "LAYOUT SARL"},
    {"LEAF", "Interleaf, Inc."},
    {"LETR", "Letraset"},
    {"LFS", "Letters from Sweden"},
    {"LGX", "Logix Research Institute, Inc."},
    {"LHF", "Letterhead Fonts"},
    {"LING", "Linguist's Software"},
    {"LINO", "Linotype GmbH"},
    {"LIVE", "Livedesign"},
    {"LNGU", "LangusteFonts"},
    {"LNTO", "Lineto"},
    {"LORO", "LoRo Productions"},
    {"LP", "LetterPerfect Fonts"},
    {"LT", "Le Typophage"},
    {"LTF", "Liberty Type Foundry"},
    {"Ltrm", "Lettermin type and design"},
    {"LTRX", "Lighttracks"},
    {"LTTR", "LettError"},
    {"LUD", "Ludlow"},
    {"LuFo", "LucasFonts"},
    {"LUSH", "Lush Type"},
    {"LUV", "iLUVfonts"},
    {"MACR", "Macromedia / Made with Fontographer"},
    {"MADT", "MADType"},
    {"MAPS", "Tom Mouat's Map Symbol Fonts"},
    {"MATS", "Match Fonts"},
    {"MC", "Cerajewski Computer Consulting"},
    {"MCKL", "MCKL"},
    {"MCOW", "Mountaincow"},
    {"MDSN", "Moraitis Design"},
    {"MEH", "Steve Mehallo"},
    {"MEIR", "Meir Sadan"},
    {"MESA", "FontMesa,"},
    {"MF", "Magic Fonts"},
    {"MFNT", "Masterfont"},
    {"MG", "Milieu Grotesque"},
    {"MILL", "Millan"},
    {"MJ", "Majus Corporation"},
    {"MJR", "Majur Inc."},
    {"MLBU", "Malibu Dream Designs, LLC"},
    {"MLGC", "Micrologic Software"},
    {"mlss", "Mark Simonson Studio LLC"},
    {"MMFT", "Michel M."},
    {"MMIK", "Monomonnik"},
    {"MNCK", "Mine Creek"},
    {"MODI", "Modular Infotech Private Limited."},
    {"MOHT", "Al Mohtaraf Assaudi Ltd"},
    {"MOJI", "Mojijuku"},
    {"MONB", "Monib"},
    {"MONE", "Meta One Limited"},
    {"MONO", "Monotype Imaging"},
    {"MOON", "Moonlight Type and Technolog"},
    {"MOTA", "Mota Italic"},
    {"MRSW", "Morisawa & Company, Ltd."},
    {"MRV", "Morovia Corporation"},
    {"MS", "Microsoft Corp."},
    {"MSCH", "Guitar-Injection"},
    {"MSCR", "Majus Corporation"},
    {"MSE", "MSE-iT"},
    {"MT", "Monotype Imaging (replaced by MONO)"},
    {"MTF", "Miss Tiina Fonts"},
    {"MTY", "Motoya Co. ,LTD."},
    {"MUTF", "Murasu Systems Sdn. Bhd"},
    {"MVB", "MVB Fonts"},
    {"MVTP", "Mauve Type"},
    {"MVty", "MV Typo"},
    {"MYFO", "MyFonts.com"},
    {"NB", "No Bodoni Typography"},
    {"ncnd", "&cond;"},
    {"NDCT", "Neufville Digital Corporatype"},
    {"NDTC", "Neufville Digital"},
    {"NEC", "NEC Corporation"},
    {"NEWL", "Newlyn"},
    {"NICK", "Nick's Fonts"},
    {"NIS", "NIS Corporation"},
    {"NORF", "Norfok Incredible Font Design"},
    {"NOVA", "NOVATYPE"},
    {"NP", "Nipponia"},
    {"OHG", "Our House Graphic Design"},
    {"OKAY", "Okay Type Foundry"},
    {"OPTM", "Optimo"},
    {"OPTO", "Opto"},
    {"ORBI", "Orbit Enterprises, Inc."},
    {"ORK1", "Ork1"},
    {"OURT", "Ourtype"},
    {"P22", "P22 Inc."},
    {"PARA", "ParaType Inc."},
    {"PD", "Pangea design"},
    {"PDWX", "Parsons Design Workx"},
    {"PECI", "Pecita"},
    {"PF", "Phil's Fonts, Inc."},
    {"PIXL", "Pixilate"},
    {"PKDD", "Philip Kelly Digital Design"},
    {"PLAT", "PLATINUM technology"},
    {"PRFS", "Production First Software"},
    {"PRGR", "Paragraph"},
    {"PROD", "Production Type"},
    {"PRTF", "Process Type Foundry"},
    {"PSIS", "PhotoShopIsland.com"},
    {"PSY", "PSY/OPS"},
    {"PT", "Playtype APS"},
    {"PTF", "Porchez Typofonderie"},
    {"PTMI", "Page Technology Marketing, Inc."},
    {"PTYP", "preussTYPE"},
    {"PYRS", "PYRS   Fontlab Ltd. / Made with FontLab"},
    {"QMSI", "QMS/Imagen"},
    {"QRAT", "Quadrat Communications"},
    {"READ", "ReadyType"},
    {"REAL", "Underware"},
    {"RES", "Resultat"},
    {"RJPS", "Reall Graphics"},
    {"RKFN", "R K Fonts"},
    {"RL", "Ruben Holthuijsen"},
    {"RLTF", "Rebeletter Studios"},
    {"RMU", "RMU TypeDesign"},
    {"robo", "Buro Petr van Blokland"},
    {"RRT", "Red Rooster Collection (ITF, Inc.)"},
    {"RSJ", "RSJ Software"},
    {"RST", "Rosetta"},
    {"RUDY", "RudynFluffy"},
    {"RYOB", "Ryobi Limited"},
    {"SAND", "Sandoll"},
    {"SAPL", "Fonderie sans plomb"},
    {"SATY", "Samuelstype Design AB"},
    {"SAX", "s.a.x. Software gmbh"},
    {"SbB", "Sketchbook B"},
    {"SBT", "SelfBuild Type Foundry"},
    {"SCTO", "Schick Toikka"},
    {"Sean", "The FontSite"},
    {"SFS", "Sarumadhu Services Pvt. Ltd."},
    {"SFUN", "Software Union"},
    {"SG", "Scooter Graphics"},
    {"SHAM", "ShamFonts / Shamrock Int."},
    {"SHFT", "Shift"},
    {"SHOT", "Shotype"},
    {"SHUB", "The Software Hub"},
    {"SIG", "vLetter, Inc"},
    {"SIL", "SIL International (SIL)"},
    {"SIT", "Summit Information Technologies Pvt.Ltd,"},
    {"SKP", "Essqué Productions"},
    {"skz", "Celtic Lady's Fonts"},
    {"SL", "Silesian Letters"},
    {"SN", "SourceNet"},
    {"SOHO", "Soft Horizons"},
    {"SOS", "Standing Ovations Software"},
    {"STC", "Sorkin Type Co"},
    {"STF", "Brian Sooy & Co + Sooy Type Foundry"},
    {"Stor", "Storm Type Foundry"},
    {"STYP", "Stone Type Foundry"},
    {"SUNW", "sunwalk fontworks"},
    {"SVTD", "Synthview"},
    {"SWFT", "Swfte International"},
    {"SWTY", "Swiss Typefaces"},
    {"SXRA", "Page42 Type Foundry"},
    {"SYDA", "Shree Muktananda Ashram"},
    {"SYN", "SynFonts"},
    {"SYRC", "Syriac Computing Institute"},
    {"TBFF", "TrueBlue Font Foundry"},
    {"TC", "Typeco"},
    {"TCH", "Darryl Cook"},
    {"TD", "Typedepot"},
    {"TDR", "Tansin A. Darcos & Co."},
    {"TERM", "Terminal Design, Inc."},
    {"TF", "Treacyfaces / Headliners"},
    {"TF3D", "TattooFont3D"},
    {"TFND", "Typefounding"},
    {"THIN", "Thinstroke Design LLC"},
    {"TILD", "Tilde, SIA"},
    {"TIMO", "Tim Romano"},
    {"TIMR", "Tim Rolands"},
    {"TIPO", "Tipo"},
    {"TIRO", "Tiro Typeworks"},
    {"TJS", "Typejockeys"},
    {"TLIN", "Teeline Fonts"},
    {"TMF", "The MicroFoundry"},
    {"TMT", "TypeMyType Comm. V."},
    {"TNTY", "tntypography"},
    {"TOPP", "Toppan Printing Co., Ltd."},
    {"TPDP", "Type Department"},
    {"TPMA", "typoma"},
    {"TPSP", "Type Supply"},
    {"TPTC", "Test Pilot Collective"},
    {"TPTQ", "Typotheque"},
    {"TR", "Type Revivals"},
    {"TRAF", "Traffictype"},
    {"TREE", "Treeflow"},
    {"TS", "TamilSoft Corporation"},
    {"TSPC", "Typespec Ltd"},
    {"TSTY", "Torleiv Georg Sverdrup"},
    {"TT", "TypeTogether"},
    {"TTG", "Twardoch Typography"},
    {"TTY", "Tipotype"},
    {"TYCU", "TypeCulture"},
    {"TYFR", "typographies.fr"},
    {"TYME", "type me! Font Foundry"},
    {"TYPA", "Typadelic"},
    {"TYPE", "Type Associates Pty Ltd"},
    {"TYPO", "Typodermic"},
    {"TYPR", "Type Project"},
    {"TYRE", "typerepublic"},
    {"UA", "UnAuthorized Type"},
    {"UNDT", "ÜNDT"},
    {"URW", "URW++"},
    {"UT", "Unitype Inc"},
    {"VINT", "Vinterstille"},
    {"VKP", "Vijay K. Patel"},
    {"VLKF", "Visualogik Technology & Design"},
    {"VLNL", "VetteLetters.nl"},
    {"VMT", "VMType"},
    {"VOG", "Martin Vogel"},
    {"VROM", "Vladimir Romanov"},
    {"VS", "VorSicht GmbH"},
    {"VT", "VISUALTYPE SRL"},
    {"VTF", "Velvetyne Type Foundry"},
    {"WASP", "Wasp Barcode Technologies"},
    {"WILL", "Willerstorfer Font Foundry"},
    {"WL", "Writ Large Fonts"},
    {"WM", "Webmakers India"},
    {"XFC", "Xerox Font Services"},
    {"XOTH", "Xoth Morello"},
    {"Y&Y;", "Y&Y;, Inc."},
    {"YDS", "Yellow Design Studio"},
    {"YN", "Yanone"},
    {"YOFF", "Your Own Font Foundry"},
    {"YOKO", "Yokokaku"},
    {"YOUR", "YourFonts.com"},
    {"ZANE", "Unrender"},
    {"ZeGr", "Zebra Font Factory"},
    {"zeta", "Tangram Studio"},
    {"ZSFT", "Zsoft"},


    /* Various Sources */
    {"ACG", "Monotype Imaging"},
    {"B?", "Bigelow & Holmes"},
    {"FJ", "Fujitsu"},
    {"RICO", "Ricoh"},

};

#define NOTICE_ENTRIES G_N_ELEMENTS(NoticeData)
#define VENDOR_ENTRIES G_N_ELEMENTS(VendorData)

gchar * get_vendor_from_notice(const gchar *notice);
gchar * get_vendor_from_vendor_id(const gchar vendor[MAX_VENDOR_ID_LENGTH]);


G_END_DECLS

#endif
