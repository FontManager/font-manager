/* UserSourceList.vala
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

namespace FontManager {

    public class SourceRow : Gtk.Grid {

        public weak FontConfig.FontSource source { get; set; }

        private Gtk.Label _label;
        private Gtk.Switch _switch;
        private Gtk.Image _icon;

        public SourceRow (FontConfig.FontSource source) {
            Object(source: source);
            _label = new Gtk.Label(null);
            _label.hexpand = true;
            _label.halign = Gtk.Align.START;
            _label.margin = 12;
            _switch = new Gtk.Switch();
            _switch.margin = 12;
            _switch.expand = false;
            _icon = new Gtk.Image.from_icon_name("folder-symbolic", Gtk.IconSize.MENU);
            _icon.margin = 12;
            _icon.expand = false;
            attach(_icon, 0, 0, 1, 1);
            attach(_label, 1, 0, 1, 1);
            attach(_switch, 2, 0, 1, 1);
            source.notify["available"].connect(() => {
                _switch.set_sensitive(source.available);
            });
            _switch.notify["active"].connect(() => {
                source.active = _switch.get_active();
            });
            source.update_complete.connect(() => { update(); });
            update();
        }

        public override void show () {
            _icon.show();
            _label.show();
            _switch.show();
            base.show();
            return;
        }

        private void update () {
            _label.set_markup("<b>%s</b>".printf(source.name));
            _switch.set_active(source.active);
            _switch.set_sensitive(source.available);
            if (source.filetype == FileType.DIRECTORY || source.filetype == FileType.MOUNTABLE)
                _icon.set_from_icon_name("folder-symbolic", Gtk.IconSize.MENU);
            else
                _icon.set_from_icon_name("font-x-generic", Gtk.IconSize.MENU);
            return;
        }

    }

    public class UserSourceList : Gtk.ScrolledWindow {

        public weak FontConfig.Sources sources {
            get {
                return _sources;
            }
            set {
                _sources = value;
                if (initial_call) {
                    foreach (var s in _sources) {
                        var w = new SourceRow(s);
                        w.show();
                        list.add(w);
                    }
                    if (list.get_row_at_index(0) != null)
                        list.select_row(list.get_row_at_index(0));
                }
                initial_call = false;
            }
        }

        private bool initial_call = true;
        private Gtk.ListBox list;
        private weak FontConfig.Sources _sources;

        construct {
            list = new Gtk.ListBox();
            add(list);
        }

        public override void show () {
            list.show();
            base.show();
            return;
        }

        public void on_add_source () {
            var new_sources = FileSelector.source_selection((Gtk.Window) this.get_toplevel());
            if (new_sources.length < 1)
                return;
            foreach (var uri in new_sources) {
                var source = new FontConfig.FontSource(File.new_for_uri(uri));
                _sources.add(source);
                _sources.save();
                var row = new SourceRow(source);
                list.add(row);
                row.show();
                message("Added new font source : %s", source.path);
            }
            return;
        }

        public void on_remove_source () {
            var selected_row = list.get_selected_row();
            var selected_source = ((SourceRow) selected_row.get_child()).source;
            _sources.remove(selected_source);
            _sources.save();
            list.remove(selected_row);
            message("Removed font source : %s", selected_source.path);
            return;
        }

    }

}
