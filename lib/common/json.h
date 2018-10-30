/* json.h
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

#ifndef __JSON_H__
#define __JSON_H__

#include <glib.h>
#include <json-glib/json-glib.h>

G_BEGIN_DECLS

void set_json_error (JsonObject *json_obj, int err_code, const gchar *err_msg);
gint compare_json_int_member (const gchar *member_name, JsonObject  *a, JsonObject  *b);
gint compare_json_string_member (const gchar *member_name, JsonObject  *a, JsonObject  *b);
gint compare_json_font_node (JsonNode *node_a, JsonNode *node_b);
gchar * print_json_array (JsonArray *json_arr, gboolean pretty);
gchar * print_json_object(JsonObject *json_obj, gboolean pretty);
gboolean write_json_file (JsonNode *root, const gchar *filepath);
JsonNode * load_json_file (const gchar *filepath);
JsonArray * str_list_to_json_array (GList *slist);

G_END_DECLS

#endif /* __JSON_H__ */

