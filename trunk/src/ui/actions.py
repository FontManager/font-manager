"""
This module allows for user-configured actions.
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
import shlex
import subprocess
import time

from constants import PACKAGE_DATA_DIR
from utils.common import display_warning, natural_sort
from utils.xmlutils import load_actions, save_actions


class UserActions(object):
    """
    Dialog to allow the user to run arbitrary commands on selected font file.
    """
    _widgets = (
                'ActionsDialog', 'ActionsTree', 'NewAction', 'RemoveAction',
                'AddActionDialog', 'ActionName', 'ActionComment',
                'ExecutablePath', 'ArgumentList', 'RunInTerminal',
                'BlockOnAction', 'RestartApp', 'Cancel', 'AddAction',
                'EditAction', 'CloseActionsDialog', 'BinSelector'
                )
    def __init__(self, objects):
        self.objects = objects
        self.builder = objects.builder
        self.widgets = {}
        self.actions = load_actions()
        self.current_name = None
        self.current_bin = None
        self.builder.add_from_file(os.path.join(PACKAGE_DATA_DIR, 'actions.ui'))
        for widget in self._widgets:
            self.widgets[widget] = self.builder.get_object(widget)
        self.widgets['ActionsDialog'].set_transient_for(objects['MainWindow'])
        model = gtk.ListStore(gobject.TYPE_STRING)
        self.widgets['ActionsTree'].set_model(model)
        cell_renderer = gtk.CellRendererText()
        cell_renderer.set_property('xpad', 5)
        cell_renderer.set_property('ypad', 3)
        column = gtk.TreeViewColumn(None, cell_renderer, text = 0)
        self.widgets['ActionsTree'].append_column(column)
        self._connect_callbacks()

    def _connect_callbacks(self):
        widgets = self.widgets
        widgets['ActionsDialog'].connect('delete-event', \
                                lambda widget, event: widget.hide() is None)
        widgets['AddActionDialog'].connect('delete-event', \
                                lambda widget, event: widget.hide() is None)
        widgets['CloseActionsDialog'].connect('clicked', \
                    lambda widget: widgets['ActionsDialog'].hide() is None)
        widgets['NewAction'].connect('clicked', self._create_action)
        widgets['RemoveAction'].connect('clicked', self._remove_action)
        widgets['RemoveAction'].set_sensitive(False)
        widgets['ActionName'].connect('changed', self._name_changed)
        widgets['ActionName'].connect('icon-press', self._icon_pressed)
        widgets['ActionComment'].connect('icon-press', self._icon_pressed)
        widgets['ExecutablePath'].connect('changed', self._bin_changed)
        widgets['ExecutablePath'].connect('icon-press', self._icon_pressed)
        widgets['ArgumentList'].connect('icon-press', self._icon_pressed)
        widgets['Cancel'].connect('clicked', self._cancel)
        widgets['AddAction'].connect('clicked', self._add_action)
        selection = widgets['ActionsTree'].get_selection()
        selection.connect('changed', self._selection_changed)
        widgets['ActionsTree'].connect('row-activated', self._action_activated)
        widgets['EditAction'].connect('clicked', self._activate_row)
        widgets['EditAction'].set_sensitive(False)
        return

    def _action_activated(self, treeview, path, column):
        """
        Display edit dialog.
        """
        model = treeview.get_model()
        treeiter = model.get_iter(path)
        val = model.get_value(treeiter, 0)
        self._edit_action(val)
        return

    def _activate_row(self, unused_widget):
        """
        Display edit dialog.
        """
        tree = self.widgets['ActionsTree']
        selection = tree.get_selection()
        if selection.count_selected_rows() < 1:
            return
        column = tree.get_column(0)
        model, treeiter = selection.get_selected()
        path = model.get_path(treeiter)
        tree.row_activated(path, column)
        return

    def _add_action(self, unused_widget):
        """
        Add a user specified action
        """
        widgets = self.widgets
        action = {}
        action['name'] = self.current_name
        action['executable'] = self.current_bin
        comment = widgets['ActionComment'].get_text()
        if len(comment) > 0:
            action['comment'] = comment
        else:
            action['comment'] = 'None'
        args = widgets['ArgumentList'].get_text()
        if len(args) > 0:
            action['arguments'] = args
        else:
            action['arguments'] = 'None'
        action['terminal'] = widgets['RunInTerminal'].get_active()
        action['block'] = widgets['BlockOnAction'].get_active()
        action['restart'] = widgets['RestartApp'].get_active()
        widgets['AddActionDialog'].hide()
        while gtk.events_pending():
            gtk.main_iteration()
        if self.current_name in self.actions:
            del self.actions[self.current_name]
        self.actions[self.current_name] = action
        save_actions(self.actions)
        self._clear_add_dialog()
        self.run(None)
        return

    def _bin_changed(self, widget):
        self.current_bin = widget.get_text()
        if len(self.widgets['ActionName'].get_text()) > 0 \
        and len(self.current_bin) > 0:
            self.widgets['AddAction'].set_sensitive(True)
        else:
            self.widgets['AddAction'].set_sensitive(False)
        return

    def _cancel(self, unused_widget):
        self.widgets['AddActionDialog'].hide()
        while gtk.events_pending():
            gtk.main_iteration()
        self._clear_add_dialog()
        self.run(None)
        return

    def _clear_add_dialog(self):
        """
        Reset dialog.
        """
        _entries = (
            'ActionName', 'ActionComment', 'ExecutablePath', 'ArgumentList'
                    )
        _toggles = ( 'RunInTerminal', 'BlockOnAction', 'RestartApp' )
        for entry in _entries:
            self.widgets[entry].set_text('')
        for toggle in _toggles:
            self.widgets[toggle].set_active(False)
        self.widgets['AddAction'].set_sensitive(False)
        return

    def _create_action(self, widget):
        if widget != self.widgets['NewAction']:
            self.widgets['AddActionDialog'].set_title(_('Edit Action'))
        else:
            self.widgets['AddActionDialog'].set_title(_('New Action'))
        self.widgets['ActionsDialog'].hide()
        self.widgets['AddActionDialog'].show()
        while gtk.events_pending():
            gtk.main_iteration()
        return

    def _edit_action(self, val):
        """
        Edit an existing action.
        """
        widgets = self.widgets
        action = self.actions[val]
        self.current_name = val
        widgets['ActionName'].set_text(action['name'])
        widgets['ExecutablePath'].set_text(action['executable'])
        if action['comment'] != 'None':
            widgets['ActionComment'].set_text(action['comment'])
        else:
            widgets['ActionComment'].set_text('')
        if action['arguments'] != 'None':
            widgets['ArgumentList'].set_text(action['arguments'])
        else:
            widgets['ArgumentList'].set_text('')
        widgets['RunInTerminal'].set_active(action['terminal'])
        widgets['BlockOnAction'].set_active(action['block'])
        widgets['RestartApp'].set_active(action['restart'])
        self._create_action(None)
        return

    def get_actions(self):
        """
        Return a list of user-configured actions or None.
        """
        if self.actions is None:
            return
        return natural_sort(self.actions.iterkeys())

    def _icon_pressed(self, widget, icon_pos, event):
        """
        Clear entry or display a file selection dialog.
        """
        if icon_pos == 0:
            self._select_bin(widget)
        else:
            widget.set_text('')
        return

    def _name_changed(self, widget):
        self.current_name = widget.get_text()
        if len(self.widgets['ExecutablePath'].get_text()) > 0 \
        and len(self.current_name) > 0:
            self.widgets['AddAction'].set_sensitive(True)
        else:
            self.widgets['AddAction'].set_sensitive(False)
        return

    def _populate_tree(self):
        model = self.widgets['ActionsTree'].get_model()
        model.clear()
        for action in natural_sort(self.actions.iterkeys()):
            model.append([action])
        return

    def _remove_action(self, unused_widget):
        """
        Remove selected action.
        """
        tree = self.widgets['ActionsTree']
        selection = tree.get_selection()
        model, treeiter = selection.get_selected()
        if treeiter is not None:
            del self.actions[model.get_value(treeiter, 0)]
            still_valid = model.remove(treeiter)
            if still_valid:
                selection.select_iter(treeiter)
            else:
                treeiter = model.get_iter_first()
                while treeiter is not None:
                    treeiter = model.iter_next(treeiter)
                if treeiter:
                    selection.select_iter(treeiter)
        save_actions(self.actions)
        return

    def run(self, unused_widget):
        """
        Display actions dialog.
        """
        self._populate_tree()
        self.widgets['ActionsDialog'].show()
        return

    def run_command(self, widget, details):
        """
        Run selected action.
        """
        name = widget.get_name()
        action = self.actions[name]
        exe = action['executable']
        args = action['arguments'].replace('None', '')
        filepath, family, style = details
        args = args.replace('FAMILY', family)
        args = args.replace('STYLE', style)
        if args.find('FILEPATH') > 0:
            args = args.replace('FILEPATH', filepath)
        else:
            args = '%s "%s"' % (args, filepath)
        command = shlex.split(args)
        command.insert(0, exe)
        try:
            process = subprocess.Popen(command)
            if action['block'] or action['restart']:
                while process.poll() is None:
                    # Prevent loop from hogging cpu
                    time.sleep(0.5)
                    # Avoid the main window becoming unresponsive
                    while gtk.events_pending():
                        gtk.main_iteration()
                    continue
            if action['restart']:
                self.objects.reload(True)
            return
        except (OSError, ValueError), error:
            command = '\nCommand was :\n\n' + ' '.join(command)
            display_warning(error, command)
            return

    def _select_bin(self, widget):
        """
        Display a file chooser dialog where user can select a program.
        """
        dialog = self.widgets['BinSelector']
        dialog.connect('file-activated', lambda widget: widget.response(1))
        if os.path.exists('/usr/bin'):
            dialog.set_current_folder('/usr/bin')
        response = dialog.run()
        dialog.hide()
        if response:
            widget.set_text(dialog.get_filename())
        return

    def _selection_changed(self, treeselection):
        """
        Enable/Disable remove button depending on whether something is selected.
        """
        if treeselection.count_selected_rows() > 0:
            self.widgets['RemoveAction'].set_sensitive(True)
            self.widgets['EditAction'].set_sensitive(True)
        else:
            self.widgets['RemoveAction'].set_sensitive(False)
            self.widgets['EditAction'].set_sensitive(False)
        return
