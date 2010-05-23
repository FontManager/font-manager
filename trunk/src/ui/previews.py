"""
This module handles everything related to the font preview area.
"""
# Font Manager, a font management application for the GNOME desktop
#
# Copyright (C) 2009, 2010 Jerry Casiano
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to:
#
#    Free Software Foundation, Inc.
#    51 Franklin Street, Fifth Floor
#    Boston, MA 02110-1301, USA.

# Disable warnings related to gettext
# pylint: disable-msg=E0602

import gtk
import gobject
import logging
import subprocess

from os.path import basename

from fontinfo import FontInformation


DEFAULT_STYLES  =  ['Regular', 'Roman', 'Medium', 'Normal', 'Book']
DEFAULT_PREVIEW_SIZE = 11
# Note to translators: this should be a pangram (a sentence containing all
# letters of your alphabet. See http://en.wikipedia.org/wiki/Pangram for
# more information and possible samples for your language.
PREVIEW_TEXT = _("""The quick brown fox jumps over the lazy dog.
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
1234567890.:,;(*!?')""")
COMPARE_TEXT = _('The quick brown fox jumps over the lazy dog.')


class Previews(object):
    def __init__(self, objects):
        self.objects = objects
        self.manager = self.objects['FontManager']
        self.preview_text = PREVIEW_TEXT
        self.compare_text = COMPARE_TEXT
        self.preview_fgcolor = gtk.gdk.color_parse('black')
        self.preview_bgcolor = gtk.gdk.color_parse('white')
        self.mode = 'preview'
        self.current_family = None
        self.current_style = None
        self.current_style_as_string = None
        self.info_dialog = None
        self.compare_tree = self.objects['CompareTree']
        self.objects['CompareFonts'].connect('toggled', self._on_switch_mode)
        # Get selected family
        selection = self.objects['FamilyTree'].get_selection()
        selection.connect("changed", self._on_font_changed)
        # Setup for custom text entry
        text_entry = self.objects['CustomTextEntry']
        text_entry.connect('changed', self._on_preview_text_changed)
        text_entry.connect('icon-press', self._on_clear_custom_text)
        self.objects['CustomText'].connect('toggled', self._on_custom_toggled)
        # Correct value on start
        size_adjustment = self.objects['SizeAdjustment']
        size_adjustment.set_value(DEFAULT_PREVIEW_SIZE)
        self.size = DEFAULT_PREVIEW_SIZE
        # Make it do something
        size_adjustment.connect('value-changed', self._on_size_adj_v_change)
        # Gnome Character Map
        character_map = self.objects['CharacterMap']
        character_map.connect('clicked', self.on_char_map)
        if not 'gucharmap' in self.objects['AvailableApps']:
            character_map.set_sensitive(False)
            character_map.set_tooltip_text(_('This feature requires Gucharmap'))
        self.objects['StyleCombo'].connect('changed', self._on_style_changed)
        self.objects['FontInformation'].connect('clicked', self._on_font_info)
        self._init_compare_tree()

    def _init_compare_tree(self):
        compare_model = gtk.ListStore(gobject.TYPE_STRING,
                                        gobject.TYPE_PYOBJECT)
        self.compare_tree.set_model(compare_model)
        cell_renderer = gtk.CellRendererText()
        preview_column = gtk.TreeViewColumn()
        preview_column.pack_start(cell_renderer, True)
        preview_column.set_cell_data_func(cell_renderer, self._cell_data_cb)
        self.compare_tree.append_column(preview_column)
        compare_selection = self.compare_tree.get_selection()
        compare_selection.set_select_function(self._set_preview_row_selection)
        self.objects['AddToCompare'].connect('clicked', self._on_add_compare)
        self.objects['RemoveFromCompare'].connect('clicked',
                                                    self._on_remove_compare)
        self.objects['ClearComparison'].connect('clicked',
                                                        self._on_clear_compare)
        self.objects['ColorSelect'].connect('clicked',
                                                    self._on_show_colors_dialog)

    def _on_switch_mode(self, unused_widget):
        """
        Hide or shows widget depending on selected mode.
        """
        toggle = self.objects['CompareFonts']
        preview = self.objects['PreviewScroll']
        compare = self.objects['CompareScroll']
        compare_buttons = self.objects['CompareButtonsBox']
        color_selector = self.objects['ColorSelect']
        character_map = self.objects['CharacterMap']
        font_info = self.objects['FontInformation']
        if toggle.get_active():
            self.mode = 'compare'
            preview.hide()
            compare.show()
            self.update_compare_view()
            toggle.set_label(_('Preview Fonts'))
            character_map.hide()
            font_info.hide()
            color_selector.show()
            compare_buttons.show()
        else:
            self.mode = 'preview'
            compare.hide()
            preview.show()
            toggle.set_label(_('Compare Fonts'))
            color_selector.hide()
            compare_buttons.hide()
            character_map.show()
            font_info.show()

    def _on_add_compare(self, unused_widget):
        lstore = self.compare_tree.get_model()
        lstore.append([self.current_style.to_string(), self.current_style])
        lstore.append([self.current_style.to_string(), self.current_style])
        self._select_last_preview()
        self.update_compare_view()
        return

    #  Aside from minor changes most of the code in this section is either  #
    #     'lifted' right out of gnome-specimen or heavily based on it.      #

    def _on_remove_compare(self, unused_widget):
        """
        Remove selected entry from compare view.
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
                new_path = self.compare_tree.get_model().get_path(treeiter)
                if (new_path[0] >= 0):
                    self.compare_tree.set_cursor(new_path)
            else:
                # The treeiter is no longer valid. In our case this means the
                # bottom row in the treeview was deleted. Set the cursor to the
                # new bottom font name row.
                self._select_last_preview()
        self.update_compare_view()
        return

    def _on_clear_compare(self, unused_widget):
        """
        Remove all entries from compare view.
        """
        self.compare_tree.get_model().clear()
        self.update_compare_view()
        return

    def _cell_data_cb(self, column, cell, model, treeiter):
        cellset = cell.set_property
        if model.get_path(treeiter)[0] % 2 == 0:
            # this is a name row
            cellset('text', model.get_value(treeiter, 0))
            cellset('font', 'Sans 11')
            cellset('ypad', 2)
            cellset('background', '#F7F7F7')
            cellset('foreground', None)
        else:
            # this is a preview row
            cellset('text', self.compare_text)
            cellset('font-desc', model.get_value(treeiter, 1))
            cellset('size-points', self.size)
            cellset('ypad', 2)
            cellset('background-gdk', self.preview_bgcolor)
            cellset('foreground-gdk', self.preview_fgcolor)
        return

    def _set_preview_row_selection(self, path):
        """
        Prevent selection of rows which hold a preview.
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

    def _select_last_preview(self):
        model = self.compare_tree.get_model()
        path_to_select = model.iter_n_children(None) - 2
        if (path_to_select >= 0):
            self.compare_tree.get_selection().select_path(path_to_select)
            # this the actual last row
            path_to_scroll_to = path_to_select + 1
            if path_to_scroll_to > 1:
                # workaround strange row height bug for first title row
                self.compare_tree.scroll_to_cell(path_to_scroll_to)

    def update_compare_view(self):
        """
        Queue redraw on the comparison view.
        """
        self.compare_tree.get_column(0).queue_resize()
        self.compare_tree.queue_draw()
        return

    def _on_preview_text_changed(self, widget):
        self.compare_text = self.preview_text = widget.get_text()
        self.update_compare_view()
        self._set_preview_text(self.current_style)
        return

    def set_colors(self, fgcolor, bgcolor):
        """
        Set the colors for font previews.
        """
        self.preview_fgcolor = fgcolor
        self.preview_bgcolor = bgcolor
        self.update_compare_view()

    def _on_show_colors_dialog(self, unused_widget):
        """
        Show the colors dialog.
        """
        dialog = self.objects['ColorSelector']
        # We abuse lambda functions here to handle the correct signals/events:
        # the window will be hidden (not destroyed) and can be used again
        dialog.connect('delete-event', \
                                lambda widget, event: widget.hide() or True)
        self.objects['CloseColorSelector'].connect('clicked', \
                                        lambda widget: dialog.hide() or True)
        self.objects['ForegroundColor'].connect('color-set',
                                                        self._on_colors_changed)
        self.objects['BackgroundColor'].connect('color-set',
                                                        self._on_colors_changed)
        dialog.show()
        dialog.present()

    def _on_colors_changed(self, unused_widget):
        """
        Update font and background colors.
        """
        fgcolor = self.objects['ForegroundColor'].get_color()
        bgcolor = self.objects['BackgroundColor'].get_color()
        self.set_colors(fgcolor, bgcolor)

    #########################################################################

    def _on_custom_toggled(self, widget):
        """
        Show or hide the custom text entry widget depending on toggle state.
        """
        text_entry = self.objects['CustomTextEntry']
        if widget.get_active():
            text_entry.show()
            text_entry.grab_focus()
            widget.set_label(_('Hide text entry'))
        else:
            text_entry.hide()
            widget.set_label(_('Custom Text'))

    def _on_clear_custom_text(self, unused_widget, unused_x, unused_y):
        """
        Clear text entry when clear icon is clicked.
        """
        self.objects['CustomTextEntry'].set_text('')
        self.compare_text = COMPARE_TEXT
        self.preview_text = PREVIEW_TEXT
        self.update_compare_view()
        self._set_preview_text(self.current_style)
        return

    def on_char_map(self, unused_widget):
        """
        Launch gucharmap with the currently selected font active
        """
        try:
            logging.info("Launching GNOME Character Map")
            font = self.current_style.to_string()
            subprocess.Popen(['gucharmap', '--font=%s 22' % font])
        except OSError, error:
            logging.error("Error: %s" % error)
        return

    def _on_font_changed(self, tree):
        """
        Update preview when a new font is selected.
        """
        enable_font = self.objects['EnableFamily']
        disable_font = self.objects['DisableFamily']
        character_map = self.objects['CharacterMap']
        model, path_list = tree.get_selected_rows()
        try:
            family = model[path_list[0]][0]
            self.current_family = self.manager[family]
        except IndexError:
            return
        self._change_font()
        if self.current_family.enabled:
            enable_font.set_sensitive(False)
            disable_font.set_sensitive(True)
            if 'gucharmap' in self.objects['AvailableApps']:
                character_map.set_sensitive(True)
        else:
            enable_font.set_sensitive(True)
            disable_font.set_sensitive(False)
            character_map.set_sensitive(False)
        return

    def _on_style_changed(self, unused_widget):
        """
        Update preview when a different style is selected.
        """
        style_combo = self.objects['StyleCombo']
        character_map = self.objects['CharacterMap']
        font_information = self.objects['FontInformation']
        if style_combo.get_active() < 0:
            return
        style = style_combo.get_model()[style_combo.get_active()][0]
        self.current_style_as_string = style
        valid_styles = _('Bold'), _('Bold Italic'), _('Italic')
        if style in self.current_family.styles.iterkeys() or \
        style in valid_styles:
            character_map.set_sensitive(True)
        else:
            character_map.set_sensitive(False)
        if style in self.current_family.styles.iterkeys():
            font_information.set_sensitive(True)
        else:
            font_information.set_sensitive(False)
        faces = sorted(self.current_family.pango_family.list_faces(),
                cmp=lambda x, y: cmp(x.get_face_name(), y.get_face_name()))
        for face in faces:
            if face.get_face_name() == style:
                descr = face.describe()
                self._set_preview_text(descr)
                self.current_style = descr
                return

    def _change_font(self):
        """
        Update preview when a new font is selected.
        """
        style_combo = self.objects['StyleCombo']
        style_combo.get_model().clear()
        family = self.current_family.pango_family
        faces = sorted(family.list_faces(),
                cmp=lambda x, y: cmp(x.get_face_name(), y.get_face_name()))
        selected_face = None
        active = -1
        i = 0
        added = []
        for face in faces:
            if face not in added:
                style_combo.append_text(face.get_face_name())
            if face.get_face_name() in DEFAULT_STYLES or not selected_face:
                selected_face = face
                active = i
            i += 1
        style_combo.set_active(active)
        if selected_face:
            descr = selected_face.describe()
            self._set_preview_text(descr)

        return

    def _on_size_adj_v_change(self, widget):
        """
        Update preview when font size is changed.
        """
        self.size = widget.get_value()
        self._set_preview_text(self.current_style)
        if self.mode == 'compare':
            self.update_compare_view()
        return

    def _set_preview_text(self, descr):
        """
        Set preview text.
        """
        t_buffer = gtk.TextBuffer()
        preview = self.objects['FontPreview']
        preview.set_buffer(t_buffer)
        size = self.size
        tag = t_buffer.create_tag(None, font_desc=descr, size_points=size)
        t_buffer.insert(t_buffer.get_end_iter(), descr.to_string() + '\n')
        t_buffer.insert(t_buffer.get_end_iter(), '\n' + self.preview_text + '\n')
        t_buffer.apply_tag(tag, t_buffer.get_start_iter(),
                                    t_buffer.get_end_iter())

        style_combo = self.objects['StyleCombo']
        style = style_combo.get_model()[style_combo.get_active()][0]
        if not style in self.current_family.styles.iterkeys():
            tooltip = \
            _('Style provided by the rendering library.')
        else:
            filepath = self.current_family.styles[style]['filepath']
            tooltip = \
            _('Style provided by %s' % basename(filepath))
        style_combo.set_tooltip_text(tooltip)
        return

    def _on_font_info(self, unused_widget):
        if not self.info_dialog:
            self.info_dialog = FontInformation(self.objects)
        self.info_dialog.show(self.current_family, self.current_style,
                                        self.current_style_as_string)
        return
