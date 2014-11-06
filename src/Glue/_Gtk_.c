/* _Gtk_.c
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

#include <gtk/gtk.h>

gboolean
_gtk_popovers_should_close_on_click (GtkMenuButton * button)
{
#if HAVE_LATEST_GTK
    gtk_widget_hide(GTK_WIDGET(gtk_menu_button_get_popover(button)));
    return gtk_widget_is_visible(GTK_WIDGET(gtk_menu_button_get_popover(button)));
#else
    return FALSE;
#endif
}
