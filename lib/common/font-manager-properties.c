/* font-manager-properties.c
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

#include "font-manager-properties.h"

/**
 * SECTION: font-manager-properties
 * @short_description: Fontconfig property configuration
 * @title: Font Properties
 * @include: font-manager-properties.h
 *
 * Base class for generating fontconfig configuration files which modify
 * font properties.
 */

typedef struct
{
    gchar *config_dir;
    gchar *target_file;

    gint hintstyle;
    gboolean antialias;
    gboolean hinting;
    gboolean autohint;
    gboolean embeddedbitmap;
    gdouble less;
    gdouble more;
    gint rgba;
    gint lcdfilter;
    gdouble scale;
    gdouble dpi;

    FontManagerPropertiesType type;
}
FontManagerPropertiesPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FontManagerProperties, font_manager_properties, G_TYPE_OBJECT)

enum
{
    PROP_RESERVED,
    PROP_HINTSTYLE,
    PROP_ANTIALIAS,
    PROP_HINTING,
    PROP_AUTOHINT,
    PROP_EMBEDDEDBITMAP,
    PROP_LESS,
    PROP_MORE,
    PROP_RGBA,
    PROP_LCDFILTER,
    PROP_SCALE,
    PROP_DPI,
    PROP_CONFIG_DIR,
    PROP_TARGET_FILE,
    PROP_TYPE,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = {0};

#define DEFAULT_PARAM_FLAGS (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)

static const struct
{
    gint start;
    gint end;
}
PROPERTY_ID_RANGE [] =
{
    { 1, 7 },
    { 8, 11 }
};

GType
font_manager_properties_type_get_type (void)
{
  static gsize g_define_type_id__volatile = 0;

  if (g_once_init_enter (&g_define_type_id__volatile))
    {
      static const GEnumValue values[] = {
        { FONT_MANAGER_PROPERTIES_TYPE_DEFAULT, "FONT_MANAGER_PROPERTIES_TYPE_DEFAULT", "default" },
        { FONT_MANAGER_PROPERTIES_TYPE_DISPLAY, "FONT_MANAGER_PROPERTIES_TYPE_DISPLAY", "display" },
        { 0, NULL, NULL }
      };
      GType g_define_type_id =
        g_enum_register_static (g_intern_static_string ("FontManagerPropertiesType"), values);
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id);
    }

  return g_define_type_id__volatile;
}

static void
font_manager_properties_dispose (GObject *gobject)
{
    g_return_if_fail(gobject != NULL);
    FontManagerProperties *self = FONT_MANAGER_PROPERTIES(gobject);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    g_clear_pointer(&priv->config_dir, g_free);
    g_clear_pointer(&priv->target_file, g_free);
    G_OBJECT_CLASS(font_manager_properties_parent_class)->dispose(gobject);
}

static void
font_manager_properties_get_property (GObject *gobject,
                                     guint property_id,
                                     GValue *value,
                                     GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerProperties *self = FONT_MANAGER_PROPERTIES(gobject);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    switch (property_id) {
        case PROP_HINTSTYLE:
            g_value_set_int(value, priv->hintstyle);
            break;
        case PROP_ANTIALIAS:
            g_value_set_boolean(value, priv->antialias);
            break;
        case PROP_HINTING:
            g_value_set_boolean(value, priv->hinting);
            break;
        case PROP_AUTOHINT:
            g_value_set_boolean(value, priv->autohint);
            break;
        case PROP_EMBEDDEDBITMAP:
            g_value_set_boolean(value, priv->embeddedbitmap);
            break;
        case PROP_LESS:
            g_value_set_double(value, priv->less);
            break;
        case PROP_MORE:
            g_value_set_double(value, priv->more);
            break;
        case PROP_RGBA:
            g_value_set_int(value, priv->rgba);
            break;
        case PROP_LCDFILTER:
            g_value_set_int(value, priv->lcdfilter);
            break;
        case PROP_SCALE:
            g_value_set_double(value, priv->scale);
            break;
        case PROP_DPI:
            g_value_set_double(value, priv->dpi);
            break;
        case PROP_CONFIG_DIR:
            g_value_set_string(value, priv->config_dir);
            break;
        case PROP_TARGET_FILE:
            g_value_set_string(value, priv->target_file);
            break;
        case PROP_TYPE:
            g_value_set_int(value, ((gint) priv->type));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_properties_set_property (GObject *gobject,
                                     guint property_id,
                                     const GValue *value,
                                     GParamSpec *pspec)
{
    g_return_if_fail(gobject != NULL);
    FontManagerProperties *self = FONT_MANAGER_PROPERTIES(gobject);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    switch (property_id) {
        case PROP_HINTSTYLE:
            priv->hintstyle = g_value_get_int(value);
            break;
        case PROP_ANTIALIAS:
            priv->antialias = g_value_get_boolean(value);
            break;
        case PROP_HINTING:
            priv->hinting = g_value_get_boolean(value);
            break;
        case PROP_AUTOHINT:
            priv->autohint = g_value_get_boolean(value);
            break;
        case PROP_EMBEDDEDBITMAP:
            priv->embeddedbitmap = g_value_get_boolean(value);
            break;
        case PROP_LESS:
            priv->less = g_value_get_double(value);
            break;
        case PROP_MORE:
            priv->more = g_value_get_double(value);
            break;
        case PROP_RGBA:
            priv->rgba = g_value_get_int(value);
            break;
        case PROP_LCDFILTER:
            priv->lcdfilter = g_value_get_int(value);
            break;
        case PROP_SCALE:
            priv->scale = g_value_get_double(value);
            break;
        case PROP_DPI:
            priv->dpi = g_value_get_double(value);
            break;
        case PROP_CONFIG_DIR:
            g_free(priv->config_dir);
            priv->config_dir = g_value_dup_string(value);
            break;
        case PROP_TARGET_FILE:
            g_free(priv->target_file);
            priv->target_file = g_value_dup_string(value);
            break;
        case PROP_TYPE:
            priv->type = ((FontManagerPropertiesType) g_value_get_int(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(gobject, property_id, pspec);
            break;
    }
    return;
}

static void
font_manager_properties_parse_edit_node (FontManagerProperties *self, xmlNode *edit_node)
{
    xmlChar *prop_name = NULL;
    for (xmlAttrPtr prop = edit_node->properties; prop != NULL; prop = prop->next) {
        if (g_strcmp0((const char *) prop->name, "name") == 0) {
            prop_name = xmlNodeGetContent(prop->children);
            break;
        }
    }
    if (!prop_name)
        return;
    for (xmlNode *val = edit_node->children; val != NULL; val = val->next) {
        xmlChar *prop_val = xmlNodeGetContent(val);
        if (prop_val == NULL) {
            continue;
        } else if (g_strcmp0((const char *) val->name, "bool") == 0) {
            g_object_set(self, (const gchar *) prop_name,
                        (g_strcmp0((const char *) prop_val, "true") == 0), NULL);
        } else if (g_strcmp0((const char *) val->name, "int") == 0) {
            g_object_set(self, (const gchar *) prop_name, atoi((const char *) prop_val), NULL);
        } else if (g_strcmp0((const char *) val->name, "double") == 0) {
            g_object_set(self, (const gchar *) prop_name,
                         g_ascii_strtod((const char *) prop_val, NULL), NULL);
        } else if (g_strcmp0((const char *) val->name, "string") == 0) {
            g_object_set(self, (const gchar *) prop_name, (const gchar *) prop_val, NULL);
        }
        xmlFree(prop_val);
    }
    xmlFree(prop_name);
    return;
}

static void
font_manager_properties_parse_test_node (FontManagerProperties *self, xmlNode *test_node)
{
    xmlChar *prop_name = NULL;
    xmlChar *prop_val = NULL;
    for (xmlAttrPtr prop = test_node->properties; prop != NULL; prop = prop->next) {
        if (g_strcmp0((const char *) prop->name, "compare") == 0) {
            for (xmlNode *val = test_node->children; val != NULL; val = val->next) {
                if (g_strcmp0((const char *) val->name, "double") == 0) {
                    prop_name = xmlNodeGetContent(prop->children);
                    prop_val = xmlNodeGetContent(val);
                    break;
                }
            }
            break;
        }
    }
    if (prop_name && prop_val)
        g_object_set(self, (const gchar *) prop_name, atof((const char *) prop_val), NULL);
    if (prop_name)
        xmlFree(prop_name);
    if (prop_val)
        xmlFree(prop_val);
    return;
}

static void
font_manager_properties_add_match_criteria (FontManagerProperties *self,
                                           FontManagerXmlWriter *writer)
{
    g_return_if_fail(self != NULL);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    if (priv->less != 0.0) {
        g_autofree gchar *val = g_strdup_printf("%.1f", priv->less);
        font_manager_xml_writer_add_test_element(writer, "size", "less", "double", val);
    }
    if (priv->more != 0.0) {
        g_autofree gchar *val = g_strdup_printf("%.1f", priv->more);
        font_manager_xml_writer_add_test_element(writer, "size", "more", "double", val);
    }
    return;
}

static void
font_manager_properties_parse_match_node (FontManagerProperties *self, xmlNode *match_node)
{
    for (xmlNode *iter = match_node->children; iter != NULL; iter = iter->next) {
        if (iter->type != XML_ELEMENT_NODE) {
            continue;
        } else if (g_strcmp0((const char *) iter->name, "edit") == 0) {
            FONT_MANAGER_PROPERTIES_GET_CLASS(self)->parse_edit_node(self, iter);
        } else if (g_strcmp0((const char *) iter->name, "test") == 0) {
            FONT_MANAGER_PROPERTIES_GET_CLASS(self)->parse_test_node(self, iter);
        }
    }
    return;
}

static void
font_manager_properties_add_assignments (FontManagerProperties *self,
                                        FontManagerXmlWriter *writer)
{
    g_return_if_fail(self != NULL);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);

    int t = (int) priv->type;
    for (int i = PROPERTY_ID_RANGE[t].start; i <= PROPERTY_ID_RANGE[t].end; i++) {
        /* Skip test elements, handled in add_match_criteria */
        if (i == PROP_LESS || i == PROP_MORE)
            continue;
        g_autofree gchar *loc = NULL;
        g_autofree gchar *val = NULL;
        g_autofree gchar *val_type = NULL;
        const gchar *name = PROPERTIES[i].name;
        GType type = PROPERTIES[i].type;
        g_auto(GValue) value = G_VALUE_INIT;
        g_value_init(&value, type);
        g_object_get_property(G_OBJECT(self), name, &value);
        switch (type) {
            /* Brackets around case statements here avoid warnings */
            case G_TYPE_INT: {
                val = g_strdup_printf("%i", g_value_get_int(&value));
                val_type = g_strdup("int");
                break;
            }
            case G_TYPE_DOUBLE: {
                loc = g_strdup(setlocale(LC_ALL, NULL));
                setlocale(LC_ALL, "C");
                val = g_strdup_printf("%.1f", g_value_get_double(&value));
                val_type = g_strdup("double");
                setlocale(LC_ALL, loc);
                break;
            }
            case G_TYPE_BOOLEAN: {
                if (g_value_get_boolean(&value))
                    val = g_strdup("true");
                else
                    val = g_strdup("false");
                val_type = g_strdup("bool");
                break;
            }
            case G_TYPE_STRING: {
                val = g_strdup(g_value_get_string(&value));
                val_type = g_strdup("string");
                break;
            }
            default:
                break;
        }
        if (val && val_type)
            font_manager_xml_writer_add_assignment(writer, name, val_type, val);
    }
}

static gdouble
get_default_for_double_property (int prop_id)
{
    switch (prop_id) {
        case PROP_DPI:
            return 96.0;
        case PROP_SCALE:
            return 1.0;
        default:
            break;
    }
    return 0.0;
}

static void
font_manager_properties_class_init (FontManagerPropertiesClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->dispose = font_manager_properties_dispose;
    object_class->get_property = font_manager_properties_get_property;
    object_class->set_property = font_manager_properties_set_property;

    klass->parse_edit_node = font_manager_properties_parse_edit_node;
    klass->parse_test_node = font_manager_properties_parse_test_node;
    klass->add_match_criteria = font_manager_properties_add_match_criteria;

    for (int i = 0; i < N_PROPERTIES; i++) {

        switch (PROPERTIES[i].type) {
            case G_TYPE_INT:
                obj_properties[i] = g_param_spec_int(PROPERTIES[i].name,
                                                    NULL,
                                                    PROPERTIES[i].desc,
                                                    0,
                                                    i == PROP_LCDFILTER ? 6 :
                                                    i == PROP_TYPE ? 1 : 4,
                                                    0,
                                                    DEFAULT_PARAM_FLAGS);
                break;
            case G_TYPE_BOOLEAN:
                obj_properties[i] = g_param_spec_boolean(PROPERTIES[i].name,
                                                         NULL,
                                                         PROPERTIES[i].desc,
                                                         FALSE,
                                                         DEFAULT_PARAM_FLAGS);
                break;
            case G_TYPE_DOUBLE:
                obj_properties[i] = g_param_spec_double(PROPERTIES[i].name,
                                                        NULL,
                                                        PROPERTIES[i].desc,
                                                        0.0, G_MAXDOUBLE,
                                                        get_default_for_double_property(i),
                                                        DEFAULT_PARAM_FLAGS);
                break;
            case G_TYPE_STRING:
                obj_properties[i] = g_param_spec_string(PROPERTIES[i].name,
                                                       NULL,
                                                       PROPERTIES[i].desc,
                                                       NULL,
                                                       DEFAULT_PARAM_FLAGS);
                break;
            case G_TYPE_RESERVED_GLIB_FIRST:
                obj_properties[i] = NULL;
                break;
            default:
                break;
        }

    }

    g_object_class_install_properties(object_class, N_PROPERTIES, obj_properties);
    return;
}

static void
font_manager_properties_init (FontManagerProperties *self)
{
    g_return_if_fail(self != NULL);
    font_manager_properties_reset(self);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    priv->type = FONT_MANAGER_PROPERTIES_TYPE_DEFAULT;
    return;
}

/**
 * font_manager_properties_load:
 * @self:   #FontManagerProperties
 *
 * Returns: %TRUE if current configuration file was successfully loaded
 */
gboolean
font_manager_properties_load (FontManagerProperties *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_autofree gchar *filepath = font_manager_properties_get_filepath(self);
    if (filepath == NULL)
        return FALSE;

    g_autoptr(GFile) file = g_file_new_for_path(filepath);
    if (!g_file_query_exists(file, NULL))
        return FALSE;

    xmlDoc *doc = xmlReadFile(filepath, NULL, 0);

    if (doc == NULL) {
        /* Empty file */
        return FALSE;
    }

    xmlNode *root = xmlDocGetRootElement(doc);
    if (root == NULL) {
        xmlFreeDoc(doc);
        xmlCleanupParser();
        return FALSE;
    }

    for (xmlNode *iter = root->children; iter != NULL; iter = iter->next) {
        if (iter->type != XML_ELEMENT_NODE)
            continue;
        if (g_strcmp0((const char *) iter->name, "match") == 0) {
            font_manager_properties_parse_match_node(self, iter);
            break;
        }
    }

    xmlFreeDoc(doc);
    return TRUE;
}

/**
 * font_manager_properties_save:
 * @self:   #FontManagerProperties
 *
 * Returns: %TRUE if current configuration was successfully saved to file
 */
gboolean
font_manager_properties_save (FontManagerProperties *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_autofree gchar *filepath = font_manager_properties_get_filepath(self);
    g_return_val_if_fail(filepath != NULL, FALSE);
    g_autoptr(FontManagerXmlWriter) writer = font_manager_xml_writer_new();
    font_manager_xml_writer_open(writer, filepath);
    font_manager_xml_writer_start_element(writer, "match");
    font_manager_xml_writer_write_attribute(writer, "target", "font");
    FONT_MANAGER_PROPERTIES_GET_CLASS(self)->add_match_criteria(self, writer);
    font_manager_properties_add_assignments(self, writer);
    font_manager_xml_writer_end_element(writer);
    gboolean result = font_manager_xml_writer_close(writer);
    return result;
}

/**
 * font_manager_properties_discard:
 * @self:   #FontManagerProperties
 *
 * Returns: %TRUE if current configuration was successfully discarded
 */
gboolean
font_manager_properties_discard (FontManagerProperties *self)
{
    g_return_val_if_fail(self != NULL, FALSE);
    g_autofree gchar *filepath = font_manager_properties_get_filepath(self);
    g_autoptr(GFile) file = g_file_new_for_path(filepath);
    gboolean result = TRUE;
    if (g_file_query_exists(file, NULL))
        result = g_file_delete(file, NULL, NULL);
    font_manager_properties_reset(self);
    return result;
}

/**
 * font_manager_properties_get_filepath:
 * @self:   #FontManagerProperties
 *
 * Returns: (transfer full) (nullable): a newly allocated string containing the full
 * filepath to current configuration file or %NULL. Free the result using #g_free().
 */
gchar *
font_manager_properties_get_filepath (FontManagerProperties *self)
{
    g_return_val_if_fail(self != NULL, NULL);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    if (priv->config_dir == NULL || priv->target_file == NULL)
        return NULL;
    return g_build_filename(priv->config_dir, priv->target_file, NULL);
}

/**
 * font_manager_properties_reset:
 * @self:   #FontManagerProperties
 *
 * Reset all base properties to their default values
 */
void
font_manager_properties_reset (FontManagerProperties *self)
{
    g_return_if_fail(self != NULL);
    FontManagerPropertiesPrivate *priv = font_manager_properties_get_instance_private(self);
    priv->hintstyle = 0;
    /* This is the default, even when not set */
    priv->antialias = TRUE;
    priv->hinting = FALSE;
    priv->autohint = FALSE;
    priv->embeddedbitmap = FALSE;
    /* Default is none but we don't expose that in the UI, so this is set to unknown */
    priv->rgba = FC_RGBA_UNKNOWN;
    priv->lcdfilter = 0;
    priv->scale = 1.0;
    priv->dpi = 96.0;
    priv->less = 0.0;
    priv->more = 0.0;

    /* Get actual values from default pattern, if possible */
    FcPattern *blank = FcPatternCreate();

    if (blank) {

        FcConfigSubstitute(0, blank, FcMatchPattern);
        FcDefaultSubstitute(blank);

        FcResult result;
        FcPattern *system = FcFontMatch(0, blank, &result);

        if (system) {

            gint hintstyle;
            gint rgba;
            gint lcdfilter;
            gdouble scale;
            gdouble dpi;
            gboolean antialias;
            gboolean hinting;
            gboolean autohint;
            gboolean embeddedbitmap;

            if (FcPatternGetInteger(system, FC_HINT_STYLE, 0, &hintstyle) == FcResultMatch)
                priv->hintstyle = hintstyle;

            if (FcPatternGetInteger(system, FC_RGBA, 0, &rgba) == FcResultMatch) {
                if (rgba != FC_RGBA_NONE)
                    priv->rgba = rgba;
            }

            if (FcPatternGetInteger(system, FC_LCD_FILTER, 0, &lcdfilter) == FcResultMatch)
                priv->lcdfilter = lcdfilter;

            if (FcPatternGetDouble(system, FC_SCALE, 0 , &scale) == FcResultMatch)
                priv->scale = scale;

            if (FcPatternGetDouble(system, FC_DPI, 0 , &dpi) == FcResultMatch)
                priv->dpi = dpi;

            if (FcPatternGetBool(system, FC_ANTIALIAS, 0 , &antialias) == FcResultMatch)
                priv->antialias = antialias;

            if (FcPatternGetBool(system, FC_HINTING, 0 , &hinting) == FcResultMatch)
                priv->hinting = hinting;

            if (FcPatternGetBool(system, FC_AUTOHINT, 0 , &autohint) == FcResultMatch)
                priv->autohint = autohint;

            if (FcPatternGetBool(system, FC_EMBEDDED_BITMAP, 0 , &embeddedbitmap) == FcResultMatch)
                priv->embeddedbitmap = embeddedbitmap;

            FcPatternDestroy(system);

        }

        FcPatternDestroy(blank);

    }

    return;
}

/**
 * font_manager_properties_new:
 *
 * Returns: (transfer full): A newly created #FontManagerProperties
 * Free the returned object using #g_object_unref().
 */
FontManagerProperties *
font_manager_properties_new (void)
{
    return g_object_new(FONT_MANAGER_TYPE_PROPERTIES, NULL);
}

