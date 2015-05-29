/* DisplayPropertiesPane.vala
 *
 * Copyright (C) 2009 - 2015 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

namespace FontConfig {

    public class DisplayPropertiesPane : Gtk.ScrolledWindow {

        public DisplayProperties properties { get; private set; }

        private Gtk.Grid grid;
        private LabeledSpinButton dpi;
        private LabeledSpinButton scale;
        private OptionScale lcdfilter;
        private SubpixelGeometry spg;

        public DisplayPropertiesPane () {
            grid = new Gtk.Grid();
            grid.margin = 24;
            properties = new DisplayProperties();
            dpi = new LabeledSpinButton(_("Target DPI"), 0, 1000, 1);
            scale = new LabeledSpinButton(_("Scale factor"), 0, 1000, 1);
            string [] filters = {};
            for (int i = 0; i < 4; i++)
                filters += ((LCDFilter) i).to_string();
            lcdfilter = new OptionScale(_("LCD Filter"), filters);
            spg = new SubpixelGeometry();
            pack_components();
            bind_properties();
            grid.foreach((w) => { w.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW); });
            grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            set_size_request(480, 420);
        }

        public override void show () {
            dpi.show();
            scale.show();
            lcdfilter.show();
            spg.show();
            grid.show();
            base.show();
        }

        private void pack_components () {
            grid.attach(dpi, 0, 0, 2, 1);
            grid.attach(scale, 0, 1, 2, 1);
            grid.attach(lcdfilter, 0, 2, 2, 1);
            grid.attach(spg, 0, 3, 2, 1);
            add(grid);
            return;
        }

        private void bind_properties () {
            properties.bind_property("dpi", dpi, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("scale", scale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("lcdfilter", lcdfilter.scale.adjustment, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("rgba", spg, "rgba", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            return;
        }

    }

}
