/* unicode-script-model.c
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
#include <gtk/gtk.h>

#include "unicode.h"


struct _UnicodeScriptModel
{
    GtkListStore parent_instance;
};

static void unicode_script_model_interface_init (UnicodeChaptersModelInterface *iface);

G_DEFINE_TYPE_WITH_CODE(UnicodeScriptModel, unicode_script_model, GTK_TYPE_LIST_STORE,
    G_IMPLEMENT_INTERFACE(UNICODE_TYPE_CHAPTERS_MODEL, unicode_script_model_interface_init))


static void
unicode_script_model_class_init (UnicodeScriptModelClass *klass)
{
    return;
}

static void
unicode_script_model_init (UnicodeScriptModel *self)
{
    //unicode_intl_ensure_initialized();

    GtkListStore *store = GTK_LIST_STORE(self);
    const gchar **unicode_scripts;
    GtkTreeIter iter;
    guint i;
    GType types[] = {
        G_TYPE_STRING,
        G_TYPE_STRING,
    };

    gtk_list_store_set_column_types(store, G_N_ELEMENTS(types), types);

    unicode_scripts = unicode_list_scripts();
    for (i = 0;  unicode_scripts[i]; i++) {
        gtk_list_store_append (store, &iter);
        gtk_list_store_set(store, &iter,
                            UNICODE_CHAPTERS_MODEL_COLUMN_ID, unicode_scripts[i],
                            UNICODE_CHAPTERS_MODEL_COLUMN_LABEL, _(unicode_scripts[i]),
                            -1);
    }
    g_free(unicode_scripts);

    gtk_tree_sortable_set_sort_column_id(GTK_TREE_SORTABLE(self),
                                        UNICODE_CHAPTERS_MODEL_COLUMN_LABEL,
                                        GTK_SORT_ASCENDING);
}

static gboolean
character_to_iter (UnicodeChaptersModel *self, gunichar wc, GtkTreeIter *iter)
{
    const char *script = unicode_get_script_for_char(wc);

    if (script == NULL)
        return FALSE;

    return unicode_chapters_model_id_to_iter(self, script, iter);
}

static UnicodeCodepointList *
get_codepoint_list (UnicodeScriptModel *self, GtkTreeIter *iter)
{
    GtkTreeModel *model = GTK_TREE_MODEL(self);
    UnicodeCodepointList *_list;
    gchar *script_untranslated;

    gtk_tree_model_get(model, iter, UNICODE_CHAPTERS_MODEL_COLUMN_ID, &script_untranslated, -1);

    _list = unicode_script_codepoint_list_new();
    if (!unicode_script_codepoint_list_set_script (UNICODE_SCRIPT_CODEPOINT_LIST(_list), script_untranslated)) {
        g_error ("unicode_script_codepoint_list_set_script (\"%s\") failed\n", script_untranslated);
        /* not reached */
        return NULL;
    }

    g_free(script_untranslated);
    return UNICODE_CODEPOINT_LIST(_list);
}

static void
unicode_script_model_interface_init (UnicodeChaptersModelInterface *iface)
{
    iface->title = _("Script");
    iface->character_to_iter = character_to_iter;
    iface->get_codepoint_list = get_codepoint_list;
    return;
}

UnicodeScriptModel *
unicode_script_model_new (void)
{
    return UNICODE_SCRIPT_MODEL(g_object_new(unicode_script_model_get_type(), NULL));
}
