#include "unicode-character-info.h"
#include "unicode-codepoint-list.h"
#include "unicode-character-map.h"
#include "unicode-search-bar.h"
#include "test-application.h"

/******************** Static CodepointList for testing purposes ***********************************/

const gchar *CHARSET = "[ 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 402, 416, 417, 431, 432, 506, 507, 508, 509, 510, 511, 536, 537, 538, 539, 710, 711, 713, 728, 729, 730, 731, 732, 733, 768, 769, 770, 771, 772, 774, 775, 776, 777, 778, 779, 780, 786, 789, 803, 806, 807, 808, 836, 884, 885, 894, 900, 901, 902, 903, 904, 905, 906, 908, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923, 924, 925, 926, 927, 928, 929, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943, 944, 945, 946, 947, 948, 949, 950, 951, 952, 953, 954, 955, 956, 957, 958, 959, 960, 961, 962, 963, 964, 965, 966, 967, 968, 969, 970, 971, 972, 973, 974, 990, 991, 992, 993, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 1034, 1035, 1036, 1037, 1038, 1039, 1040, 1041, 1042, 1043, 1044, 1045, 1046, 1047, 1048, 1049, 1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070, 1071, 1072, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1081, 1082, 1083, 1084, 1085, 1086, 1087, 1088, 1089, 1090, 1091, 1092, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1116, 1117, 1118, 1119, 1122, 1123, 1138, 1139, 1140, 1141, 1168, 1169, 7808, 7809, 7810, 7811, 7812, 7813, 7840, 7841, 7842, 7843, 7844, 7845, 7846, 7847, 7848, 7849, 7850, 7851, 7852, 7853, 7854, 7855, 7856, 7857, 7858, 7859, 7860, 7861, 7862, 7863, 7864, 7865, 7866, 7867, 7868, 7869, 7870, 7871, 7872, 7873, 7874, 7875, 7876, 7877, 7878, 7879, 7880, 7881, 7882, 7883, 7884, 7885, 7886, 7887, 7888, 7889, 7890, 7891, 7892, 7893, 7894, 7895, 7896, 7897, 7898, 7899, 7900, 7901, 7902, 7903, 7904, 7905, 7906, 7907, 7908, 7909, 7910, 7911, 7912, 7913, 7914, 7915, 7916, 7917, 7918, 7919, 7920, 7921, 7922, 7923, 7924, 7925, 7926, 7927, 7928, 7929, 8208, 8211, 8212, 8213, 8216, 8217, 8218, 8220, 8221, 8222, 8224, 8225, 8226, 8230, 8240, 8249, 8250, 8253, 8260, 8304, 8308, 8309, 8310, 8311, 8312, 8313, 8314, 8315, 8316, 8317, 8318, 8319, 8320, 8321, 8322, 8323, 8324, 8325, 8326, 8327, 8328, 8329, 8330, 8331, 8332, 8333, 8334, 8363, 8364, 8467, 8470, 8471, 8482, 8486, 8494, 8706, 8710, 8719, 8721, 8722, 8725, 8729, 8730, 8734, 8747, 8776, 8800, 8804, 8805, 9312, 9313, 9314, 9315, 9316, 9317, 9318, 9319, 9320, 9321, 9322, 9323, 9324, 9325, 9326, 9327, 9328, 9329, 9330, 9331, 9450, 9451, 9452, 9453, 9454, 9455, 9456, 9457, 9458, 9459, 9460, 9471, 9674, 9675, 10102, 10103, 10104, 10105, 10106, 10107, 10108, 10109, 10110, 10111, 64256, 64257, 64258, 64259, 64260]";

#define TEST_TYPE_CODEPOINT_LIST (test_codepoint_list_get_type())
G_DECLARE_FINAL_TYPE(TestCodepointList, test_codepoint_list, TEST, CODEPOINT_LIST, GObject)
struct _TestCodepointList { GObject parent_instance; GList *charset; };
static void unicode_codepoint_list_interface_init (UnicodeCodepointListInterface *iface);
G_DEFINE_TYPE_WITH_CODE(TestCodepointList, test_codepoint_list, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(UNICODE_TYPE_CODEPOINT_LIST, unicode_codepoint_list_interface_init))

static gint
get_index (UnicodeCodepointList *_self, GSList *codepoints)
{
    g_return_val_if_fail(_self != NULL, -1);
    TestCodepointList *self = TEST_CODEPOINT_LIST(_self);
    if (!codepoints || g_slist_length(codepoints) < 1)
        return -1;
    gunichar code1 = (gunichar) GPOINTER_TO_INT(g_slist_nth_data(codepoints, 0));
    return self->charset != NULL ? (gint) g_list_index(self->charset, GINT_TO_POINTER(code1)) : -1;
}

static gint
get_last_index (UnicodeCodepointList *_self)
{
    g_return_val_if_fail(_self != NULL, -1);
    TestCodepointList *self = TEST_CODEPOINT_LIST(_self);
    return self->charset != NULL ? (gint) g_list_length(self->charset) - 1 : -1;
}

static GSList *
get_char (UnicodeCodepointList *_self, gint index)
{
    g_return_val_if_fail(_self != NULL, NULL);
    TestCodepointList *self = TEST_CODEPOINT_LIST(_self);
    GSList *results = NULL;

    return self->charset != NULL ?
           g_slist_append(results, g_list_nth_data(self->charset, index)) :
           results;
}

static void
unicode_codepoint_list_interface_init (UnicodeCodepointListInterface *iface)
{
    iface->get_codepoints = get_char;
    iface->get_index = get_index;
    iface->get_last_index = get_last_index;
    return;
}

static void
test_codepoint_list_finalize (GObject *object)
{
    TestCodepointList *self = TEST_CODEPOINT_LIST(object);
    g_list_free(self->charset);
    G_OBJECT_CLASS(test_codepoint_list_parent_class)->finalize(object);
    return;
}

static void test_codepoint_list_class_init (TestCodepointListClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS(klass);
    object_class->finalize = test_codepoint_list_finalize;
    return;
}

static void
test_codepoint_list_init (TestCodepointList *self)
{
    self->charset = NULL;
    g_autoptr(JsonParser) parser = json_parser_new();
    if (json_parser_load_from_data(parser, CHARSET, -1, NULL)) {
        JsonNode *root = json_parser_get_root(parser);
        g_assert(JSON_NODE_HOLDS_ARRAY(root));
        JsonArray *_charset = json_node_get_array(root);
        for (gint i = 0; i < json_array_get_length(_charset); i++)
            self->charset = g_list_append(self->charset, GINT_TO_POINTER(json_array_get_int_element(_charset, i)));
    }
    return;
}

TestCodepointList *
test_codepoint_list_new ()
{
    return g_object_new(TEST_TYPE_CODEPOINT_LIST, NULL);
}

/**************************************************************************************************/

void
on_font_set (GtkFontButton *chooser, gpointer user_data)
{
    g_autoptr(PangoFontDescription) font_desc = gtk_font_chooser_get_font_desc(GTK_FONT_CHOOSER(chooser));
    unicode_character_map_set_preview_size(UNICODE_CHARACTER_MAP(user_data),
                                           (gdouble) pango_font_description_get_size(font_desc) / PANGO_SCALE);
    unicode_character_map_set_font_desc(UNICODE_CHARACTER_MAP(user_data), font_desc);
    return;
}

G_MODULE_EXPORT
TestDialog *
get_widget (TestApplicationWindow *parent)
{
    TestDialog *dialog = test_dialog_new(parent, "Character Map", 600, 500);
    GtkWidget *cmap = unicode_character_map_new();
    g_autoptr(TestCodepointList) codepoints = test_codepoint_list_new();
    unicode_character_map_set_codepoint_list(UNICODE_CHARACTER_MAP(cmap), UNICODE_CODEPOINT_LIST(codepoints));
    GtkWidget *search = unicode_search_bar_new();
    unicode_search_bar_set_character_map(UNICODE_SEARCH_BAR(search), UNICODE_CHARACTER_MAP(cmap));
    GtkWidget *scroll = gtk_scrolled_window_new();
    gtk_widget_set_can_focus(scroll, TRUE);
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scroll), cmap);
    GtkWidget *font_chooser = gtk_font_button_new();
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    GtkWidget *info = unicode_character_info_new();
    unicode_character_info_set_character_map(UNICODE_CHARACTER_INFO(info), UNICODE_CHARACTER_MAP(cmap));
    gtk_box_append(GTK_BOX(box), info);
    gtk_box_append(GTK_BOX(box), scroll);
    gtk_box_append(GTK_BOX(box), search);
    g_signal_connect(font_chooser, "font-set", G_CALLBACK(on_font_set), cmap);
    test_dialog_append(dialog, box);
    test_dialog_append_control(dialog, font_chooser);
    return dialog;
}
