/* font-manager-utils.c
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

#include "font-manager-utils.h"

/**
 * SECTION: font-manager-utils
 * @title: Utility Functions
 * @short_description: General purpose utility functions
 * @include: font-manager-utils.h
 */

static const gchar *POSSIBLE_SCHEMA_DIRS[] = {
    PREFIX"/share/glib-2.0/schemas",
#ifdef NOT_REPRODUCIBLE
    SRCDIR"/data"
#endif
};

static GSList *
get_possible_schema_dirs (void)
{
    GSList *slist = NULL;
    gchar *user_schema_dir = g_build_filename(g_get_user_data_dir(), "glib-2.0", "schemas", NULL);
    for (gint i = 0; i < (gint) G_N_ELEMENTS(POSSIBLE_SCHEMA_DIRS); i++) {
        slist = g_slist_append(slist, g_strdup(POSSIBLE_SCHEMA_DIRS[i]));
        if (i == 0)
          slist = g_slist_append(slist, user_schema_dir);
    }
    return slist;
}

/**
 * font_manager_setup_i18n:
 *
 * Initializes gettext translations
 */
void
font_manager_setup_i18n ()
{
    setlocale(LC_ALL, "");
    bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR);
    bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    textdomain(GETTEXT_PACKAGE);
    return;
}

/**
 * font_manager_print_os_info:
 *
 * Print OS name and version.
 */
void
font_manager_print_os_info ()
{
    g_autofree gchar *pretty_name = g_get_os_info(G_OS_INFO_KEY_PRETTY_NAME);
    if (pretty_name)
        g_debug("%s", pretty_name);
    else {
        g_autofree gchar *name = g_get_os_info(G_OS_INFO_KEY_NAME);
        g_autofree gchar *version = g_get_os_info(G_OS_INFO_KEY_VERSION);
        g_debug("%s %s", name, version ? version : "");
    }
    g_debug("%s", setlocale(LC_ALL, NULL));
    return;
}

/**
 * font_manager_print_library_versions:
 *
 * Logs the versions of libraries in use for debugging purposes.
 */
void
font_manager_print_library_versions ()
{
    g_debug("Fontconfig version : %i", FcGetVersion());

    g_debug("Freetype version (compile-time) : %i.%i.%i", FREETYPE_MAJOR,
                                                          FREETYPE_MINOR,
                                                          FREETYPE_PATCH);
    FT_Library library;
    FT_Error ft_error = FT_Init_FreeType(&library);
    if (!ft_error) {
        FT_Int major, minor, patch;
        FT_Library_Version(library, &major, &minor, &patch);
        g_debug("Freetype version (run-time) : %i.%i.%i", major, minor, patch);
    }
    FT_Done_FreeType(library);

    g_debug("Harfbuzz version (compile-time) : %s", HB_VERSION_STRING);
    g_debug("Harfbuzz version (run-time) : %s", hb_version_string());

    g_debug("JSON-GLib version : %s", JSON_VERSION_S);

    g_debug("Pango version (compile-time) : %s", PANGO_VERSION_STRING);
    g_debug("Pango version (run-time) : %i", pango_version());

    g_debug("libxml2 version : %s", LIBXML_VERSION_STRING);

    g_debug("SQLite version (compile-time) : %s", SQLITE_VERSION);
    g_debug("SQLite version (run-time) : %s", sqlite3_libversion());

    g_debug("GLib version (compile-time) : %i.%i.%i", GLIB_MAJOR_VERSION,
                                                      GLIB_MINOR_VERSION,
                                                      GLIB_MICRO_VERSION);
    g_debug("GLib version (run-time) : %i.%i.%i", glib_major_version,
                                                  glib_minor_version,
                                                  glib_micro_version);

    g_debug("GTK version (compile-time) : %i.%i.%i", GTK_MAJOR_VERSION,
                                                     GTK_MINOR_VERSION,
                                                     GTK_MICRO_VERSION);
    g_debug("GTK version (run-time) : %i.%i.%i", gtk_get_major_version(),
                                                 gtk_get_minor_version(),
                                                 gtk_get_micro_version());

    return;
}

/**
 * font_manager_is_dir:
 * @filepath:   full path to file
 *
 * Returns:             %TRUE if @filepath is a directory
 */
gboolean
font_manager_is_dir (const gchar *filepath)
{
    return g_file_test(filepath, G_FILE_TEST_IS_DIR);
}

/**
 * font_manager_exists:
 * @filepath:   full path to file
 *
 * Returns:             %TRUE if @filepath exists
 */
gboolean
font_manager_exists (const gchar *filepath)
{
    return g_file_test(filepath, G_FILE_TEST_EXISTS);
}

static gboolean
ensure_dir_exists (const gchar *dir)
{
    return (G_LIKELY(font_manager_exists(dir)) || (g_mkdir_with_parents(dir, 0755) == 0));
}

/**
 * font_manager_natural_sort:
 * @str1:   a nul-terminated string
 * @str2:   a nul-terminated string
 *
 * Returns:     An integer less than, equal to, or greater than zero,
 *              if str1 is <, == or > than str2 .
 */
gint
font_manager_natural_sort (const gchar *str1, const gchar *str2)
{
    g_return_val_if_fail((str1 != NULL && str2 != NULL), 0);
    g_autofree gchar *s1 = g_utf8_collate_key_for_filename(str1, -1);
    g_autofree gchar *s2 = g_utf8_collate_key_for_filename(str2, -1);
    return g_strcmp0(s1, s2);
}

/**
 * font_manager_get_file_owner:
 * @filepath:   full path to file
 *
 * Returns:     0 if current user has read/write permissions, -1 otherwise
 */
gint
font_manager_get_file_owner (const gchar *filepath)
{
    return g_access(filepath, R_OK | W_OK);
}

/**
 * font_manager_timecmp:
 * @file_a:  #GFile
 * @file_b:  #GFile
 *
 * Compare the modification time of two different files.
 *
 * Returns:     An integer less than, equal to, or greater than zero,
 *              if a is <, == or > than b.
 */
gint
font_manager_timecmp (GFile *file_a, GFile *file_b)
{
    g_autoptr(GError) error = NULL;
    gchar *attrs = G_FILE_ATTRIBUTE_TIME_MODIFIED;
    GFileQueryInfoFlags flags = G_FILE_QUERY_INFO_NONE;
    g_return_val_if_fail(g_file_query_exists(file_a, NULL), 0);
    g_return_val_if_fail(g_file_query_exists(file_b, NULL), 0);
    g_autoptr(GFileInfo) info_a = g_file_query_info(file_a, attrs, flags, NULL, &error);
    g_return_val_if_fail(error == NULL, 0);
    g_autoptr(GFileInfo) info_b = g_file_query_info(file_b, attrs, flags, NULL, &error);
    g_return_val_if_fail(error == NULL, 0);
    g_autoptr(GDateTime) time_a = g_file_info_get_modification_date_time(info_a);
    g_return_val_if_fail(time_a != NULL, 0);
    g_autoptr(GDateTime) time_b = g_file_info_get_modification_date_time(info_b);
    g_return_val_if_fail(time_b != NULL, 0);
    return g_date_time_compare(time_a, time_b);
}

/**
 * font_manager_get_file_extension:
 * @filepath:   full path to file
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_get_file_extension (const gchar *filepath)
{
    g_return_val_if_fail(filepath != NULL, NULL);
    g_return_val_if_fail(g_strrstr(filepath, ".") != NULL, NULL);
    gchar ** str_arr = g_strsplit(filepath, ".", -1);
    g_return_val_if_fail(str_arr != NULL, NULL);
    guint arr_len = g_strv_length(str_arr);
    g_autofree gchar *res = g_strdup(str_arr[arr_len - 1]);
    g_strfreev(str_arr);
    return g_ascii_strdown(res, -1);
}

/**
 * font_manager_get_local_time:
 *
 * Returns: (transfer full) (nullable): A newly allocated string formatted
 * to the requested format or %NULL if there was an error.
 * The returned string must be freed using #g_free().
 */
gchar *
font_manager_get_local_time (void)
{
    g_autoptr(GDateTime) local_time = g_date_time_new_now_local();
    return g_date_time_format(local_time, "%c");
}

/**
 * font_manager_get_user_font_directory:
 *
 * This function attempts to create the directory if it doesn't already exist
 * and returns the filepath as a string if successful.
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_get_user_font_directory (void)
{
    g_autofree gchar *font_dir = g_build_filename(g_get_user_data_dir(), "fonts", NULL);
    if (ensure_dir_exists(font_dir))
        return g_steal_pointer(&font_dir);
    return NULL;
}

/**
 * font_manager_get_package_cache_directory:
 *
 * This function attempts to create the directory if it doesn't already exist
 * and returns the filepath as a string if successful.
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_get_package_cache_directory (void)
{
    g_autofree gchar *cache_dir = g_build_filename(g_get_user_cache_dir(), PACKAGE_NAME, NULL);
    if (ensure_dir_exists(cache_dir))
        return g_steal_pointer(&cache_dir);
    return NULL;
}

/**
 * font_manager_get_package_config_directory:
 *
 * This function attempts to create the directory if it doesn't already exist
 * and returns the filepath as a string if successful.
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_get_package_config_directory (void)
{
    g_autofree gchar *config_dir = g_build_filename(g_get_user_config_dir(), PACKAGE_NAME, NULL);
    if (ensure_dir_exists(config_dir))
        return g_steal_pointer(&config_dir);
    return NULL;
}

/**
 * font_manager_get_user_fontconfig_directory:
 *
 * This function attempts to create the directory if it doesn't already exist
 * and returns the filepath as a string if successful.
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_get_user_fontconfig_directory (void)
{
    g_autofree gchar *config_dir = g_build_filename(g_get_user_config_dir(), "fontconfig", "conf.d", NULL);
    if (ensure_dir_exists(config_dir))
        return g_steal_pointer(&config_dir);
    return NULL;
}

/**
 * font_manager_str_replace: (skip)
 * @str:                a nul-terminated string
 * @target:             the nul-terminated string to search for
 * @replacement:        the nul-terminated string to replace target with
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_str_replace (const gchar *str, const gchar *target, const gchar *replacement)
{
    g_return_val_if_fail((str != NULL && target != NULL && replacement != NULL), NULL);
    gchar *res = NULL;
    g_autoptr(GError) error = NULL;
    g_autofree gchar *escaped_str = g_regex_escape_string(target, -1);
    g_autoptr(GRegex) regex = g_regex_new(escaped_str, 0, 0, &error);
    if (error == NULL)
        res = g_regex_replace_literal(regex, str, -1, 0, replacement, 0, &error);
    if (error != NULL) {
        g_warning("%i - %s", error->code, error->message);
        g_clear_pointer(&res, g_free);
    }
    return res;
}

/**
 * font_manager_to_filename:
 * @str:                a nul-terminated string
 *
 * Replaces spaces and dashes with an underscore.
 *
 * Returns: (transfer full) (nullable):
 * A newly allocated string that must be freed with #g_free or %NULL
 */
gchar *
font_manager_to_filename (const gchar *str)
{
    g_return_val_if_fail(str != NULL, NULL);
    g_autofree gchar *tmp = font_manager_str_replace(str, " ", "_");
    return font_manager_str_replace(tmp, "-", "_");
}

/**
 * font_manager_install_file:
 * @file:       #GFile
 * @directory:  #GFile
 * @error:      #GError or %NULL to ignore errors
 *
 * Returns:     %TRUE if installation was successful.
 */
gboolean
font_manager_install_file (GFile *file, GFile *directory, GError **error)
{
    g_return_val_if_fail(error == NULL || *error == NULL, FALSE);
    g_return_val_if_fail(file != NULL, FALSE);
    g_return_val_if_fail(directory != NULL, FALSE);
    g_autoptr(GFile) target = font_manager_get_installation_target(file, directory, TRUE, error);
    g_return_val_if_fail(error == NULL || *error == NULL, FALSE);
    GFileCopyFlags flags = G_FILE_COPY_ALL_METADATA | G_FILE_COPY_OVERWRITE | G_FILE_COPY_TARGET_DEFAULT_PERMS;
    g_file_copy(file, target, flags, NULL, NULL, NULL, error);
    g_return_val_if_fail(error == NULL || *error == NULL, FALSE);
    return TRUE;
}

/**
 * font_manager_get_command_line_files:
 * @cmdline:    #GApplicationCommandLine
 *
 * Returns: (transfer full): #FontManagerStringSet containing filepaths for each
 * file specified in @cmdline or %NULL if no files were specified.
 */
FontManagerStringSet *
font_manager_get_command_line_files (GApplicationCommandLine *cmdline)
{
    g_return_val_if_fail(cmdline != NULL, NULL);
    GVariantDict *options = g_application_command_line_get_options_dict(cmdline);
    g_autoptr(GVariant) argv = g_variant_dict_lookup_value(options,
                                                           "",
                                                           G_VARIANT_TYPE_BYTESTRING_ARRAY);
    if (!argv)
        return NULL;
    g_debug("Processing files passed on command line");
    gsize array_length;
    const gchar **filelist = g_variant_get_bytestring_array(argv, &array_length);
    if G_UNLIKELY(array_length == 0)
        return NULL;
    FontManagerStringSet *files = font_manager_string_set_new();
    gint i = 0;
    while (filelist[i]) {
        g_autoptr(GFile) file = g_application_command_line_create_file_for_arg(cmdline, filelist[i]);
        g_autofree gchar *path = g_file_get_path(file);
        g_debug("Adding %s to list of command line files", path);
        font_manager_string_set_add(files, path);
        i++;
    }
    g_free(filelist);
    return files;
}

static GHashTable *gsettings = NULL;

/**
 * font_manager_get_gsettings:
 * @schema_id:      the id of the schema
 *
 * Returns: (transfer full) (nullable):
 * A newly created #GSettings instance or %NULL if schema_id could not be found
 */
GSettings *
font_manager_get_gsettings (const gchar *schema_id)
{
    if (!gsettings)
        gsettings = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, g_object_unref);
    else {
        gpointer stored = g_hash_table_lookup(gsettings, schema_id);
        if (stored) {
            g_debug("Using existing settings instance for %s", schema_id);
            return (GSettings *) g_object_ref(stored);
        }
    }
    GSettingsSchemaSource *schema_source = g_settings_schema_source_get_default();
    g_return_val_if_fail(schema_source != NULL, NULL);
    g_autoptr(GSettingsSchema) schema = g_settings_schema_source_lookup(schema_source, schema_id, TRUE);
    if (schema != NULL) {
        g_debug("Found schema with id %s in default source", schema_id);
    }
    g_debug("Checking for schema overrides");
    GSList *slist = get_possible_schema_dirs();
    GSList *iter;
    for (iter = slist; iter != NULL; iter = iter->next) {
        const gchar *dir = iter->data;
        if (!g_file_test(dir, G_FILE_TEST_IS_DIR)) {
            g_debug("Skipping invalid or non-existent directory path %s", dir);
            continue;
        }
        g_autoptr(GSettingsSchemaSource) source = NULL;
        source = g_settings_schema_source_new_from_directory(dir, schema_source, FALSE, NULL);
        if (source == NULL) {
            g_debug("Failed to create schema source for %s", dir);
            continue;
        }
        g_debug("Checking for schema with id %s in %s", schema_id, dir);
        GSettingsSchema *override = g_settings_schema_source_lookup(source, schema_id, TRUE);
        if (override) {
            g_settings_schema_unref(g_steal_pointer(&schema));
            schema = override;
            g_debug("Using schema with id %s from %s", schema_id, dir);
        }
    }
    g_slist_free_full(slist, g_free);
    if (schema == NULL) {
        g_debug("Failed to locate schema for id %s", schema_id);
        g_debug("Settings will not persist");
        return NULL;
    }
    GSettings *result = g_settings_new_full(schema, NULL, NULL);
    g_hash_table_insert(gsettings, g_strdup(schema_id), g_object_ref(result));
    return result;
}

/**
 * font_manager_free_gsettings:
 *
 * Free stored gsettings
 */
void
font_manager_free_gsettings () {
    if (gsettings) {
        g_hash_table_remove_all(gsettings);
        g_hash_table_unref(gsettings);
    }
    return;
}

