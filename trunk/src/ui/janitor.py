"""
This module provides a GUI which allows users to easily clean imported folders.
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

import os
import gtk
import gio
import gobject
import logging
import shutil

from os.path import exists, join, split, splitext

from constants import COMPARE_TEXT, FONT_EXTS, LOCALIZED_TEXT, \
                        PACKAGE_DATA_DIR, STANDARD_TEXT
from core.database import Table
from utils.common import correct_slider_behavior, filename_is_questionable, \
                            filename_is_illegal, natural_sort

( FAMILY, FILENAME, SUGGESTED_FILENAME, FILETYPE, FILESIZE, FILEPATH,
  PS_NAME, PANGO_NAME, PANGO_DESC, FONT_DESC, ACTIVE, INCONSISTENT,
  BG_COLOR, REMOVE ) = range(14)

( MISSING_PSNAME, INVALID_PSNAME, UNUSABLE ) = range(3)

COLUMNS = [ _('Family'), _('Filename'), _('Suggested Filename'),
            _('Filetype'), _('Filesize') ]

WARNING_MESSAGES = {
                    0   :   _('Missing PostScript Name'),
                    1   :   _('Invalid PostScript Name'),
                    2   :   _('File not listed by FontConfig')
                    }

SAMPLE_STRING = ''

def set_preview_text(use_localized_sample):
    global SAMPLE_STRING
    if use_localized_sample:
        SAMPLE_STRING = COMPARE_TEXT.format(LOCALIZED_TEXT)
    else:
        SAMPLE_STRING = COMPARE_TEXT.format(STANDARD_TEXT)
    return


class FontJanitor(object):
    _dirty = False
    _issues = False
    def __init__(self, objects, folder):
        self._cellmap = {
                        FAMILY              :   self._family,
                        FILENAME            :   self._filename,
                        SUGGESTED_FILENAME  :   self._suggested,
                        FILETYPE            :   self._filetype,
                        FILESIZE            :   self._filesize
                        }
        self.objects = objects
        self.folder = folder
        self.builder = objects.builder
        self.manager = self.objects['FontManager']
        self.dupes = {}
        self.recognized = []
        self.broken = {}
        self.dupelist = []
        self.all_selected = False
        self.remove_on_exit = []
        set_preview_text(self.objects['Preferences'].localized)
        self.builder.add_from_file(os.path.join(PACKAGE_DATA_DIR,
                                                    'font-janitor.ui'))
        self.window = self.builder.get_object('JanitorWindow')
        self.window.set_transient_for(objects['MainWindow'])
        self.window.set_title(_('Font Janitor - {0}').format(
                                                    self.folder.rstrip(os.sep)))
        self.window.set_size_request(700, 400)
        self.window.set_position(gtk.WIN_POS_CENTER_ON_PARENT)
        self.window.set_destroy_with_parent(True)
        self.window.connect('delete-event', self.on_quit)
        self.default_font_desc = self.window.get_style().font_desc
        self.font_desc = self.default_font_desc.copy()
        self.font_desc.set_weight(700)
        self.font_size = 9.0
        self.builder.get_object('RenameButton').connect('clicked', self.do_rename)
        self.builder.get_object('DeleteButton').connect('clicked', self.do_delete)
        self.builder.get_object('PostScriptName').connect('toggled', self._suggest)
        self.builder.get_object('PangoName').connect('toggled', self._suggest)
        self.size_slider = self.builder.get_object('JanitorSizeSlider')
        self.size_slider.connect('scroll-event', correct_slider_behavior, 1.0)
        size_adjustment = self.size_slider.get_adjustment()
        size_adjustment.connect('value-changed', self._set_font_size)
        self.store = gtk.TreeStore(gobject.TYPE_STRING, gobject.TYPE_STRING,
                                    gobject.TYPE_STRING, gobject.TYPE_STRING,
                                    gobject.TYPE_STRING, gobject.TYPE_STRING,
                                    gobject.TYPE_STRING, gobject.TYPE_STRING,
                                    gobject.TYPE_STRING, gobject.TYPE_PYOBJECT,
                                    gobject.TYPE_BOOLEAN, gobject.TYPE_BOOLEAN,
                                    gobject.TYPE_STRING, gobject.TYPE_STRING)
        self.treeview = self.builder.get_object('CleanTree')
        self.treeview.set_model(self.store)
        self._setup_treecolumns()
        self._populate_treeview()
        self.treeview.expand_all()
        size_adjustment.set_value(self.font_size)
        self.treeview.connect('query-tooltip', self._on_tooltip_query)
        if self._issues:
            self.builder.get_object('IssuesButton').show()
            self.builder.get_object('IssuesButton').connect('toggled',
                                                                self._set_page)
        self.window.show()

    def _add_possible_dupe(self, table, family, style):
        dupes = table.get('*',
                        'family="{0}" AND style="{1}"'.format(family, style))
        paths = [f['filepath'] for f in dupes]
        if len(paths) > 1:
            self.dupes['{0} {1}'.format(family, style)] = '\n'.join(paths)
            self.dupelist = self.dupelist + paths
        return

    @staticmethod
    def _set_cell_color(column, cell, model, treeiter):
        cell.set_property('background', model.get_value(treeiter, BG_COLOR))
        return

    def _family(self, column, cell, model, treeiter):
        cell.set_property('text', model.get_value(treeiter, FAMILY))
        if not model.iter_has_child(treeiter):
            cell.set_property('font-desc', model.get_value(treeiter, FONT_DESC))
        else:
            cell.set_property('font-desc', self.font_desc)
        cell.set_property('size-points', self.font_size)
        self._set_cell_color(column, cell, model, treeiter)
        return

    def _filename(self, column, cell, model, treeiter):
        cell.set_property('text', model.get_value(treeiter, FILENAME))
        self._set_cell_color(column, cell, model, treeiter)
        return

    def _filetype(self, column, cell, model, treeiter):
        cell.set_property('text', model.get_value(treeiter, FILETYPE))
        self._set_cell_color(column, cell, model, treeiter)
        return

    def _filesize(self, column, cell, model, treeiter):
        cell.set_property('text', model.get_value(treeiter, FILESIZE))
        self._set_cell_color(column, cell, model, treeiter)
        return

    def _get_selected_paths(self):
        selected_paths = []
        parent_rows = self.store.iter_n_children(None)
        for row in range(parent_rows):
            parent = self.store.get_iter(row)
            treeiter = self.store.iter_children(parent)
            while treeiter:
                path = self.store.get_path(treeiter)
                if self.store[path][ACTIVE]:
                    selected_paths.append(path)
                treeiter = self.store.iter_next(treeiter)
        return selected_paths

    def _get_all_valid_paths(self):
        valid_paths = []
        parent_rows = self.store.iter_n_children(None)
        for row in range(parent_rows):
            parent = self.store.get_iter(row)
            treeiter = self.store.iter_children(parent)
            while treeiter:
                path = self.store.get_path(treeiter)
                valid_paths.append(path)
                treeiter = self.store.iter_next(treeiter)
        return valid_paths

    def _get_unrecognized(self):
        unrecognized = []
        for root, dirs, files in os.walk(self.folder):
            for filepath in files:
                if not filepath.endswith(FONT_EXTS):
                    continue
                path = join(root, filepath)
                if path not in self.recognized and path not in self.dupelist:
                    unrecognized.append(path)
        return unrecognized

    @staticmethod
    def _have_write_permissions(filepath):
        return (exists(filepath) and os.access(filepath, os.W_OK))

    def _on_name_cell_edited(self, cell, path, new_name):
        if new_name.strip() == '':
            return
        if len(path.split(':')) > 1:
            self.store[path][SUGGESTED_FILENAME] = new_name
        return

    # Disable warnings related to invalid names
    # pylint: disable-msg=C0103
    @staticmethod
    def _on_tooltip_query(widget, x, y, unused_kmode, tooltip):
        try:
            model = widget.get_model()
            x, y = widget.convert_widget_to_bin_window_coords(x, y)
            path = widget.get_path_at_pos(x, y)[0]
            color = model[path][BG_COLOR]
            filepath = model[path][FILEPATH]
            if filepath.lower().endswith('.ttc'):
                markup = '\nTrueType Collections may be listed multiple times\n'
            elif model[path][PS_NAME].startswith('None.'):
                markup = '\nFile failed to provide a valid PostScript name\n'
            elif color == '#ff6f6f':
                markup = '\nSuggested filenames may contain illegal characters\n'
            elif color == '#ffff99':
                markup = '\nSuggested filenames may contain non-ASCII characters\n'
            elif color == '#a3ffa3':
                markup = '\nSuggested filenames may be too generic\n'
            else:
                markup = None
            if markup:
                tooltip.set_markup(markup)
                return True
            else:
                return False
        except (TypeError, ValueError, KeyError):
            return False
    # Enable warnings related to invalid names
    # pylint: enable-msg=C0103

    def _suggested(self, column, cell, model, treeiter):
        cell.set_property('text', model.get_value(treeiter, SUGGESTED_FILENAME))
        self._set_cell_color(column, cell, model, treeiter)
        return

    def _select_all(self, column):
        model = self.store
        self.all_selected = not self.all_selected
        for row in model:
            row[ACTIVE] = self.all_selected
            try:
                children = row.iterchildren()
                if children:
                    row = children.next()
                    while row:
                        row[ACTIVE] = self.all_selected
                        row = children.next()
            except StopIteration:
                continue
        return

    def _set_font_size(self, adjustment):
        self.font_size = adjustment.get_value()
        for column in self.treeview.get_columns():
            column.set_max_width(-1)
            cell = column.get_cell_renderers()[0]
            if isinstance(cell, gtk.CellRendererText):
                cell.set_property('size-points', self.font_size)
            column.queue_resize()
        self.treeview.queue_draw()
        return

    def _set_page(self, widget):
        _widgets = ( 'RenameButton', 'NameToggles', 'DeleteButton' )
        notebook = self.builder.get_object('JanitorNotebook')
        if widget.get_active():
            notebook.set_current_page(1)
            self.size_slider.hide()
            widget.set_tooltip_text(_('Hide possible issues'))
            self.builder.get_object('ToolBarSpacer').show()
            for widget in _widgets:
                self.builder.get_object(widget).hide()
        else:
            notebook.set_current_page(0)
            self.size_slider.show()
            widget.set_tooltip_text(_('View possible issues'))
            self.builder.get_object('ToolBarSpacer').hide()
            for widget in _widgets:
                self.builder.get_object(widget).show()
        return

    def _setup_treecolumns(self):
        for i in range(5):
            column = gtk.TreeViewColumn(COLUMNS[i])
            renderer = gtk.CellRendererText()
            column.pack_start(renderer)
            column.set_cell_data_func(renderer, self._cellmap[i])
            column.set_resizable(True)
            column.set_expand(True)
            self.treeview.append_column(column)
            column.set_sizing(gtk.TREE_VIEW_COLUMN_FIXED)
            if i == 0:
                column.set_fixed_width(200)
                column.set_expand(False)
            if i == 2:
                renderer.set_property('editable', True)
                renderer.connect('edited', self._on_name_cell_edited)
            if i == 3 or i == 4:
                column.set_fixed_width(100)
                column.set_expand(False)
            if i == 4:
                column = gtk.TreeViewColumn(' * ')
                renderer = gtk.CellRendererToggle()
                renderer.connect('toggled', self._toggled)
                column.pack_start(renderer, False)
                column.set_fixed_width(50)
                column.set_resizable(False)
                column.set_expand(False)
                renderer.set_property('activatable', True)
                column.add_attribute(renderer, "active", ACTIVE)
                column.add_attribute(renderer, "inconsistent", INCONSISTENT)
                self.treeview.append_column(column)
                column.set_clickable(True)
                column.connect('clicked', self._select_all)
        return

    def _suggest(self, toggle):
        if self.builder.get_object('PangoName').get_active():
            new_value = PANGO_NAME
        elif self.builder.get_object('PangoDescription').get_active():
            new_value = PANGO_DESC
        else:
            new_value = PS_NAME
        paths = self._get_all_valid_paths()
        for path in paths:
            self.store[path][SUGGESTED_FILENAME] = self.store[path][new_value]
        self.treeview.queue_draw()
        return

    def _toggled(self, toggle, path):
        if len(path.split(':')) == 1:
            self.store[path][INCONSISTENT] = False
            current = self.store[path][ACTIVE]
            self.store[path][ACTIVE] = not current
            parent = self.store.get_iter(path)
            treeiter = self.store.iter_children(parent)
            while treeiter:
                path = self.store.get_path(treeiter)
                self.store[path][ACTIVE] = not current
                treeiter = self.store.iter_next(treeiter)
        else:
            self.store[path][ACTIVE] = not self.store[path][ACTIVE]
            treeiter = self.store.get_iter(path)
            parent = self.store.iter_parent(treeiter)
            if parent:
                path = self.store.get_path(parent)
                self.store[path][INCONSISTENT] = True
        return

    def _populate_treeview(self):
        table = Table('Fonts')
        query = 'filepath LIKE "{0}"'.format('%' + self.folder + '%')
        db_families = [f[0] for f in set(table.get('family', query))]
        families = self.objects['FontManager'].list_families()
        results = [ f for f in db_families if f in families ]
        for family in natural_sort(results):
            parent = None
            styles = self.objects['FontManager'][family].styles
            pango_family = self.objects['FontManager'][family].pango_family
            for style in styles:
                folder, fontfile = split(styles[style]['filepath'])
                if not folder.startswith(self.folder):
                    self._add_possible_dupe(table, family, style)
                    continue
                font_desc = None
                for face in pango_family.list_faces():
                    if face.get_face_name() == style:
                        font_desc = face.describe()
                        break
                if not font_desc:
                    font_desc = self.font_desc
                if self._have_write_permissions(styles[style]['filepath']):
                    if parent is None:
                        parent = self.store.append(None, [family, '', '', '',
                        '', '', '', '', '', None, False, False, None, family])
                    ps_name = styles[style]['psname'].strip()
                    pango_desc = font_desc.to_string().strip('.').strip(',')
                    pango_name = font_desc.to_filename().strip('.').strip(',')
                    file_ext = splitext(styles[style]['filepath'])[1].lower()
                    if filename_is_illegal(ps_name) or \
                    filename_is_illegal(pango_desc):
                        bg_color = '#ff6f6f'
                    elif ps_name == 'None':
                        self.broken[styles[style]['filepath']] = MISSING_PSNAME
                        bg_color = '#ff6f6f'
                    elif file_ext == '.ttc':
                        bg_color = '#ff6f6f'
                    elif filename_is_questionable(pango_desc):
                        bg_color = '#ffff99'
                    elif ps_name.startswith('New'):
                        bg_color = '#a3ffa3'
                    else:
                        bg_color = None
                    self.store.append(parent, [SAMPLE_STRING, fontfile,
                                    '{0}{1}'.format(ps_name, file_ext),
                                    styles[style]['filetype'],
                                    styles[style]['filesize'],
                                    styles[style]['filepath'],
                                    '{0}{1}'.format(ps_name, file_ext),
                                    '{0}{1}'.format(pango_name, file_ext),
                                    '{0}{1}'.format(pango_desc, file_ext),
                                    font_desc, False, False, bg_color, family])
                    self.recognized.append(styles[style]['filepath'])
        self._show_dupes()
        self._show_issues()
        return

    def _show_dupes(self):
        if not len(self.dupes) > 0:
            return
        dupe_tree = self.builder.get_object('DuplicatesTree')
        dupe_store = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING,
                                                        gobject.TYPE_PYOBJECT)
        column = gtk.TreeViewColumn()
        for i in range(2):
            renderer = gtk.CellRendererText()
            column.pack_start(renderer)
            column.add_attribute(renderer, 'markup', i)
            renderer = gtk.CellRendererText()
            column.pack_start(renderer)
        dupe_tree.append_column(column)
        dupe_tree.set_model(dupe_store)
        for family, files in self.dupes.iteritems():
            dupe_store.append(['<b>{0}</b>'.format(family), files, self.font_desc])
        column.set_sort_column_id(0)
        column.clicked()
        self.builder.get_object('DupesBox').show_all()
        self._issues = True
        return

    def _show_issues(self):
        unrecognized = self._get_unrecognized()
        if not len(unrecognized) > 0 and not len(self.broken) > 0:
            return
        issue_tree = self.builder.get_object('IssuesTree')
        issue_store = gtk.ListStore(gobject.TYPE_STRING, gobject.TYPE_STRING,
                                    gobject.TYPE_PYOBJECT)
        column = gtk.TreeViewColumn()
        for i in range(3):
            renderer = gtk.CellRendererText()
            column.pack_start(renderer)
            if i != 2:
                column.add_attribute(renderer, 'markup', i)
            renderer = gtk.CellRendererText()
            column.pack_start(renderer)
        issue_tree.append_column(column)
        issue_tree.set_model(issue_store)
        for path in unrecognized:
            issue_store.append(['<b>{0}</b>'.format(WARNING_MESSAGES[UNUSABLE]),
                                                    path, self.font_desc])
        for path, err in self.broken.iteritems():
            issue_store.append(['<b>{0}</b>'.format(WARNING_MESSAGES[err]),
                                                    path, self.font_desc])
        column.set_sort_column_id(0)
        column.clicked()
        self.builder.get_object('IssuesBox').show_all()
        self._issues = True
        return

    def do_delete(self, unused_widget):
        # FIXME - shouldn't need this hack
        run_again = False
        selected = self._get_selected_paths()
        model = self.store
        for row in selected:
            try:
                font = gio.File(model[row][FILEPATH])
                access = font.query_info('access::*')
                can_trash = access.get_attribute_boolean('access::can-trash')
                if can_trash:
                    trashed = font.trash()
                if not trashed or not can_trash:
                    os.unlink(model[row][FILEPATH])
                self.manager.remove_families(model[row][REMOVE])
                self.objects.update_family_total()
                self.objects['Treeviews'].update_category_treeview()
            except (IndexError, KeyError):
                run_again = True
            except (OSError, gio.Error), error:
                #logging.error(error)
                pass
        for row in selected:
            try:
                treeiter = model.get_iter(row)
                model.remove(treeiter)
            except ValueError:
                run_again = True
        rootiter = model.get_iter_root()
        while rootiter:
            treeiter = rootiter
            rootiter = model.iter_next(treeiter)
            if not model.iter_has_child(treeiter):
                model.remove(treeiter)
        self.treeview.queue_draw()
        self._dirty = True
        if run_again:
            self.do_delete(None)
        self.objects['Treeviews'].update_views()
        return

    def do_rename(self, unused_widget):
        failed = []
        selected = self._get_selected_paths()
        model = self.store
        for path in selected:
            try:
                old_file = model[path][FILEPATH]
                folder = split(model[path][FILEPATH])[0]
                new_file = join(folder, model[path][SUGGESTED_FILENAME])
                if old_file != new_file and (not exists(new_file)):
                    shutil.copy2(old_file, new_file)
                    self.remove_on_exit.append(old_file)
                    model[path][FILENAME] = model[path][SUGGESTED_FILENAME]
                    model[path][FILEPATH] = join(folder,
                                                model[path][SUGGESTED_FILENAME])
                else:
                    failed.append(model[path][FILEPATH])
            except Exception:
                failed.append(model[path][FILEPATH])
        self._dirty = True
        if len(failed) > 0:
            for font in failed:
                logging.error('Failed to rename : {0}'.format(font))
        return

    def on_quit(self, unused_widget, unused_event):
        self.window.destroy()
        for path in self.remove_on_exit:
            try:
                os.unlink(path)
            except Exception:
                pass
        if self._dirty:
            self.objects.reload(True)
        return
