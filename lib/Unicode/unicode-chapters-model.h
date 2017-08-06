/* unicode-chapters-model.h
 *
 * Originally a part of Gucharmap
 *
 * Copyright © 2017 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
 * Copyright © 2007 Christian Persch
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02110-1301  USA
 */

#ifndef __UNICODE_CHAPTERS_MODEL__
#define __UNICODE_CHAPTERS_MODEL__

#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>

#include "unicode-codepoint-list.h"

G_BEGIN_DECLS

#define UNICODE_TYPE_CHAPTERS_MODEL (unicode_chapters_model_get_type())
G_DECLARE_INTERFACE(UnicodeChaptersModel, unicode_chapters_model, UNICODE, CHAPTERS_MODEL, GObject)

struct _UnicodeChaptersModelInterface
{
    GTypeInterface  parent_iface;

    const gchar *title;

    gboolean (* character_to_iter) (UnicodeChaptersModel *self, gunichar ch, GtkTreeIter *iter);
    UnicodeCodepointList * (* get_codepoint_list) (UnicodeChaptersModel *self, GtkTreeIter *iter);
};


enum
{
    UNICODE_CHAPTERS_MODEL_COLUMN_ID,
    UNICODE_CHAPTERS_MODEL_COLUMN_LABEL,
    UNICODE_CHAPTERS_MODEL_COLUMN_USER_DATA,
    UNICODE_CHAPTERS_MODEL_COLUMN_NUM_COLUMNS
};

const gchar * unicode_chapters_model_get_title (UnicodeChaptersModel *self);
gboolean unicode_chapters_model_character_to_iter (UnicodeChaptersModel *self, gunichar ch, GtkTreeIter *iter);
gboolean unicode_chapters_model_id_to_iter (UnicodeChaptersModel *self, const gchar *id, GtkTreeIter *iter);
UnicodeCodepointList * unicode_chapters_model_get_codepoint_list (UnicodeChaptersModel *self, GtkTreeIter *iter);

G_END_DECLS

#endif /* #ifndef __UNICODE_CHAPTERS_MODEL__ */
