"""
This module provides a simple preferences dialog.
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
import gobject

from os.path import join, isdir

from core import database
from utils.common import delete_cache, delete_database, match, \
                            natural_sort, search, run_dialog
from constants import HOME


EXTS = ('.ttf', '.ttc', '.otf', '.pfb', '.pfa', '.pfm', '.afm', '.bdf',
            '.TTF', '.TTC', '.OTF', '.PFB', '.PFA', '.PFM', '.AFM', '.BDF')
# http://code.google.com/p/font-manager/issues/detail?id=1
BAD_PATHS = ('/usr', '/bin', '/boot', '/dev', '/lost+found', '/proc',
             '/root', '/selinux', '/srv', '/sys', '/etc', '/lib',
             '/sbin', '/tmp', '/var')


class PreferencesDialog():
    """
    Font Manager preferences dialog.
    """
    _widgets = (
        'PreferencesDialog', 'AddDirButton', 'RemoveDirButton',
        'AutoScanButton', 'PrefsInfoButton', 'PrefsAutoStart', 'PrefsHidden',
        'PrefsMinimize', 'PrefsOrphans', 'PrefsPangram', 'PrefsFontSize',
        'DBTree', 'UserDirTree', 'SearchDB', 'RemoveFromDB', 'ResetDB',
        'DefaultFolderBox', 'ArchTypeBox', 'PrefsFileChooser',
        'PrefsInvalidDir', 'AutoScanInfo', 'PrefsCollFocus', 'PrefsCollTotal',
        'PrefsFamTotal', 'PrefsToolTips', 'PrefsLocSample',
        'PrefsJanitor'
        )
    def __init__(self, objects):
        self.objects = objects
        self.builder = objects.builder
        self.preferences = objects['Preferences']
        self.widgets = {}
        self.directories = None
        self.dir_tree = None
        self.db_tree = None
        self.update_required = False
        for widget in self._widgets:
            self.widgets[widget] = self.builder.get_object(widget)
        self._create_widgets()
        self._setup_treeviews()
        self._update_widgets()
        self._connect_handlers()

    def _create_widgets(self):
        """
        Create widgets not defined in glade file.
        """
        widgets = self.widgets
        dir_combo = gtk.ComboBox()
        cell = gtk.CellRendererText()
        dir_combo.pack_start(cell, True)
        dir_combo.add_attribute(cell, 'text', 0)
        arch_combo = gtk.combo_box_new_text()
        for ext in 'zip', 'tar.bz2', 'tar.gz':
            arch_combo.append_text(ext)
        widgets['DirCombo'] = dir_combo
        widgets['ArchCombo'] = arch_combo
        return

    def _connect_handlers(self):
        """
        Connect handlers.
        """
        _clicked = {
                    'AddDirButton'      :   self._on_add_dir,
                    'RemoveDirButton'   :   self._on_del_dir,
                    'AutoScanButton'    :   self._on_autoscan,
                    'PrefsInfoButton'   :   self._on_info,
                    'RemoveFromDB'      :   self._on_del_db_item,
                    'ResetDB'           :   self._on_reset_db
                    }
        _toggled = {
                    'PrefsAutoStart'    :   self._on_autostart,
                    'PrefsHidden'       :   self._on_hide_at_start,
                    'PrefsMinimize'     :   self._on_minimize_to_tray,
                    'PrefsOrphans'      :   self._on_show_orphans,
                    'PrefsPangram'      :   self._on_use_pangram,
                    'PrefsCollFocus'    :   self._on_focus_on_drop,
                    'PrefsCollTotal'    :   self._on_coll_totals,
                    'PrefsFamTotal'     :   self._on_fam_totals,
                    'PrefsToolTips'     :   self._on_show_tooltips,
                    'PrefsLocSample'    :   self._on_use_localized_sample,
                    'PrefsJanitor'      :   self._on_enable_janitor
                    }
        widgets = self.widgets
        widgets['PreferencesDialog'].connect('delete-event', self._on_close)
        for widget, function in _clicked.iteritems():
            widgets[widget].connect('clicked', function)
        for widget, function in _toggled.iteritems():
            widgets[widget].connect('toggled', function)
        widgets['PrefsFontSize'].connect('value-changed',
                                                self._on_font_size_change)
        widgets['SearchDB'].connect('icon-press', self._on_clear_db_search)
        widgets['DefaultFolderBox'].pack_start(widgets['DirCombo'], False,
                                                                    True, 5)
        widgets['DirCombo'].connect('changed', self._on_default_dir_changed)
        widgets['ArchCombo'].connect('changed', self._on_arch_type_changed)
        widgets['ArchTypeBox'].pack_start(widgets['ArchCombo'], False, True, 5)
        return

    def _add_dir(self, directory):
        """
        Add a directory to fontconfig search path.
        """
        if directory:
            self.preferences.add_user_font_dir(directory)
            tree = self.widgets['UserDirTree']
            tree.get_model().append([directory])
            tree.queue_draw()
            while gtk.events_pending():
                gtk.main_iteration()
            self.update_required = True
        return

    def _get_new_dir(self):
        """
        Display file chooser dialog so user can add new directories
        to fontconfig search path.
        """
        self.widgets['PrefsFileChooser'].set_current_folder(HOME)
        if run_dialog(dialog = self.widgets['PrefsFileChooser']):
            directory = self.widgets['PrefsFileChooser'].get_filename()
            if directory == '/' or directory.startswith(BAD_PATHS):
                self._on_bad_path()
            else:
                return directory
        return

    def _get_selected_dir(self):
        """
        Return selected treeiter and value for directory tree.
        """
        selection = self.widgets['UserDirTree'].get_selection()
        model, treeiter = selection.get_selected()
        if not treeiter:
            return
        return treeiter, model.get(treeiter, 0)[0]

    def _on_add_dir(self, unused_widget = None):
        """
        Add a directory to fontconfig search path.
        """
        directory = self._get_new_dir()
        self._add_dir(directory)
        return

    def _on_arch_type_changed(self, widget):
        """
        Change archive type used for export.
        """
        self.preferences.archivetype = widget.get_active_text()
        return

    def _on_autoscan(self, unused_widget):
        """
        Find any directories containing fonts in the users home folder and
        add them to the search path.
        """
        # FIXME
        # Dirs shouldn't be added twice
        for root, unused_dirs, files in os.walk(HOME):
            for name in files:
                if name.endswith(EXTS) and root.find('/.') == -1 \
                and root not in self.directories:
                    self._add_dir(root)
                    # Ensure update
                    while gtk.events_pending():
                        gtk.main_iteration()
                    break
        return

    def _on_autostart(self, widget):
        """
        Enable or disable application autostart.
        """
        self.preferences.on_autostart(widget.get_active())
        return

    def _on_bad_path(self):
        """
        Display warning dialog.
        """
        run_dialog(dialog = self.widgets['PrefsInvalidDir'])
        self._on_add_dir()
        return

    def _on_clear_db_search(self, widget, unused_icon_pos, unused_event):
        """
        Clear database search entry.
        """
        widget.set_text('')
        self.widgets['DBTree'].scroll_to_point(0, 0)
        return

    def _on_close(self, unused_widget, unused_event = None):
        """
        Save preferences and hide dialog.
        """
        self.preferences.save()
        self.widgets['PreferencesDialog'].hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if self.update_required:
            self.objects.reload(True)
        return True

    def _on_coll_totals(self, widget):
        current = widget.get_active()
        self.preferences.collectiontotals = current
        try:
            render = \
            self.objects['CategoryTree'].get_column(0).get_cell_renderers()[0]
            render.set_property('show-count', current)
            render = \
            self.objects['CollectionTree'].get_column(0).get_cell_renderers()[0]
            render.set_property('show-count', current)
            self.objects['CategoryTree'].queue_draw()
            self.objects['CollectionTree'].queue_draw()
        except TypeError:
            self.update_required = True
        return

    def _on_enable_janitor(self, widget):
        self.preferences.janitor = widget.get_active()
        return

    def _on_fam_totals(self, widget):
        current = widget.get_active()
        self.preferences.familytotals = current
        try:
            render = \
            self.objects['FamilyTree'].get_column(0).get_cell_renderers()[0]
            render.set_property('show-count', current)
            self.objects['FamilyTree'].queue_draw()
        except TypeError:
            self.update_required = True
        return

    def _on_focus_on_drop(self, widget):
        self.preferences.focusondrop = widget.get_active()
        return

    def _on_show_tooltips(self, widget):
        show = widget.get_active()
        self.preferences.tooltips = show
        if show:
            self.objects['CategoryTree'].set_tooltip_column(2)
            self.objects['CollectionTree'].set_tooltip_column(2)
        else:
            self.objects['CategoryTree'].set_tooltip_column(-1)
            self.objects['CollectionTree'].set_tooltip_column(-1)
        return

    def _on_default_dir_changed(self, widget):
        """
        Change default user font directory.
        """
        default_dir = widget.get_active_text()
        if default_dir and isdir(default_dir):
            self.preferences.folder = default_dir
        return

    def _on_del_db_item(self, unused_widget):
        """
        Delete an entry from the applications database.
        """
        db_tree = self.widgets['DBTree']
        db_model = db_tree.get_model()
        db_selection = db_tree.get_selection()
        try:
            treeiter = db_selection.get_selected()[1]
            family = db_model.get_value(treeiter, 0)
        # Tried to delete something that wasn't there
        except TypeError:
            return
        fonts = database.Table('Fonts')
        query = 'family="{0}"'.format(family)
        fonts.remove(query)
        fonts.close()
        db_model.remove(treeiter)
        still_valid = db_model.iter_is_valid(treeiter)
        if still_valid:
            new_path = db_model.get_path(treeiter)
            if (new_path[0] >= 0):
                db_selection.select_path(new_path)
        else:
            path_to_select = db_model.iter_n_children(None) - 1
            if (path_to_select >= 0):
                db_selection.select_path(path_to_select)
        db_tree.queue_draw()
        return

    def _on_del_dir(self, unused_widget):
        """
        Remove a directory from fontconfig search path
        """
        try:
            treeiter, directory = self._get_selected_dir()
        except TypeError:
            return
        self.preferences.remove_user_font_dir(directory)
        dir_tree = self.widgets['UserDirTree']
        model = dir_tree.get_model()
        selection = dir_tree.get_selection()
        model.remove(treeiter)
        still_valid = model.iter_is_valid(treeiter)
        if still_valid:
            new_path = model.get_path(treeiter)
            if (new_path[0] >= 0):
                selection.select_path(new_path)
        else:
            path_to_select = model.iter_n_children(None) - 1
            if (path_to_select >= 0):
                selection.select_path(path_to_select)
        # Remove any fonts which were in that directory
        manager = self.objects['FontManager']
        families = manager.list_families()
        for family in families:
            for style in manager[family].styles.itervalues():
                if style['filepath'].startswith(directory):
                    manager.remove_families(family)
                    break
            while gtk.events_pending():
                gtk.main_iteration()
            self.objects.update_family_total()
            self.objects['Treeviews'].update_category_treeview()
        self.objects['Treeviews'].update_views()
        return

    def _on_dir_selection_changed(self, treeselection):
        """
        Update UI sensitivity.
        """
        default = treeselection.path_is_selected(0)
        # Don't allow removal of default folder
        if default:
            self.widgets['RemoveDirButton'].set_sensitive(False)
        else:
            self.widgets['RemoveDirButton'].set_sensitive(True)
        return

    def _on_font_size_change(self, widget):
        """
        Change font size used in exported .pdf. files.
        """
        self.preferences.fontsize = widget.get_adjustment().get_value()
        return

    def _on_info(self, unused_widget):
        """
        Display info dialog.
        """
        run_dialog(dialog = self.widgets['AutoScanInfo'])
        return

    def _on_hide_at_start(self, widget):
        """
        Show or hide application at startup.
        """
        self.preferences.minimizeonstart = widget.get_active()
        return

    def _on_minimize_to_tray(self, widget):
        """
        Minimize application to tray instead of closing.
        """
        self.preferences.minimize_to_tray(widget.get_active())
        return

    def _on_reset_db(self, unused_widget):
        """
        Delete both the applications database and startup cache.
        """
        db_tree = self.widgets['DBTree']
        db_model = db_tree.get_model()
        db_model.clear()
        db_tree.queue_draw()
        delete_cache()
        delete_database()
        self.update_required = True
        return

    def _on_show_orphans(self, widget):
        """
        Show a category containing fonts not present in user collections.
        """
        category_tree = self.objects['CategoryTree']
        category_model = category_tree.get_model()
        show = widget.get_active()
        showing = search(category_model, category_model.iter_children(None),
                                    match, (0, _('Orphans')))
        if show:
            self.preferences.orphans = True
        else:
            self.preferences.orphans = False
        if not show and showing:
            if category_model.iter_is_valid(showing):
                category_model.remove(showing)
                category_tree.expand_all()
        elif show and not showing:
            obj = self.objects['FontManager'].categories[_('Orphans')]
            header = category_model.get_iter_root()
            category_model.append(header,
        [obj.get_name(), obj.get_label(), obj.comment, str(len(obj.families))])
            category_tree.expand_all()
        return

    def _on_use_pangram(self, widget):
        """
        Include pangram in exported .pdf files.
        """
        self.preferences.pangram = widget.get_active()
        return

    def _on_use_localized_sample(self, widget):
        """
        Use localized sample string instead of default pangram.
        """
        self.preferences.localized = widget.get_active()
        return

    def _populate_trees(self, dir_tree, db_tree):
        """
        Populate the models.
        """
        directories = dir_tree.get_model()
        families = db_tree.get_model()
        if directories:
            directories.clear()
        if families:
            families.clear()
        fonts = database.Table('Fonts')
        db_families = set(fonts['family'])
        fonts.close()
        famlist = [f[0] for f in db_families]
        results = natural_sort(famlist)
        for family in results:
            families.append([family])
        default_dir = join(HOME, '.fonts')
        for directory in self.directories:
            if isdir(directory):
                directories.append([directory])
        directories.insert(0, [default_dir])
        return

    def quit(self):
        """
        Save preferences and hide dialog.
        """
        self._on_close(None)
        return

    def run(self, objects):
        """
        Show preferences dialog.
        """
        self.objects = objects
        self.preferences = objects['Preferences']
        self.directories = self.preferences.fontdirs
        self._populate_trees(self.widgets['UserDirTree'],
                                    self.widgets['DBTree'])
        self._update_widgets()
        self.widgets['PreferencesDialog'].show_all()
        return

    def _setup_treeviews(self):
        """
        Setup the directories and database treeviews.
        """
        dir_model = gtk.ListStore(gobject.TYPE_STRING)
        dir_tree = self.widgets['UserDirTree']
        dir_tree.set_model(dir_model)
        self.widgets['DirCombo'].set_model(dir_model)
        dir_column = gtk.TreeViewColumn(None, gtk.CellRendererText(), markup=0)
        dir_tree.append_column(dir_column)
        dir_selection = dir_tree.get_selection()
        dir_selection.set_mode(gtk.SELECTION_SINGLE)
        dir_selection.connect('changed', self._on_dir_selection_changed)
        db_tree = self.widgets['DBTree']
        db_search = self.widgets['SearchDB']
        db_tree.set_search_entry(db_search)
        db_model = gtk.ListStore(gobject.TYPE_STRING)
        db_tree.set_model(db_model)
        db_column = gtk.TreeViewColumn(None, gtk.CellRendererText(), text=0)
        db_column.set_sort_column_id(0)
        db_tree.append_column(db_column)
        db_selection = db_tree.get_selection()
        db_selection.set_mode(gtk.SELECTION_SINGLE)
        dir_selection.select_path(0)
        db_selection.select_path(0)
        return

    def _update_widgets(self):
        """
        Update widget values.
        """
        widgets = {
                    'PrefsHidden'       :   'minimizeonstart',
                    'PrefsAutoStart'    :   'autostart',
                    'PrefsMinimize'     :   'minimizeonclose',
                    'PrefsOrphans'      :   'orphans',
                    'PrefsPangram'      :   'pangram',
                    'PrefsCollFocus'    :   'focusondrop',
                    'PrefsCollTotal'    :   'collectiontotals',
                    'PrefsFamTotal'     :   'familytotals',
                    'PrefsToolTips'     :   'tooltips',
                    'PrefsLocSample'    :   'localized',
                    'PrefsJanitor'      :   'janitor'
                    }
        preferences = self.preferences
        for widget, val in widgets.iteritems():
            self.widgets[widget].set_active(getattr(preferences, val))
        font_size = self.widgets['PrefsFontSize']
        font_size.get_adjustment().set_value(preferences.fontsize)

        model = self.widgets['DirCombo'].get_model()
        dir_iter = search(model, model.iter_children(None),
                                    match, (0, preferences.folder))
        try:
            if model.iter_is_valid(dir_iter):
                self.widgets['DirCombo'].set_active_iter(dir_iter)
        except TypeError:
            self.widgets['DirCombo'].set_active(0)

        arch_type = preferences.archivetype
        types = {
                'zip'       :   0,
                'tar.bz2'   :   1,
                'tar.gz'    :   2
                }
        self.widgets['ArchCombo'].set_active(types[arch_type])
        return
