/* font-manager-gtk-utils.h
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

#include <pango/pango-context.h>
#include <pango/pango-fontmap.h>
#include <pango/pangofc-fontmap.h>

#include <gtk/gtk.h>

#define FONT_MANAGER_BUS_ID "org.gnome.FontManager"
#define FONT_MANAGER_BUS_PATH "/org/gnome/FontManager"
#define FONT_MANAGER_FONT_VIEWER_BUS_ID "org.gnome.FontViewer"
#define FONT_MANAGER_FONT_VIEWER_BUS_PATH "/org/gnome/FontViewer"

#define FONT_MANAGER_STYLE_CLASS_FLAT "flat"
#define FONT_MANAGER_STYLE_CLASS_VIEW "view"
#define FONT_MANAGER_STYLE_CLASS_DIM_LABEL "dim-label"

#define FONT_MANAGER_MIN_MARGIN 2
#define FONT_MANAGER_DEFAULT_MARGIN 6

#define FONT_MANAGER_DEFAULT_FONT "Sans"
#define FONT_MANAGER_MIN_FONT_SIZE 6.0
#define FONT_MANAGER_MAX_FONT_SIZE 96.0
#define FONT_MANAGER_DEFAULT_PREVIEW_SIZE 10.0
#define FONT_MANAGER_CHARACTER_MAP_PREVIEW_SIZE 16.0

#define FONT_MANAGER_DEFAULT_PREVIEW_TEXT "\n\n\n"\
"    %s\n" \
"\n" \
"    ABCDEFGHIJKLMNOPQRSTUVWXYZ\n" \
"    abcdefghijklmnopqrstuvwxyz\n" \
"    1234567890.:,;(*!?')\n" \
"\n" \
"    "

#define FONT_MANAGER_LOREM_IPSUM \
"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent sed " \
"tristique nunc. Sed augue dolor, posuere a auctor quis, dignissim sed " \
"est. Aliquam convallis, orci nec posuere lacinia, risus libero mattis " \
"velit, a consectetur orci felis venenatis neque. Praesent id lacinia m" \
"assa. Nam risus diam, faucibus vitae pulvinar eget, scelerisque nec ni" \
"sl. Integer dolor ligula, placerat id elementum id, venenatis sed mass" \
"a. Vestibulum at convallis libero. Curabitur at molestie justo.\n" \
"\n" \
"Mauris convallis odio rutrum elit aliquet quis fermentum velit tempus." \
" Ut porttitor lectus at dui iaculis in vestibulum eros tristique. Vest" \
"ibulum ante ipsum primis in faucibus orci luctus et ultrices posuere c" \
"ubilia Curae; Donec ut dui massa, at aliquet leo. Cras sagittis pulvin" \
"ar nunc. Fusce eget felis ut dolor blandit scelerisque non eget risus." \
" Nunc elementum ipsum id lacus porttitor accumsan. Suspendisse at quam" \
" ligula, ultrices bibendum massa.\n" \
"\n" \
"Mauris feugiat, orci non fermentum congue, libero est rutrum sem, non " \
"dignissim justo urna at turpis. Donec non varius augue. Fusce id enim " \
"ligula, sit amet mattis urna. Ut sodales augue tristique tortor lobort" \
"is vestibulum. Maecenas quis tortor lacus. Etiam varius hendrerit bibe" \
"ndum. Nullam pretium nulla in sem blandit vel facilisis felis fermentu" \
"m. Integer aliquet leo nec nunc sollicitudin congue. In hac habitasse " \
"platea dictumst. Curabitur mattis nibh ac velit euismod condimentum. P" \
"ellentesque volutpat, neque ac congue fermentum, turpis metus posuere " \
"turpis, ac facilisis velit lectus sed diam. Etiam dui diam, tempus vit" \
"ae fringilla quis, tincidunt ac libero.\n" \
"\n" \
"Quisque sollicitudin eros sit amet lorem semper nec imperdiet ante veh" \
"icula. Proin a vulputate sem. Aliquam erat volutpat. Vestibulum congue" \
" pulvinar eros eu vestibulum. Phasellus metus mauris, suscipit tristiq" \
"ue ullamcorper laoreet, viverra eget libero. Donec id nibh justo. Aliq" \
"uam sagittis ultricies erat. Integer sed purus felis. Pellentesque leo" \
" nisi, sagittis non tincidunt vitae, porta quis eros. Pellentesque ut " \
"ornare erat. Vivamus semper sodales suscipit. Praesent placerat eleife" \
"nd nibh quis tristique. Aenean ullamcorper pellentesque ultrices. Nunc" \
" eu risus turpis, in condimentum dui. Aliquam erat volutpat. Phasellus" \
" sagittis mattis diam, sit amet pharetra lacus cursus non.\n" \
"\n" \
"Vestibulum sed est id velit rhoncus imperdiet. Aliquam dictum, arcu at" \
" tincidunt condimentum, metus ligula molestie lorem, eget congue torto" \
"r est ut massa. Duis ut pulvinar nisl. Aenean sodales purus id risus h" \
"endrerit sit amet mattis sem blandit. Aenean feugiat dapibus mattis. P" \
"raesent non nibh magna. Nulla facilisi. Nam elementum malesuada sagitt" \
"is. Cras et tellus augue, non rhoncus libero. Suspendisse ut nulla mau" \
"ris.\n" \
"\n" \
"Suspendisse potenti. Nulla neque leo, condimentum nec posuere non, ele" \
"mentum sit amet lorem. Integer ut ante libero, a tristique quam. Nulla" \
" libero nibh, bibendum eget blandit non, viverra in velit. Duis sit am" \
"et ipsum in massa imperdiet interdum. Phasellus venenatis consequat le" \
"ctus eget facilisis. Quisque ullamcorper rutrum erat at egestas. Integ" \
"er pharetra pulvinar odio, sagittis imperdiet ligula aliquam suscipit." \
" Aenean rutrum convallis felis, at rhoncus lectus tincidunt et. Morbi " \
"mattis risus eu quam suscipit ut tempus nunc pellentesque. Ut adipisci" \
"ng, nibh nec pharetra fringilla, diam diam hendrerit neque, quis preti" \
"um tellus ligula ut dolor. Nullam dictum, libero in molestie convallis" \
", nunc arcu imperdiet risus, vitae laoreet risus ipsum in ligula. Clas" \
"s aptent taciti sociosqu ad litora torquent per conubia nostra, per in" \
"ceptos himenaeos. Donec molestie, quam ut adipiscing consequat, risus " \
"sem facilisis nisi, ut aliquet sapien est a sapien. Quisque sed enim j" \
"usto, sit amet volutpat urna."

void font_manager_set_application_style (void);
void font_manager_clear_pango_cache (PangoContext *ctx);
void font_manager_widget_set_align (GtkWidget *widget, GtkAlign align);
void font_manager_widget_set_expand (GtkWidget *widget, gboolean expand);
void font_manager_widget_set_margin (GtkWidget *widget, gint margin);
void font_manager_widget_dispose (GtkWidget *widget);

gchar * font_manager_get_localized_pangram (void);
gchar * font_manager_get_localized_preview_text (void);

GtkTextTagTable * font_manager_text_tag_table_new (void);
GtkGesture * font_manager_tree_view_setup_drag_selection (GtkTreeView *treeview);

GtkShortcut * font_manager_get_shortcut_for_stateful_action (const gchar *prefix, const gchar *name,
                                                             const gchar *target, const gchar *accel);
