/* font-manager-json.c
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

#include "font-manager-json.h"

/**
 * SECTION: font-manager-json
 * @short_description: JSON related utility functions
 * @title: JSON Utility Functions
 * @include: font-manager-json.h
 *
 * Helper functions to make working with JSON data easier.
 */

/**
 * font_manager_write_json_file:
 * @root:               #JsonNode to use as root
 * @filepath:           filepath to write @root to
 * @pretty:             whether the generated string should be pretty printed
 *
 * Returns:             %TRUE if file was written successfully
 */
gboolean
font_manager_write_json_file (JsonNode *root, const gchar *filepath, gboolean pretty)
{
    g_return_val_if_fail(root != NULL && filepath != NULL, FALSE);

    g_autoptr(JsonGenerator) generator = json_generator_new();
    json_generator_set_root(generator, root);
    json_generator_set_pretty(generator, pretty);
    json_generator_set_indent(generator, 4);
    return json_generator_to_file(generator, filepath, NULL);
}

/**
 * font_manager_load_json_file:
 * @filepath:           filepath to a valid json file
 *
 * Returns: (transfer full) (nullable): #JsonNode or %NULL if file failed to load
 */
JsonNode *
font_manager_load_json_file (const gchar *filepath)
{
    g_return_val_if_fail(filepath != NULL, NULL);

    g_autoptr(JsonParser) parser = json_parser_new();
    JsonNode *root = NULL;
    if (json_parser_load_from_file(parser, filepath, NULL))
        root = json_parser_get_root(parser);
    return root ? json_node_copy(root) : NULL;
}

/**
 * font_manager_compare_json_int_member:
 * @member_name:        name of member to compare
 * @a:                  #JsonObject
 * @b:                  #JsonObject
 *
 * Returns:             An integer less than, equal to, or greater than zero
 *                      if int member from a is <, == or > than int member from b
 */
gint
font_manager_compare_json_int_member (const gchar *member_name,
                                      JsonObject *a,
                                      JsonObject *b)
{
    g_return_val_if_fail(member_name != NULL, 0);
    g_return_val_if_fail(a != NULL && b != NULL, 0);
    g_return_val_if_fail(json_object_has_member(a, member_name), 0);
    g_return_val_if_fail(json_object_has_member(b, member_name), 0);
    gint int_a = json_object_get_int_member(a, member_name);
    gint int_b = json_object_get_int_member(b, member_name);
    return int_a == int_b ? 0 : int_a - int_b;
}

/**
 * font_manager_compare_json_string_member:
 * @member_name:        name of member to compare
 * @a:                  #JsonObject
 * @b:                  #JsonObject
 *
 * Returns:             An integer less than, equal to, or greater than zero
 *                      if string member from a is <, == or > than string member from b
 */
gint
font_manager_compare_json_string_member (const gchar *member_name,
                                         JsonObject *a,
                                         JsonObject *b)
{
    g_return_val_if_fail(member_name != NULL, 0);
    g_return_val_if_fail(a != NULL && b != NULL, 0);
    g_return_val_if_fail(json_object_has_member(a, member_name), 0);
    g_return_val_if_fail(json_object_has_member(b, member_name), 0);
    const gchar *str_a = json_object_get_string_member(a, member_name);
    const gchar *str_b = json_object_get_string_member(b, member_name);
    g_return_val_if_fail(str_a != NULL && str_b != NULL, 0);
    return font_manager_natural_sort(str_a, str_b);
}

/* Order matters */
static const gchar *STYLE_PROPS[3] = {
    "width",
    "weight",
    "slant"
};

/**
 * font_manager_compare_json_font_node:
 * @node_a:             #JsonNode containing a font description
 * @node_b:             #JsonNode containing a font description
 *
 * Returns:             An integer less than, equal to, or greater than zero,
 *                      if font a is <, == or > than font b
 */
gint
font_manager_compare_json_font_node (JsonNode *node_a, JsonNode *node_b)
{
    g_return_val_if_fail(JSON_NODE_HOLDS_OBJECT(node_a), 0);
    g_return_val_if_fail(JSON_NODE_HOLDS_OBJECT(node_b), 0);
    JsonObject *a = json_node_get_object(node_a);
    JsonObject *b = json_node_get_object(node_b);
    g_return_val_if_fail(a != NULL && b != NULL, 0);
    gint i, result = 0;
    /* Attempt to sort based on style properties */
    for (i = 0; i < (gint) G_N_ELEMENTS(STYLE_PROPS); i++) {
        result = font_manager_compare_json_int_member(STYLE_PROPS[i], a, b);
        if (result != 0)
            return result;
    }
    /* All else being equal sort alphabetically based on style */
    return font_manager_compare_json_string_member("style", a, b);
}

/**
 * font_manager_str_list_to_json_array:
 * @slist: (element-type utf8): a #GList containing only strings
 *
 * Returns: (transfer full): A newly created #JsonArray
 */
JsonArray *
font_manager_str_list_to_json_array (GList *slist)
{
    GList *iter;
    JsonArray *result = json_array_new();
    for (iter = slist; iter != NULL; iter = iter->next)
        json_array_add_string_element(result, iter->data);
    return result;
}

/**
 * font_manager_print_json_array:
 * @json_arr:           a #JsonArray
 * @pretty:             whether the output should be prettyfied for printing
 *
 * Convenience function which simply wraps json_to_string to allow direct
 * conversion of a #JsonArray to string. Equivalent to creating a #JsonNode,
 * then setting the given array inside the node and calling json_to_string
 * on the node.
 *
 * Returns: (transfer full): A newly allocated buffer holding a JSON data stream.
 * The returned string should be freed with g_free() when no longer needed.
 */
gchar *
font_manager_print_json_array (JsonArray *json_arr, gboolean pretty)
{
    g_return_val_if_fail(json_arr != NULL, NULL);
    g_autoptr(JsonNode) n = json_node_new(JSON_NODE_ARRAY);
    json_node_set_array(n, json_arr);
    gchar *res = (gchar *) json_to_string(n, pretty);
    json_node_set_array(n, NULL);
    return res;
}

/**
 * font_manager_print_json_object:
 * @json_obj:           a #JsonObject
 * @pretty:             whether the output should be prettyfied for printing
 *
 * Convenience function which simply wraps json_to_string to allow direct
 * conversion of a #JsonObject to string. Equivalent to creating a #JsonNode,
 * then setting the given object inside the node and calling json_to_string
 * on the node.
 *
 * Returns: (transfer full): A newly allocated buffer holding a JSON data stream.
 * The returned string should be freed with g_free() when no longer needed.
 */
gchar *
font_manager_print_json_object (JsonObject *json_obj, gboolean pretty)
{
    g_return_val_if_fail(json_obj != NULL, NULL);
    g_autoptr(JsonNode) n = json_node_new(JSON_NODE_OBJECT);
    json_node_set_object(n, json_obj);
    gchar *res = (gchar *) json_to_string(n, pretty);
    json_node_set_object(n, NULL);
    return res;
}
