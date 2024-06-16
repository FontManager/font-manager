/* font-manager-json.h
 *
 * Copyright (C) 2009-2022 Jerry Casiano
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

#include <glib.h>
#include <json-glib/json-glib.h>

#include "font-manager-utils.h"

gint font_manager_compare_json_int_member (const gchar *member_name,
                                           JsonObject  *a,
                                           JsonObject  *b);

gint font_manager_compare_json_string_member (const gchar *member_name,
                                              JsonObject  *a,
                                              JsonObject  *b);

gint font_manager_compare_json_font_node (JsonNode *node_a,
                                          JsonNode *node_b);

gchar * font_manager_print_json_array (JsonArray *json_arr,
                                       gboolean   pretty);

gchar * font_manager_print_json_object(JsonObject *json_obj,
                                       gboolean    pretty);

gboolean font_manager_write_json_file (JsonNode    *root,
                                       const gchar *filepath,
                                       gboolean     pretty);

JsonNode * font_manager_load_json_file (const gchar *filepath);
JsonArray * font_manager_str_list_to_json_array (GList *slist);

