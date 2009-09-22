"""
This module handles everything related to the font preview area.
.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009 Jerry Casiano
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to:
#
# Free Software Foundation, Inc.
# 51 Franklin Street, Fifth Floor
# Boston, MA  02110-1301, USA.
#
# Suppress errors related to gettext
# pylint: disable-msg=E0602
# Suppress messages related to missing docstrings
# pylint: disable-msg=C0111

import os
import gtk
import gobject
import logging
import subprocess

import fontload

COMPARE_LS = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT)

DEFAULT_STYLES  =  ['Regular', 'Roman', 'Medium', 'Normal', 'Book']

# Note to translators: this should be a pangram (a sentence containing all
# letters of your alphabet. See http://en.wikipedia.org/wiki/Pangram for
# more information and possible samples for your language.
PREVIEW_TEXT = _("""The quick brown fox jumps over a lazy dog.
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
1234567890.:,;(*!?')""")
COMPARE_TEXT = _('The quick brown fox jumps over a lazy dog.')


class Views:
    """
    Sets up preview area
    """
    preview_text = PREVIEW_TEXT
    compare_text = COMPARE_TEXT
    # default colors
    preview_fgcolor = gtk.gdk.color_parse('black')
    preview_bgcolor = gtk.gdk.color_parse('white')
    mode = 'preview'
    colors_dialog = None
    have_gfw = False
    def __init__(self, parent=None, builder=None):
        if builder is None:
            self.builder = gtk.Builder()
            self.builder.set_translation_domain('font-manager')
        else:
            self.builder = builder
        self.parent = parent
        self.current_font = None
        self.current_style = None
        self.style_combo = gtk.combo_box_new_text()
        self.style_combo.set_focus_on_click(False)
        self.family_tv = self.builder.get_object('families_tree')
        self.family_tv.get_selection().connect("changed", self._font_changed)
        self.preview_scroll = self.builder.get_object('preview_scroll')
        self.compare_scroll = self.builder.get_object('compare_scroll')
        self.compare_tree = self.builder.get_object('compare_tree')
        self.preview = self.builder.get_object('font_preview')
        self.toggle = self.builder.get_object('compare_preview')
        self.toggle.connect('toggled', self.switch_mode)
        self.preview_column = gtk.TreeViewColumn()
        self.font_info = self.builder.get_object('font_info')
        self.cb_box = self.builder.get_object('compare_buttons_box')
        self.color_selector = self.builder.get_object('color_selector')
        self.tentry = self.builder.get_object('custom_text_entry')
        self.tentry.connect('changed', self.preview_text_changed)
        self.tentry.connect('icon-press', self.clear_custom_text)
        custom_text = self.builder.get_object('custom_text')
        custom_text.connect('toggled', self.custom_toggled)
        size_adjustment = self.builder.get_object('size_adjustment')
        # correct value on start
        size_adjustment.set_value(11)
        self.size = size_adjustment.get_value()
        # make it do something
        size_adjustment.connect('value-changed', self.on_size_adj_v_change)
        self.gucharmap = self.builder.get_object("gucharmap")
        if os.path.exists('/usr/bin/gucharmap') or \
        os.path.exists('/usr/local/bin/gucharmap'):
            self.gucharmap.connect('clicked', self.on_char_map)
            self.charmap = True
        else:
            self.gucharmap.hide()
            self.charmap = False
        self.check_for_gfw()
        self.setup_style_combo()
        self.init_compare_tree()
        return

    def init_compare_tree(self):
        self.compare_tree.set_model(COMPARE_LS)
        cell_render = gtk.CellRendererText()
        self.preview_column.pack_start(cell_render, True)
        self.preview_column.set_cell_data_func(cell_render, self.cell_data_cb)
        self.compare_tree.append_column(self.preview_column)
        compare_selection = self.compare_tree.get_selection()
        compare_selection.set_select_function(self._set_preview_row_selection)
        addb = self.builder.get_object('add_compare')
        delb = self.builder.get_object('remove_compare')
        clearb = self.builder.get_object('clear_compare')
        addb.connect('clicked', self.add_compare)
        delb.connect('clicked', self.remove_compare)
        clearb.connect('clicked', self.clear_compare)
        self.color_selector.connect('clicked', self.show_colors_dialog)

    def switch_mode(self, unused_widget):
        """
        Hides or shows widgets depending on selected mode
        """
        if self.toggle.get_active():
            self.mode = 'compare'
            self.preview_scroll.hide()
            self.update_compare_view()
            self.compare_scroll.show()
            self.toggle.set_label(_('Preview Fonts'))
            self.font_info.hide()
            self.color_selector.show()
            if self.charmap:
                self.gucharmap.hide()
            self.cb_box.show()
        elif not self.toggle.get_active():
            self.mode = 'preview'
            self.compare_scroll.hide()
            self.preview_scroll.show()
            self.toggle.set_label(_('Compare Fonts'))
            self.color_selector.hide()
            self.font_info.show()
            self.cb_box.hide()
            if self.charmap:
                self.gucharmap.show()

    def add_compare(self, unused_widget):
        lstore = COMPARE_LS
        lstore.append([self.current_style.to_string(), self.current_style])
        lstore.append([self.current_style.to_string(), self.current_style])
        self.select_last_preview()
        self.update_compare_view()
        return

    # Aside from a few functions most of the code in this section is either #
    #     'lifted' right out of gnome-specimen or heavily based on it.      #
    
    def remove_compare(self, unused_widget):
        """
        Removes selected entry from compare view
        """
        model, treeiter = self.compare_tree.get_selection().get_selected()
        if treeiter is not None:
            # Remove 2 rows
            model.remove(treeiter)
            still_valid = model.remove(treeiter)
            # Set the cursor to a remaining row instead of having the cursor
            # disappear. This allows for easy deletion of multiple previews by
            # hitting the Remove button repeatedly.
            if still_valid:
                # The treeiter is still valid. This means that there's another
                # row has "shifted" to the location the deleted row occupied
                # before. Set the cursor to that row.
                new_path = COMPARE_LS.get_path(treeiter)
                if (new_path[0] >= 0):
                    self.compare_tree.set_cursor(new_path)
            else:
                # The treeiter is no longer valid. In our case this means the
                # bottom row in the treeview was deleted. Set the cursor to the
                # new bottom font name row.
                self.select_last_preview()
        self.update_compare_view()
        return

    def clear_compare(self, unused_widget):
        """
        Removes all entries from compare view
        """
        COMPARE_LS.clear()
        self.update_compare_view()
        return

    def cell_data_cb(self, column, cell, model, treeiter):
        if model.get_path(treeiter)[0] % 2 == 0:
            # this is a name row
            cell.set_property('text', model.get_value(treeiter, 0))
            cell.set_property('font', 'Sans 11')
            cell.set_property('ypad', 2)
            cell.set_property('background', '#F7F7F7')
            cell.set_property('foreground', None)
        else:
            # this is a preview row
            cell.set_property('text', self.compare_text)
            cell.set_property('font-desc', model.get_value(treeiter, 1))
            cell.set_property('size-points', self.size)
            cell.set_property('ypad', 2)
            cell.set_property('background-gdk', self.preview_bgcolor)
            cell.set_property('foreground-gdk', self.preview_fgcolor)
        return

    def _set_preview_row_selection(self, path):
        """
        Prevents selection of rows which hold a preview
        """
        # http://bugzilla.gnome.org/show_bug.cgi?id=340475
        if (path[0] % 2) == 0:
            # this is a name row
            return True
        else:
            # this is a preview row
            path = (path[0]-1,)
            self.compare_tree.get_selection().select_path(path)
            return False

    def select_last_preview(self):
        path_to_select = COMPARE_LS.iter_n_children(None) - 2
        if (path_to_select >= 0):
            self.compare_tree.get_selection().select_path(path_to_select)
            # this the actual last row
            path_to_scroll_to = path_to_select + 1 
            if path_to_scroll_to > 1:
                # workaround strange row height bug for first title row
                self.compare_tree.scroll_to_cell(path_to_scroll_to)

    def update_compare_view(self):
        self.preview_column.queue_resize()
        self.compare_tree.queue_draw()
        return

    def preview_text_changed(self, widget):
        self.compare_text = widget.get_text()
        self.preview_text = widget.get_text()
        self.update_compare_view()
        self._set_preview_text(self.current_style)
        return

    def set_colors(self, fgcolor, bgcolor):
        """
        Sets the colors for the font previews
        """
        self.preview_fgcolor = fgcolor
        self.preview_bgcolor = bgcolor
        self.update_compare_view()

    def show_colors_dialog(self, unused_widget):
        """
        Shows the colors dialog
        """
        self.colors_dialog = gtk.Dialog(
                _('Change colors'),
                self.parent,
                gtk.DIALOG_DESTROY_WITH_PARENT,
                (gtk.STOCK_CLOSE, gtk.RESPONSE_CANCEL))
        self.colors_dialog.set_icon_name('gtk-select-color')
        self.colors_dialog.set_default_response(gtk.RESPONSE_ACCEPT)
        self.colors_dialog.set_resizable(False)
        self.colors_dialog.set_has_separator(False)
        # A table is used to layout the dialog
        table = gtk.Table(2, 2)
        table.set_border_width(12)
        table.set_col_spacings(6)
        table.set_homogeneous(True)
        # The widgets for the foreground color
        fglabel = gtk.Label(_('Foreground color:'))
        fgchooser = gtk.ColorButton()
        fgchooser.set_color(self.preview_fgcolor)
        table.attach(fglabel, 0, 1, 0, 1)
        table.attach(fgchooser, 1, 2, 0, 1)
        # The widgets for the background color
        bglabel = gtk.Label(_('Background color:'))
        bgchooser = gtk.ColorButton()
        bgchooser.set_color(self.preview_bgcolor)
        table.attach(bglabel, 0, 1, 1, 2)
        table.attach(bgchooser, 1, 2, 1, 2)
        self.colors_dialog.vbox.pack_start(table, True, True, 0)
        # Keep direct references to the buttons on the dialog itself. The
        # callback method for the color-set signal uses those retrieve the
        # color values (the colors_dialog is passed as user_data).
        self.colors_dialog.fgchooser = fgchooser
        self.colors_dialog.bgchooser = bgchooser
        fgchooser.connect\
        ('color-set', self.colors_dialog_color_changed_cb, self.colors_dialog)
        bgchooser.connect\
        ('color-set', self.colors_dialog_color_changed_cb, self.colors_dialog)
        # We abuse lambda functions here to handle the correct signals/events:
        # the window will be hidden (not destroyed) and can be used again
        self.colors_dialog.connect\
        ('response', lambda widget, response: self.colors_dialog.hide())
        self.colors_dialog.connect\
        ('delete-event', lambda widget, event: widget.hide() or True)
        # Show the dialog
        self.colors_dialog.show_all()
        self.colors_dialog.present()

    def colors_dialog_color_changed_cb(self, button, dialog):
        """
        Updates the colors when the color buttons have changed
        """
        fgcolor = dialog.fgchooser.get_color()
        bgcolor = dialog.bgchooser.get_color()
        self.set_colors(fgcolor, bgcolor)

    #########################################################################

    def custom_toggled(self, widget):
        """
        Shows or hides the custom text entry widget depending on toggle state
        """
        if widget.get_active():
            self.tentry.show()
            self.tentry.grab_focus()
            widget.set_label(_('Hide text entry'))
        else:
            self.tentry.hide()
            widget.set_label(_('Custom Text'))
            
    def clear_custom_text(self, unused_widget, unused_x, unused_y):
        """
        Clears text entry when clear icon is clicked
        """
        self.tentry.set_text('')
        self.compare_text = COMPARE_TEXT
        self.preview_text = PREVIEW_TEXT
        self.update_compare_view()
        self._set_preview_text(self.current_style)
        return

    def setup_style_combo(self):
        """
        Sets up style selection combo
        """
        fsb = self.builder.get_object("font_size_box")
        fsb.pack_end(self.style_combo, False, False)
        self.style_combo.connect('changed', self._on_style_changed)
        self.style_combo.show()
        return

    def check_for_gfw(self):
        """
        Enables the font info button if gnome-font-viewer is
        found on the system
        """
        gfw = '/usr/bin/gnome-font-viewer'
        lgfw = '/usr/local/bin/gnome-font-viewer'
        font_info = self.builder.get_object('font_info')
        if os.path.exists(gfw) or os.path.exists(lgfw):
            font_info.connect('clicked', self._on_font_info)
            self.have_gfw = True
        else:
            font_info.set_sensitive(False)
            font_info.set_tooltip_text\
            (_('This feature requires gnome-font-viewer'))
            
    def on_char_map(self, unused_widget):
        """
        Launches gucharmap with the currently selected font active
        """
        font = self.current_style.to_string()
        try:
            logging.info("Launching GNOME Character Map")
            subprocess.Popen(['gucharmap', '--font=%s 22' % font])
        except OSError, error:
            logging.error("Error: %s" % error)
        return
    
    def _font_changed(self, sel):
        """
        Calls _change_font with the newly selected font
        """
        tree = sel
        model, path_list = tree.get_selected_rows()
        try:
            obj = model[path_list[0]][1]
        except IndexError:
            return
        if isinstance(obj, fontload.Family):
            self._change_font(obj)
            if obj.enabled:
                self.gucharmap.set_sensitive(True)
            else:
                self.gucharmap.set_sensitive(False)
        return

    def _on_style_changed(self, unused_widget):
        """
        Updates preview when a different style is selected
        """
        if self.style_combo.get_active() < 0:
            return
        try:
            style = self.style_combo.get_model()\
            [self.style_combo.get_active()][0]
        except IndexError:
            logging.warn('Font failed to provide style information')
            return
        if style in self.current_font.filelist and self.have_gfw:
            self.font_info.set_sensitive(True)
        else:
            self.font_info.set_sensitive(False)
        faces = sorted(self.current_font.pango_family.list_faces(),
                cmp=lambda x, y: cmp(x.get_face_name(), y.get_face_name()))
        for face in faces:
            if face.get_face_name() == style:
                descr = face.describe()
                self._set_preview_text(descr)
                self.current_style = descr
                return

    def _change_font(self, font):
        """
        Updates preview when a new font is selected
        """
        self.current_font = font
        self.style_combo.get_model().clear()
        faces = sorted(font.pango_family.list_faces(),
                cmp=lambda x, y: cmp(x.get_face_name(), y.get_face_name()))
        selected_face = None
        active = -1
        i = 0
        added = []
        for face in faces:
            if face not in added:
                self.style_combo.append_text(face.get_face_name())
            if face.get_face_name() in DEFAULT_STYLES or not selected_face:
                selected_face = face
                active = i
            i += 1
        self.style_combo.set_active(active)
        if selected_face:
            descr = selected_face.describe()
            self._set_preview_text(descr)
        return

    def on_size_adj_v_change(self, widget):
        """
        Updates preview when font size is changed
        """
        self.size = widget.get_value()
        self._set_preview_text(self.current_style)
        if self.mode == 'compare':
            self.update_compare_view()
        return

    def _on_font_info(self, unused_widget):
        """
        Displays detailed font information

        Requires gnome-font-viewer to be installed
        """
        font = self.current_font
        style = self.style_combo.get_model()[self.style_combo.get_active()][0]
        fontfile = font.filelist[style]
        try:
            subprocess.Popen(['gnome-font-viewer', fontfile])
        except (TypeError, IndexError):
            self._font_info_unavailable()    
        except OSError, error:
            logging.error("Error opening font file: %s" % error)
            self._font_info_unavailable()
        return

    def _set_preview_text(self, descr):
        """
        Sets up sample text
        """
        buff = self.preview.get_buffer()
        buff.set_text("", 0)
        size = self.size
        tag = buff.create_tag(None, font_desc=descr, size_points=size)
        buff.insert_with_tags\
        (buff.get_end_iter(), descr.to_string() + '\n', tag)
        buff.insert_with_tags\
        (buff.get_end_iter(), '\n' + self.preview_text + '\n', tag)
        self.current_style = descr
        return

    def _font_info_unavailable(self):
        """
        Displays a dialog if we couldn't load specified file
        """
        dialog = gtk.MessageDialog(self.parent,
        gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_ERROR,
        gtk.BUTTONS_CLOSE,
        _("Sorry could not load information for selected font"))
        dialog.set_title(_("Unavailable"))
        dialog.run()
        dialog.destroy()
        return
