/* unicode-block-model.c
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

#include <glib/gi18n-lib.h>

#include "unicode.h"
#include "unicode-blocks.h"
#include "unicode-chapters-model.h"


struct _UnicodeBlockModel
{
    GtkListStore parent_instance;
};

static void unicode_block_model_interface_init (UnicodeChaptersModelInterface *iface);

G_DEFINE_TYPE_WITH_CODE(UnicodeBlockModel, unicode_block_model, GTK_TYPE_LIST_STORE,
    G_IMPLEMENT_INTERFACE(UNICODE_TYPE_CHAPTERS_MODEL, unicode_block_model_interface_init))


static void
unicode_block_model_class_init (UnicodeBlockModelClass *klass)
{
    return;
}

static void
unicode_block_model_init (UnicodeBlockModel *self)
{
    //unicode_intl_ensure_initialized ();

    GtkListStore *store = GTK_LIST_STORE(self);
    GtkTreeIter iter;
    guint i;
    GType types[] = {
        G_TYPE_STRING,
        G_TYPE_STRING,
        G_TYPE_POINTER
    };

    gtk_list_store_set_column_types(store, G_N_ELEMENTS(types), types);
    gtk_list_store_append(store, &iter);
    gtk_list_store_set(store, &iter,
                        UNICODE_CHAPTERS_MODEL_COLUMN_ID, "All",
                        UNICODE_CHAPTERS_MODEL_COLUMN_LABEL, _("All"),
                        UNICODE_CHAPTERS_MODEL_COLUMN_USER_DATA, NULL,
                        -1);

    for (i = 0;  i < G_N_ELEMENTS(unicode_blocks); i++) {
        const gchar *block_name = unicode_blocks_strings + unicode_blocks[i].block_name_index;
        gtk_list_store_append(store, &iter);
        gtk_list_store_set(store, &iter,
                            UNICODE_CHAPTERS_MODEL_COLUMN_ID, block_name,
                            UNICODE_CHAPTERS_MODEL_COLUMN_LABEL, _(block_name),
                            UNICODE_CHAPTERS_MODEL_COLUMN_USER_DATA, unicode_blocks + i,
                            -1);
    }

    return;
}

/* XXX linear search */
static gboolean
character_to_iter (UnicodeBlockModel *self, gunichar wc, GtkTreeIter *iter)
{
    GtkTreeModel *model = GTK_TREE_MODEL(self);
    GtkTreeIter _iter;

    if (wc > UNICHAR_MAX)
        return FALSE;

    /* skip "All" block */
    if (!gtk_tree_model_get_iter_first(model, &_iter))
        return FALSE;

    while (gtk_tree_model_iter_next(model, &_iter)) {
        UnicodeBlock *unicode_block;
        gtk_tree_model_get(model, &_iter, UNICODE_CHAPTERS_MODEL_COLUMN_USER_DATA, &unicode_block, -1);
        if (wc >= unicode_block->start && wc <= unicode_block->end) {
            *iter = _iter;
            return TRUE;
        }
    }

    /* "All" is the last resort */
    return gtk_tree_model_get_iter_first(model, iter);
}

static UnicodeCodepointList *
get_codepoint_list (UnicodeBlockModel *self, GtkTreeIter *iter)
{
    GtkTreeModel *model = GTK_TREE_MODEL(self);
    UnicodeBlock *unicode_block;

    gtk_tree_model_get(model, iter, UNICODE_CHAPTERS_MODEL_COLUMN_USER_DATA, &unicode_block, -1);

    /* special "All" block */
    if (unicode_block == NULL)
        return UNICODE_CODEPOINT_LIST(unicode_block_codepoint_list_new(0, UNICHAR_MAX));

    return UNICODE_CODEPOINT_LIST(unicode_block_codepoint_list_new(unicode_block->start, unicode_block->end));
}

static void
unicode_block_model_interface_init (UnicodeChaptersModelInterface *iface)
{
    iface->title = _("Unicode Block");
    iface->character_to_iter = character_to_iter;
    iface->get_codepoint_list = get_codepoint_list;
    return;
}

UnicodeBlockModel *
unicode_block_model_new (void)
{
  return UNICODE_BLOCK_MODEL(g_object_new(unicode_block_model_get_type(), NULL));
}
