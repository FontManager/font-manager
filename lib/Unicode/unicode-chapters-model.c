/* unicode-chapters-model.c
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

#include <glib.h>

#include "unicode.h"


#include "unicode-chapters-model.h"


G_DEFINE_INTERFACE(UnicodeChaptersModel, unicode_chapters_model, G_TYPE_OBJECT)


static void
unicode_chapters_model_default_init (UnicodeChaptersModelInterface *iface)
{
    return;
}

/**
 * unicode_chapters_model_get_title:
 * @self: a #UnicodeChaptersModel
 *
 * Return value: (transfer none): the title for this model or %NULL if not set.
 */
const gchar *
unicode_chapters_model_get_title (UnicodeChaptersModel *self)
{
    g_return_val_if_fail(UNICODE_IS_CHAPTERS_MODEL(self), NULL);
    UnicodeChaptersModelInterface *iface = UNICODE_CHAPTERS_MODEL_GET_IFACE(self);
    g_return_val_if_fail(iface->title != NULL, NULL);
    return iface->title;
}

/**
 * unicode_chapters_model_get_codepoint_list:
 * @self: a #UnicodeChaptersModel
 * @iter: a #GtkTreeIter
 *
 * Creates a new #UnicodeCodepointList representing the characters in the
 * current chapter.
 *
 * Return value: (transfer full): the newly-created #UnicodeCodepointList,
 * or NULL if there is no category selected. The caller should release the
 * result with g_object_unref() when finished.
 */
UnicodeCodepointList *
unicode_chapters_model_get_codepoint_list (UnicodeChaptersModel *self, GtkTreeIter *iter)
{
    g_return_val_if_fail(UNICODE_IS_CHAPTERS_MODEL(self), NULL);
    UnicodeChaptersModelInterface *iface = UNICODE_CHAPTERS_MODEL_GET_IFACE(self);
    g_return_val_if_fail(iface->get_codepoint_list != NULL, UNICODE_CODEPOINT_LIST(unicode_block_codepoint_list_new(0, UNICHAR_MAX)));
    return iface->get_codepoint_list(self, iter);
}

/**
 * unicode_chapters_model_character_to_iter:
 * @self: a #UnicodeChaptersModel
 * @ch: a character
 * @iter: (out): a #GtkTreeIter
 *
 * Return value: %TRUE on success, %FALSE on failure.
 **/
gboolean
unicode_chapters_model_character_to_iter (UnicodeChaptersModel *self, gunichar ch, GtkTreeIter *iter)
{
    g_return_val_if_fail(UNICODE_IS_CHAPTERS_MODEL(self), FALSE);
    UnicodeChaptersModelInterface *iface = UNICODE_CHAPTERS_MODEL_GET_IFACE(self);
    g_return_val_if_fail(iface->character_to_iter != NULL, FALSE);
    return iface->character_to_iter(self, ch, iter);
}

/**
 * unicode_chapters_model_id_to_iter:
 * @self: a #UnicodeChaptersModel
 * @id: name
 * @iter: (out): a #GtkTreeIter
 *
 * Return value: %TRUE on success, %FALSE on failure.
 */
gboolean
unicode_chapters_model_id_to_iter (UnicodeChaptersModel *self, const gchar *id, GtkTreeIter *iter)
{
    g_return_val_if_fail(UNICODE_IS_CHAPTERS_MODEL(self), FALSE);
    g_return_val_if_fail(id != NULL, FALSE);

    int match = -1;
    gchar *str;
    GtkTreeIter _iter;

    if (gtk_tree_model_get_iter_first(GTK_TREE_MODEL(self), &_iter)) {

        do {
            gtk_tree_model_get(GTK_TREE_MODEL(self), &_iter, UNICODE_CHAPTERS_MODEL_COLUMN_ID, &str, -1);
            match = g_strcmp0(id, str);
            g_free(str);
            if (match == 0) {
                *iter = _iter;
                break;
            }
        } while (gtk_tree_model_iter_next(GTK_TREE_MODEL(self), &_iter));

    }

    return (match == 0);
}
