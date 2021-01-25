/* font-manager-font-model.h
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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

#ifndef __FONT_MANAGER_FONT_MODEL_H__
#define __FONT_MANAGER_FONT_MODEL_H__

#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>
#include <json-glib/json-glib.h>

#include "font-manager-font.h"
#include "font-manager-family.h"

G_BEGIN_DECLS

#define FONT_MANAGER_TYPE_FONT_MODEL (font_manager_font_model_get_type())
G_DECLARE_FINAL_TYPE(FontManagerFontModel, font_manager_font_model, FONT_MANAGER, FONT_MODEL, GObject)

/**
 * FontManagerFontModelColumn:
 * @FONT_MANAGER_FONT_MODEL_OBJECT:         #FontManagerFont
 * @FONT_MANAGER_FONT_MODEL_NAME:           Object name
 * @FONT_MANAGER_FONT_MODEL_DESCRIPTION:    Font description
 * @FONT_MANAGER_FONT_MODEL_COUNT:          Number of variations for family objects
 * @FONT_MANAGER_FONT_MODEL_N_COLUMNS:      Number of columns in this model
 *
 * Index of available columns in #FontManagerFontModel.
 */
typedef enum
{
    FONT_MANAGER_FONT_MODEL_OBJECT,
    FONT_MANAGER_FONT_MODEL_NAME,
    FONT_MANAGER_FONT_MODEL_DESCRIPTION,
    FONT_MANAGER_FONT_MODEL_COUNT,
    FONT_MANAGER_FONT_MODEL_N_COLUMNS
}
FontManagerFontModelColumn;

GType font_manager_font_model_column_get_type (void) G_GNUC_CONST;
#define FONT_MANAGER_TYPE_FONT_MODEL_COLUMN (font_manager_font_model_column_get_type ())

FontManagerFontModel * font_manager_font_model_new (void);

G_END_DECLS

#endif /* __FONT_MANAGER_FONT_MODEL_H__ */

