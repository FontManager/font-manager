/* ModeSelector.vala
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

public class ModeSelector : Gtk.Box {

    public signal void selection_changed (int mode);

    public int mode {
        get {
            int i = 0;
            foreach (Gtk.Widget child in get_children())
                if (((Gtk.ToggleButton) child).active)
                    return i;
                else
                    i++;
            return -1;
        }
        set {
            if (value < 0 || value == mode || value >= n_modes)
                return;
            ((Gtk.ToggleButton) get_children().nth_data(value)).set_active(true);
        }
    }

    public uint n_modes {
        get {
            return get_children().length();
        }
    }

    public Gtk.Notebook notebook {
        get {
            return _notebook;
        }

        set {
            real_set_notebook(value);
            return;
        }
    }

    private Gtk.Notebook _notebook;
    private Gtk.RadioButton radio_group = null;

    construct {
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        homogeneous = true;
        orientation = Gtk.Orientation.HORIZONTAL;
        /* Some themes/engines honor this. i.e. Adwaita */
        get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
    }

    public bool add_mode (Gtk.Widget label) {
        uint begin_n_modes = n_modes;
        Gtk.RadioButton new_mode;
        if (label is Gtk.Label)
        #if GTK_314
            label.halign = label.valign = Gtk.Align.CENTER;
        #else
            ((Gtk.Misc) label).set_alignment(0.5f, 0.5f);
        #endif
        if (radio_group == null) {
            radio_group = new_mode = new Gtk.RadioButton(null);
            mode = 0;
        } else
            new_mode = new Gtk.RadioButton.from_widget(radio_group);
        ((Gtk.Container) new_mode).add(label);
        new_mode.can_focus = false;
        ((Gtk.ToggleButton) new_mode).draw_indicator = false;
        new_mode.xalign = new_mode.yalign = 0.5f;
        pack_start(new_mode, true, true, 0);
        new_mode.toggled.connect((toggle) => {
            if (toggle.active) {
                selection_changed(mode);
            }
        });
        set_junction_sides();
        new_mode.show_all();
        this.visible = n_modes > 1;
        return n_modes > begin_n_modes;
    }

    public bool remove_mode (int mode)
    requires (mode >= 0 && mode < n_modes && n_modes > 0) {
        uint begin_n_modes = n_modes;
        remove(get_children().nth_data(mode));
        while (this.mode >= mode)
            this.mode--;
        selection_changed(mode);
        set_junction_sides();
        this.visible = n_modes > 1;
        return begin_n_modes > n_modes;
    }

    /* Some themes/engines honor junction sides, i.e. Unico */
    void set_junction_sides () {
        if (n_modes < 1)
            return;
        var children = get_children();
        if (n_modes == 1)
            children.first().data.get_style_context().set_junction_sides(Gtk.JunctionSides.NONE);
        else {
            /* Set all to flat edges */
            foreach (Gtk.Widget child in children)
                child.get_style_context().set_junction_sides(Gtk.JunctionSides.LEFT | Gtk.JunctionSides.RIGHT);
            /* Round end caps */
            children.first().data.get_style_context().set_junction_sides(Gtk.JunctionSides.RIGHT);
            children.last().data.get_style_context().set_junction_sides(Gtk.JunctionSides.LEFT);
        }
        return;
    }

    private void real_set_notebook (Gtk.Notebook? new_notebook) {
        if (_notebook != null)
            while (n_modes > 0)
                remove_mode(0);
        _notebook = new_notebook;
        set_notebook_event_handlers();
        int n_pages = _notebook.get_n_pages();
        if (!(n_pages > 0))
            return;
        for (int i = 0; i < n_pages; i++) {
            var child = _notebook.get_nth_page(i);
            Gtk.Label label = new Gtk.Label(_notebook.get_tab_label_text(child));
            add_mode(label);
        }
        if (_notebook.page > 0)
            mode = _notebook.page;
        else
            _notebook.page = 0;
        _notebook.show();
        return;
    }

    private void set_notebook_event_handlers () {
        /* (child, page_num) */
        _notebook.page_added.connect((c, p) => {
            add_mode(new Gtk.Label(_notebook.get_tab_label_text(c)));
        });
        _notebook.page_removed.connect((c, p) => {
            remove_mode((int) p);
        });
        selection_changed.connect((mode) => {_notebook.set_current_page(mode);});
        _notebook.show_border = false;
        _notebook.show_tabs = false;
        return;
    }

}
