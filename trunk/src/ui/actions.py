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
from utils.common import display_warning, natural_sort, run_dialog
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
        hide_widget = lambda widget, event: widget.hide() is None
        close_dialog = lambda widget: widgets['ActionsDialog'].hide() is None
        selection = widgets['ActionsTree'].get_selection()
        callbacks = [
            [widgets['ActionsDialog'], 'delete-event', hide_widget],
            [widgets['AddActionDialog'], 'delete-event', hide_widget],
            [widgets['CloseActionsDialog'], 'clicked', close_dialog],
            [widgets['NewAction'], 'clicked', self._create_action],
            [widgets['RemoveAction'], 'clicked', self._remove_action],
            [widgets['ActionName'], 'changed',  self._name_changed],
            [widgets['ActionName'], 'icon-press', self._icon_pressed],
            [widgets['ActionComment'], 'icon-press', self._icon_pressed],
            [widgets['ExecutablePath'], 'changed', self._bin_changed],
            [widgets['ExecutablePath'], 'icon-press', self._icon_pressed],
            [widgets['ArgumentList'], 'icon-press', self._icon_pressed],
            [widgets['Cancel'], 'clicked', self._cancel],
            [widgets['AddAction'], 'clicked', self._add_action],
            [selection, 'changed', self._selection_changed],
            [widgets['ActionsTree'], 'row-activated', self._action_activated],
            [widgets['EditAction'], 'clicked', self._activate_row]
            ]
        for entry in callbacks:
            entry[0].connect(entry[1], entry[2])
        widgets['EditAction'].set_sensitive(False)
        widgets['RemoveAction'].set_sensitive(False)
        return

    def _action_activated(self, treeview, path, column):
        """
        Display edit dialog.
        """
        return self._edit_action(treeview.get_model().get_value(
                                    treeview.get_model().get_iter(path), 0))

    def _activate_row(self, unused_widget):
        """
        Display edit dialog.
        """
        tree = self.widgets['ActionsTree']
        selection = tree.get_selection()
        if selection.count_selected_rows() < 1:
            return
        model, treeiter = selection.get_selected()
        tree.row_activated(model.get_path(treeiter), tree.get_column(0))
        return

    def _add_action(self, unused_widget):
        """
        Add a user specified action
        """
        action = {}
        action['name'] = self.current_name
        action['executable'] = self.current_bin
        if self.widgets['ActionComment'].get_text().strip() != '':
            action['comment'] = self.widgets['ActionComment'].get_text()
        else:
            action['comment'] = 'None'
        if self.widgets['ArgumentList'].get_text().strip() != '':
            action['arguments'] = self.widgets['ArgumentList'].get_text()
        else:
            action['arguments'] = 'None'
        action['terminal'] = self.widgets['RunInTerminal'].get_active()
        action['block'] = self.widgets['BlockOnAction'].get_active()
        action['restart'] = self.widgets['RestartApp'].get_active()
        self.widgets['AddActionDialog'].hide()
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
        self.widgets['AddAction'].set_sensitive(
                            (len(self.widgets['ActionName'].get_text()) > 0 and
                            len(self.current_bin) > 0))
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
        for entry in 'ActionName', 'ActionComment', 'ExecutablePath', \
            'ArgumentList':
            set_widget_text(self.widgets[entry], None)
        for toggle in 'RunInTerminal', 'BlockOnAction', 'RestartApp':
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
        action = self.actions[val]
        self.current_name = val
        _text = {
                self.widgets['ActionName']        :   action['name'],
                self.widgets['ExecutablePath']    :   action['executable'],
                self.widgets['ActionComment']     :   action['comment'],
                self.widgets['ArgumentList']      :   action['arguments']
                }
        _bool = {
                self.widgets['BlockOnAction']       :   action['block'],
                self.widgets['RestartApp']          :   action['restart'],
                self.widgets['RunInTerminal']       :   action['terminal']
                }
        for widget, text in _text.iteritems():
            set_widget_text(widget, text)
        for widget, state in _bool.iteritems():
            widget.set_active(state)
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
            set_widget_text(widget, None)
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
        action = self.actions[widget.get_name()]
        exe = action['executable']
        args = action['arguments'].replace('None', '')
        filepath, family, style = details
        args = args.replace('FAMILY', family)
        args = args.replace('STYLE', style)
        if args.find('FILEPATH') > 0:
            args = args.replace('FILEPATH', filepath)
        else:
            args = '{0} "{1}"'.format(args, filepath)
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
            display_warning(error, '\nCommand was :\n\n' + ' '.join(command))
            return

    def _select_bin(self, widget):
        """
        Display a file chooser dialog where user can select a program.
        """
        dialog = self.widgets['BinSelector']
        dialog.connect('file-activated', lambda widget: widget.response(1))
        dialog.set_current_folder('/usr/bin')
        if run_dialog(dialog = dialog):
            set_widget_text(widget, dialog.get_filename())
        return

    def _selection_changed(self, treeselection):
        """
        Enable/Disable remove button depending on whether something is selected.
        """
        state = (treeselection.count_selected_rows() > 0)
        self.widgets['RemoveAction'].set_sensitive(state)
        self.widgets['EditAction'].set_sensitive(state)
        return


def set_widget_text(widget, text):
    if text is None or text == 'None':
        text = ''
    return widget.set_text(text)
