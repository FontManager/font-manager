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
# Disable warnings related to missing docstrings, for now...
# pylint: disable-msg=C0111

import gtk
import glib
import gobject
import logging
import subprocess

from os.path import basename

from constants import COMPARE_TEXT, DEFAULT_STYLES, PREVIEW_TEXT, \
                        STANDARD_TEXT, LOCALIZED_TEXT
from ui.fontinfo import FontInformation
from utils.common import begin_drag, correct_slider_behavior

TARGET_TYPE_BROWSE_ROW = 30
TARGET_TYPE_COMPARE_ROW = 50

BROWSE_DRAG_TARGETS = [('browser_add', gtk.TARGET_SAME_APP, TARGET_TYPE_BROWSE_ROW)]
BROWSE_DRAG_ACTIONS = (gtk.gdk.ACTION_DEFAULT | gtk.gdk.ACTION_MOVE)
COMPARE_DRAG_TARGETS = [('reorder', gtk.TARGET_SAME_WIDGET, TARGET_TYPE_COMPARE_ROW)]
COMPARE_DRAG_ACTIONS = (gtk.gdk.ACTION_DEFAULT | gtk.gdk.ACTION_MOVE)


def set_preview_text(use_localized_sample):
    global PREVIEW_TEXT
    global COMPARE_TEXT
    if use_localized_sample:
        PREVIEW_TEXT = PREVIEW_TEXT.format(LOCALIZED_TEXT)
        COMPARE_TEXT = COMPARE_TEXT.format(LOCALIZED_TEXT)
    else:
        PREVIEW_TEXT = PREVIEW_TEXT.format(STANDARD_TEXT)
        COMPARE_TEXT = COMPARE_TEXT.format(STANDARD_TEXT)
    return


class Previews(object):
    def __init__(self, objects):
        self.objects = objects
        self.manager = self.objects['FontManager']
        self.preferences = self.objects['Preferences']
        set_preview_text(self.objects['Preferences'].localized)
        self.preview_text = PREVIEW_TEXT
        self.compare_text = COMPARE_TEXT
        self.preview_fgcolor = gtk.gdk.color_parse(self.preferences.fgcolor)
        self.preview_bgcolor = gtk.gdk.color_parse(self.preferences.bgcolor)
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
        self.size = self.objects['Preferences'].previewsize
        size_adjustment = self.objects['SizeAdjustment']
        size_adjustment.set_value(self.size)
        # Make it do something
        size_adjustment.connect('value-changed', self._on_size_adj_v_change)
        # Correct slider behavior - up means up, down means down
        self.objects['FontSizeSlider'].connect('scroll-event',
                                                correct_slider_behavior, 1.0)
        # Gnome Character Map
        character_map = self.objects['CharacterMap']
        character_map.connect('clicked', self.on_char_map)
        if not 'gucharmap' in self.objects['AppCache']:
            character_map.set_sensitive(False)
            character_map.set_tooltip_text(_('This feature requires Gucharmap'))
        self.objects['StyleCombo'].connect('changed', self._on_style_changed)
        self.objects['FontInformation'].connect('clicked', self._on_font_info)
        self._init_compare_tree()
        self.objects['BrowseFonts'].connect('clicked', self._on_browse_fonts)
        self.objects['BackButton'].connect('clicked', self._on_browse_fonts)

    def _init_compare_tree(self):
        compare_model = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_PYOBJECT)
        self.compare_tree.set_model(compare_model)
        cell_renderer = gtk.CellRendererText()
        preview_column = gtk.TreeViewColumn()
        preview_column.pack_start(cell_renderer, True)
        preview_column.set_cell_data_func(cell_renderer, self._cell_data_cb)
        self.compare_tree.append_column(preview_column)
        compare_selection = self.compare_tree.get_selection()
        compare_selection.set_select_function(self._set_preview_row_selection)
        self.compare_tree.enable_model_drag_dest(COMPARE_DRAG_TARGETS,
                                                    COMPARE_DRAG_ACTIONS)
        self.compare_tree.enable_model_drag_source\
                                (gtk.gdk.BUTTON1_MASK | gtk.gdk.RELEASE_MASK,
                                    COMPARE_DRAG_TARGETS, COMPARE_DRAG_ACTIONS)
        self.compare_tree.connect('drag-data-received',
                                            self._on_drag_data_received)
        self.compare_tree.connect_after('drag-begin', self._on_begin_drag)
        self.objects['AddToCompare'].connect('clicked', self._on_add_compare)
        self.objects['RemoveFromCompare'].connect('clicked',
                                                    self._on_remove_compare)
        self.objects['ClearComparison'].connect('clicked',
                                                        self._on_clear_compare)
        self.objects['ColorSelect'].connect('clicked',
                                                    self._on_show_colors_dialog)
        return

    def _on_browse_fonts(self, widget):
        if widget == self.objects['BrowseFonts']:
            self.objects['MainNotebook'].set_current_page(1)
            collection = self.objects['Treeviews'].current_collection
            families = self.manager.list_families_in(collection)
            self.objects['FontBrowser'].update_tree(families)
            self.objects['Treeviews'].set_direct_select()
        else:
            # Clearing the font browser prevents the interface from hanging
            self.objects['FontBrowser'].update_tree([])
            self.objects['MainNotebook'].set_current_page(0)
            self.objects['Treeviews'].update_views(True)
            self.objects['Treeviews'].set_indirect_select()
        return

    def _on_begin_drag(self, widget, context):
        model, treeiter = self.compare_tree.get_selection().get_selected()
        font = model.get_value(treeiter, 0)
        win = gtk.Window(gtk.WINDOW_POPUP)
        preview = gtk.Label()
        preview.set_markup('<span size="x-large"> {0} \n\n</span><span \
                    font_desc="{1}" size="xx-large"> {2} </span>'.format(
                    font, font, self.compare_text))
        preview.set_padding(4, 4)
        win.add(preview)
        win.set_title('You should NOT be seeing this window frame!')
        win.set_decorated(False)
        win.set_opacity(0.95)
        win.show_all()
        win.set_transient_for(self.objects['MainWindow'])
        context.set_icon_widget(win, 0, 0)
        return

    # Gets really ugly here dragging and dropping two separate rows...
    # Seems to work though :-D
    def _on_drag_data_received(self, widget, context, x, y, data, info, tstamp):
        assert(info == TARGET_TYPE_COMPARE_ROW)
        treeiter = widget.get_selection().get_selected()[1]
        model = widget.get_model()
        orig_path = model.get_path(treeiter)[0]
        assert(orig_path % 2 == 0)
        data = model.get(treeiter, 0, 1)
        drop_info = widget.get_dest_row_at_pos(x, y)
        if drop_info:
            path, position = drop_info
            if path[0] == orig_path or path[0] - 2 == orig_path \
            or path[0] - 1 == orig_path:
                return
            if position == gtk.TREE_VIEW_DROP_BEFORE:
                if path[0] % 2 != 0:
                    return
                try:
                    treeiter = model.get_iter(path)
                    del model[orig_path + 1]
                    del model[orig_path]
                    treeiter = model.insert_before(treeiter, data)
                    treeiter = model.insert_before(treeiter, data)
                except ValueError:
                    return
            elif position == gtk.TREE_VIEW_DROP_AFTER:
                if path[0] % 2 == 0:
                    return
                try:
                    treeiter = model.get_iter(path)
                    del model[orig_path + 1]
                    del model[orig_path]
                    treeiter = model.insert_after(treeiter, data)
                    treeiter = model.insert_before(treeiter, data)
                except ValueError:
                    del model[orig_path + 1]
                    del model[orig_path]
                    treeiter = model.append(data)
                    treeiter = model.append(data)
            else:
                return
        else:
            del model[orig_path + 1]
            del model[orig_path]
            treeiter = model.append(data)
            treeiter = model.append(data)
        path = model.get_path(treeiter)
        if path:
            widget.get_selection().select_path(path)
        self.update_compare_view()
        return

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
        return

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
        style = self.compare_tree.get_style()
        # pango.SCALE doesn't work as expected, this does...
        scale = 9216
        font_desc = style.font_desc
        font_desc.set_size(int(scale * 1.2))
        cellset = cell.set_property
        if model.get_path(treeiter)[0] % 2 == 0:
            # this is a name row
            cellset('text', model.get_value(treeiter, 0))
            cellset('font_desc', font_desc)
            cellset('ypad', 2)
            cellset('background', style.base[gtk.STATE_NORMAL])
            cellset('foreground', style.text[gtk.STATE_NORMAL])
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
        return

    def update_compare_view(self):
        """
        Queue redraw on the comparison view.
        """
        self.compare_tree.queue_draw()
        self.compare_tree.get_column(0).queue_resize()
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
        return

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
        self.objects['ForegroundColor'].set_property('color',
                                                        self.preview_fgcolor)
        self.objects['BackgroundColor'].set_property('color',
                                                        self.preview_bgcolor)
        self.objects['ForegroundColor'].connect('color-set',
                                                        self._on_colors_changed)
        self.objects['BackgroundColor'].connect('color-set',
                                                        self._on_colors_changed)
        dialog.show()
        dialog.present()
        return

    def _on_colors_changed(self, unused_widget):
        """
        Update font and background colors.
        """
        fgcolor = self.objects['ForegroundColor'].get_color()
        bgcolor = self.objects['BackgroundColor'].get_color()
        self.preferences.fgcolor = fgcolor.to_string()
        self.preferences.bgcolor = bgcolor.to_string()
        self.set_colors(fgcolor, bgcolor)
        return

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
        return

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
            subprocess.Popen(['gucharmap', '--font={0} 22'.format(font)])
        except OSError, error:
            logging.error("Error: {0}".format(error))
        return

    def _on_font_changed(self, treeselection):
        """
        Update preview when a new font is selected.
        """
        enable_font = self.objects['EnableFamily']
        disable_font = self.objects['DisableFamily']
        character_map = self.objects['CharacterMap']
        model, path_list = treeselection.get_selected_rows()
        try:
            family = model[path_list[0]][0]
            self.current_family = self.manager[family]
        except (IndexError, KeyError):
            return
        self._change_font()
        if self.current_family.enabled:
            enable_font.set_sensitive(False)
            disable_font.set_sensitive(True)
            if 'gucharmap' in self.objects['AppCache']:
                character_map.set_sensitive(True)
        else:
            enable_font.set_sensitive(True)
            disable_font.set_sensitive(False)
            character_map.set_sensitive(False)
        return

    def _on_style_changed(self, widget):
        """
        Update preview when a different style is selected.
        """
        character_map = self.objects['CharacterMap']
        font_information = self.objects['FontInformation']
        if widget.get_active() < 0:
            return
        style = widget.get_active_text()
        self.current_style_as_string = style
        valid_styles = ('Bold', 'Bold Italic', 'Italic',
                        _('Bold'), _('Bold Italic'), _('Italic'))
        if self.current_family.enabled and \
        'gucharmap' in self.objects['AppCache']:
            if style in self.current_family.styles.iterkeys() or \
            style in valid_styles:
                character_map.set_sensitive(True)
            else:
                character_map.set_sensitive(False)
        else:
            character_map.set_sensitive(False)
        if style in self.current_family.styles.iterkeys():
            font_information.set_sensitive(True)
        else:
            font_information.set_sensitive(False)
        for face in self.current_family.pango_family.list_faces():
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
        selected_face = None
        active = None
        i = 0
        for face in family.list_faces():
            style_combo.append_text(face.get_face_name())
            if face.get_face_name() in DEFAULT_STYLES or not selected_face:
                if face.get_face_name() in self.current_family.styles.keys():
                    selected_face = face
                    active = i
            i += 1
        if active is None:
            active = 0
        style_combo.set_active(active)
        if selected_face:
            descr = selected_face.describe()
        else:
            descr = family.list_faces()[0].describe()
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
        self.objects['Preferences'].previewsize = self.size
        return

    def _set_preview_text(self, descr):
        """
        Set preview text.
        """
        self.current_style = descr
        t_buffer = gtk.TextBuffer()
        preview = self.objects['FontPreview']
        preview.set_buffer(t_buffer)
        size = self.size
        tag = t_buffer.create_tag(None, font_desc=descr, size_points=size,
                                    wrap_mode=gtk.WRAP_WORD)
        t_buffer.insert(t_buffer.get_end_iter(),
                        '{0} {1}\n'.format(self.current_family.get_name(),
                                            self.current_style_as_string))
        t_buffer.insert(t_buffer.get_end_iter(), '\n' + self.preview_text)
        t_buffer.apply_tag(tag, t_buffer.get_start_iter(),
                                    t_buffer.get_end_iter())
        style_combo = self.objects['StyleCombo']
        style = style_combo.get_model()[style_combo.get_active()][0]
        if not style in self.current_family.styles.iterkeys():
            tooltip = _('Style provided by the rendering library.')
        else:
            filepath = self.current_family.styles[style]['filepath']
            tooltip = _('Style provided by {0}'.format(basename(filepath)))
        style_combo.set_tooltip_text(tooltip)
        if self.info_dialog:
            if self.info_dialog.window.get_property('visible'):
                self._on_font_info(None)
        return

    def _on_font_info(self, unused_widget):
        """
        Display font metadata dialog.
        """
        if not self.info_dialog:
            self.info_dialog = FontInformation(self.objects)
        try:
            self.info_dialog.show(self.current_family.styles\
                                [self.current_style_as_string]['filepath'],
                                self.current_style)
        except KeyError:
            self.info_dialog.show(None, None)
        return


class FontBrowser(object):
    """
    Create a treeview containing inline previews of all fonts.
    """
    def __init__(self, objects):
        self.objects = objects
        self.browse_tree = self.objects['BrowseTree']
        self.families = self.objects['FontManager'].list_families()
        self.treestore = gtk.TreeStore(gobject.TYPE_STRING,
                                    gobject.TYPE_PYOBJECT, gobject.TYPE_BOOLEAN,
                                    gobject.TYPE_BOOLEAN, gobject.TYPE_STRING)
        self.browse_tree.set_model(self.treestore)
        renderer = gtk.CellRendererText()
        renderer.set_property('ypad', 3)
        column = gtk.TreeViewColumn(None, renderer)
        column.set_cell_data_func(renderer, self._cell_data_cb)
        self.browse_tree.append_column(column)
        self.browse_tree.get_selection().set_select_function(self._on_select)
        self.browse_tree.enable_model_drag_source\
                                (gtk.gdk.BUTTON1_MASK | gtk.gdk.RELEASE_MASK,
                                    BROWSE_DRAG_TARGETS, BROWSE_DRAG_ACTIONS)
        self.browse_tree.connect_after('drag-begin', begin_drag)
        self.size = self.objects['Preferences'].previewsize
        size_adjustment = self.objects['SizeAdjustment']
        # Make it do something
        size_adjustment.connect('value-changed', self.update_browse_view)
        # Correct slider behavior - up means up, down means down
        self.objects['BrowseSizeSlider'].connect('scroll-event',
                                                correct_slider_behavior, 1.0)

    def _on_select(self, path):
        model = self.browse_tree.get_model()
        if model.get_value(model.get_iter(path), 3):
            return True
        else:
            self.browse_tree.get_selection().select_path(path[0])
            return False

    def update_tree(self, families, scroll_to_top = True):
        self.families = families
        self.objects['BrowseScroll'].set_sensitive(False)
        self.treestore.clear()
        self._populate_browse_tree()
        self.objects['BrowseScroll'].set_sensitive(True)
        if scroll_to_top:
            self.browse_tree.scroll_to_point(0, 0)
        return

    def _cell_data_cb(self, column, cell, model, treeiter):
        style = self.browse_tree.get_style()
        font_desc = style.font_desc
        font_desc.set_weight(700)
        cellset = cell.set_property
        if len(model.get_path(treeiter)) < 2:
            # this is a top level row
            cellset('markup', model.get_value(treeiter, 0))
            cellset('font_desc', font_desc)
            cellset('size-points', self.size * 1.25)
            cellset('ypad', 2)
            cellset('strikethrough', model.get_value(treeiter, 2))
        else:
            # this is a preview row
            cellset('markup', model.get_value(treeiter, 0))
            cellset('font_desc', model.get_value(treeiter, 1))
            cellset('size-points', self.size)
            cellset('ypad', 2)
            cellset('strikethrough', model.get_value(treeiter, 2))
        return

    def _populate_browse_tree(self):
        # temporarily disconnect the model
        self.browse_tree.set_model(None)
        for family in self.families:
            obj = self.objects['FontManager'][family]
            root_node = self.treestore.append(None,
                [glib.markup_escape_text(family), None, False, True, family])
            for style in obj.pango_family.list_faces():
                displaytext = '{0} {1}'.format(glib.markup_escape_text(family),
                            glib.markup_escape_text(style.get_face_name()))
                self.treestore.append(root_node,
                [displaytext, style.describe(), not obj.enabled, False, family])
        # reconnect the model
        self.browse_tree.set_model(self.treestore)
        self.browse_tree.expand_all()
        return

    def update_browse_view(self, widget):
        """
        Queue redraw on the browse view.
        """
        self.size = widget.get_value()
        self.objects['Preferences'].previewsize = self.size
        self.browse_tree.queue_draw()
        self.browse_tree.get_column(0).queue_resize()
        return

