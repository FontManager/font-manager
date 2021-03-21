/* Fontconfig.vala
 *
 * Copyright (C) 2009 - 2021 Jerry Casiano
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
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

namespace FontManager {

    /**
     * Fontconfig default font properties configuration
     */
    public class DefaultProperties : Properties {

        public DefaultProperties () {
            type = PropertiesType.DEFAULT;
            target_file = "19-DefaultProperties.conf";
            load();
        }

    }

    /**
     * Fontconfig display properties configuration
     */
    public class DisplayProperties : Properties {

        public DisplayProperties () {
            type = PropertiesType.DISPLAY;
            target_file = "19-DisplayProperties.conf";
            load();
        }

    }

    /**
     * Fontconfig font specific properties configuration
     */
    public class FontProperties : DefaultProperties {

        /**
         * Emitted whenever family or font changes.
         */
        public signal void changed ();

        /**
         * Name of font family this configuration will apply to.
         * If only family is set, configuration will apply to all variations.
         */
        public string? family { get; set; default = null; }

        /**
         * Font this configuration will apply to.
         * If font is set, configuration will apply only to that specific variation.
         */
        public Font? font { get; set; default = null; }

        public FontProperties () {
            notify["family"].connect((source, pspec) => {
                load();
                changed();
            });
            notify["font"].connect((s, p) => {
                family = font.is_valid() ? font.family : null;
            });
            load();
        }

        /**
         * Load saved settings
         */
        public override bool load () {
            /* Load global settings */
            target_file = "19-DefaultProperties.conf";
            base.load();
            /* Load any settings that apply to entire family */
            if (family != null) {
                target_file = "29-%s.conf".printf(family);
                base.load();
            }
            /* Load font specific settings */
            if (font.is_valid()) {
                target_file = "29-%s.conf".printf(FontManager.to_filename(font.description));
                base.load();
            }
            return true;
        }

        /**
         * Save settings to file
         */
        public override bool save () {
            if (font.is_valid())
                target_file = "29-%s.conf".printf(FontManager.to_filename(font.description));
            else if (family != null)
                target_file = "29-%s.conf".printf(family);
            return base.save();
        }

        protected override void add_match_criteria (XmlWriter writer) {
            if (family != null)
                writer.add_test_element("family", "contains", "string", family);
            if (font.is_valid()) {
                writer.add_test_element("slant", "eq", "int", font.slant.to_string());
                writer.add_test_element("weight", "eq", "int", font.weight.to_string());
                writer.add_test_element("width", "eq", "int", font.width.to_string());
            }
            base.add_match_criteria(writer);
            return;
        }

    }

    /**
     * #Gtk.Actionbar containing a save and discard button along with a notice
     * informing the user that changes may not take effect immediately.
     * Intended for use in pages which generate Fontconfig configuration files.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-font-config-controls.ui")]
    public class FontConfigControls : Gtk.ActionBar {

        /**
         * Emitted when the user clicks Save
         */
        public signal void save_selected ();

        /**
         * Emitted when the user clicks Discard
         */
        public signal void discard_selected ();

        /**
         * Informational notice displayed between discard and save buttons.
         */
        public Gtk.Label note { get; private set; }

        [GtkChild] unowned Gtk.Button save_button;
        [GtkChild] unowned Gtk.Button discard_button;

        public override void constructed () {
            save_button.clicked.connect(() => { save_selected(); });
            discard_button.clicked.connect(() => { discard_selected(); });
            base.constructed();
            return;
        }

    }

    /**
     * Base class for panes which generate Fontconfig configuration files.
     */
    public class FontConfigSettingsPage : SettingsPage {

        const string help_text = _("""Select save to generate a fontconfig configuration file from the above settings.

Select discard to remove the configuration file and revert to the default settings.

Note that not all environments/applications will honor these settings.""");

        protected FontConfigControls controls;

        construct {
            controls = new FontConfigControls();
            box.pack_end(controls, false, false, 0);
            controls.show();
            var help = new InlineHelp();
            help.margin_bottom = 56;
            help.margin_start = help.margin_end = 18;
            help.valign = help.halign = Gtk.Align.END;
            help.message.set_text(help_text);
            add_overlay(help);
            help.show();
        }

    }

    public class DisplayPreferences : FontConfigSettingsPage {

        DisplayPropertiesPane pane;

        public DisplayPreferences () {
            pane = new DisplayPropertiesPane();
            box.pack_start(pane, true, true, 0);
            connect_signals();
            pane.show();
        }

        void connect_signals () {
            controls.save_selected.connect(() => {
                if (pane.properties.save())
                    show_message(_("Settings saved to file."));
            });
            controls.discard_selected.connect(() => {
                if (pane.properties.discard())
                    show_message(_("Removed configuration file."));
            });
            return;
        }

    }

    /**
     * Preference pane allowing configuration of display related Fontconfig properties
     */
    public class DisplayPropertiesPane : Gtk.ScrolledWindow {

        public DisplayProperties properties { get; private set; }

        Gtk.Grid grid;
        LabeledSpinButton dpi;
        LabeledSpinButton scale;
        OptionScale lcdfilter;
        SubpixelGeometry spg;
        Gtk.Widget [] widgets;

        public DisplayPropertiesPane () {
            set_size_request(480, 420);
            grid = new Gtk.Grid();
            properties = new DisplayProperties();
            properties.config_dir = FontManager.get_user_fontconfig_directory();
            properties.load();
            dpi = new LabeledSpinButton(_("Target DPI"), 0, 1000, 1);
            scale = new LabeledSpinButton(_("Scale Factor"), 0, 1000, 0.1);
            string [] filters = {};
            for (int i = 0; i <= LCDFilter.LEGACY; i++)
                filters += ((LCDFilter) i).to_string();
            lcdfilter = new OptionScale(_("LCD Filter"), filters);
            spg = new SubpixelGeometry();
            widgets = { dpi, scale, lcdfilter, spg };
            pack_components();
            bind_properties();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            grid.foreach((w) => { w.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW); });
            grid.show();
        }

        void pack_components () {
            for (int i = 0; i < widgets.length; i++)
                grid.attach(widgets[i], 0, i - 1, 2, 1);
            add(grid);
            return;
        }

        void bind_properties () {
            properties.bind_property("dpi", dpi, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("scale", scale, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("lcdfilter", lcdfilter, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("rgba", spg, "rgba", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            return;
        }

    }

    public class RenderingPreferences : FontConfigSettingsPage {

        FontPropertiesPane pane;

        public RenderingPreferences () {
            pane = new FontPropertiesPane();
            box.pack_start(pane, true, true, 0);
            connect_signals();
            pane.show();
        }

        void connect_signals () {
            controls.save_selected.connect(() => {
                if (pane.properties.save())
                    show_message(_("Settings saved to file."));
            });
            controls.discard_selected.connect(() => {
                if (pane.properties.discard())
                    show_message(_("Removed configuration file."));
            });
            return;
        }

        public void set_family (string? family) {
            pane.properties.family = family;
            return;
        }

        public void set_font (Font? font) {
            pane.properties.font = font;
            return;
        }

    }

    /**
     * Preference pane allowing configuration of FontConfig rendering properties
     */
    public class FontPropertiesPane : Gtk.ScrolledWindow {

        public FontProperties properties { get; private set; }

        Gtk.Grid grid;
        Gtk.Revealer hinting_options;
        Gtk.Grid hinting_options_grid;
        Gtk.Expander expander;
        Gtk.CheckButton autohint;
        OptionScale hintstyle;
        LabeledSwitch antialias;
        LabeledSwitch hinting;
        LabeledSwitch embeddedbitmap;
        SizeOptions size_options;
        Gtk.Widget [] widgets;

        public FontPropertiesPane () {
            set_size_request(450, 450);
            grid = new Gtk.Grid();
            properties = new FontProperties();
            properties.config_dir = FontManager.get_user_fontconfig_directory();
            properties.load();
            antialias = new LabeledSwitch(_("Antialias"));
            hinting = new LabeledSwitch(_("Hinting"));
            autohint = new Gtk.CheckButton.with_label(_("Enable Autohinter"));
            autohint.margin = DEFAULT_MARGIN;
            hinting_options = new Gtk.Revealer();
            hinting_options.set_transition_duration(450);
            hinting_options_grid = new Gtk.Grid();
            hinting_options_grid.margin = (int) (DEFAULT_MARGIN * 1.5);
            string [] hintstyles = {};
            for (int i = 0; i <= HintStyle.FULL; i++)
                hintstyles += ((HintStyle) i).to_string();
            hintstyle = new OptionScale(_("Hinting Style"), hintstyles);
            embeddedbitmap = new LabeledSwitch(_("Use Embedded Bitmaps"));
            size_options = new SizeOptions();
            expander = new Gtk.Expander(_(" Size Restrictions "));
            expander.margin = DEFAULT_MARGIN * 2;
            expander.notify["expanded"].connect(() => {
                if (expander.expanded)
                    expander.set_label(_(" Apply settings to point sizes "));
                else
                    expander.set_label(_(" Size Restrictions "));
            });

            /* Order of first five widgets matters */
            widgets = { antialias, hinting, hinting_options, embeddedbitmap, expander,
                        hinting_options_grid, autohint, hintstyle, size_options, grid };

            foreach (var widget in widgets)
                widget.show();

            bind_properties();
            pack_components();

            grid.foreach((w) => { w.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW); });
            grid.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            update_sensitivity();
        }

        void pack_components () {
            hinting_options_grid.attach(autohint, 0, 0, 2, 1);
            hinting_options_grid.attach(hintstyle, 0, 1, 2, 1);
            hinting_options.add(hinting_options_grid);
            expander.add(size_options);
            for (int i = 0; i < 5; i++)
                grid.attach(widgets[i], 0, i, 2, 1);
            add(grid);
            return;
        }

        void bind_properties () {
            properties.bind_property("antialias", antialias.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("hinting", hinting.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("autohint", autohint, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("hintstyle", hintstyle.adjustment, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("embeddedbitmap", embeddedbitmap.toggle, "active", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("less", size_options.less, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            properties.bind_property("more", size_options.more, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            hinting.toggle.bind_property("active", hinting_options, "reveal-child", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            properties.notify["font"].connect(() => { update_sensitivity(); });
            properties.notify["family"].connect(() => { update_sensitivity(); });
            return;
        }

        void update_sensitivity () {
            if (properties.font == null && properties.family == null)
                expander.hide();
            else
                expander.show();
            return;
        }

        internal class SizeOptions : Gtk.Grid {

            public LabeledSpinButton less { get; private set; }
            public LabeledSpinButton more { get; private set; }

            public SizeOptions () {
                less = new LabeledSpinButton(_("Smaller than"), 0, 96, 0.5);
                more = new LabeledSpinButton(_("Larger than"), 0, 96, 0.5);
                attach(less, 0, 0, 1, 1);
                attach(more, 1, 0, 1, 1);
                less.show();
                more.show();
            }

        }

    }

    public class SubstitutionPreferences : FontConfigSettingsPage {

        BaseControls base_controls;
        SubstituteList sub_list;

        public SubstitutionPreferences () {
            sub_list = new SubstituteList();
            sub_list.expand = true;
            base_controls = new BaseControls();
            base_controls.add_button.set_tooltip_text(_("Add alias"));
            base_controls.remove_button.set_tooltip_text(_("Remove selected alias"));
            set_control_sensitivity(base_controls.remove_button, false);
            box.pack_start(base_controls, false, false, 1);
            add_separator(box, Gtk.Orientation.HORIZONTAL);
            box.pack_end(sub_list, true, true, 1);
            sub_list.load();
            connect_signals();
            get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            base_controls.show();
            sub_list.show();
        }

        void connect_signals () {
            base_controls.add_selected.connect(() => {
                sub_list.on_add_row();
            });
            base_controls.remove_selected.connect(() => {
                sub_list.on_remove_row();
            });
            sub_list.row_selected.connect((r) => {
                if (r != null)
                    base_controls.remove_button.show();
                else
                    base_controls.remove_button.hide();
                set_control_sensitivity(base_controls.remove_button, r != null);
            });
            controls.save_selected.connect(() => {
                if (sub_list.save())
                    show_message(_("Settings saved to file."));
            });
            controls.discard_selected.connect(() => {
                if (sub_list.discard())
                    show_message(_("Removed configuration file."));
            });
            sub_list.place_holder.map.connect(() => {
                base_controls.add_button.set_relief(Gtk.ReliefStyle.NORMAL);
                base_controls.add_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            sub_list.place_holder.unmap.connect(() => {
                base_controls.add_button.set_relief(Gtk.ReliefStyle.NONE);
                base_controls.add_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            });
            return;
        }

    }

    internal Gtk.Widget? get_bin_child (Gtk.Widget? widget) {
        if (widget == null)
            return null;
        return ((Gtk.Bin) widget).get_child();
    }

    /**
     * Single line widget representing a substitute font family
     * in a Fontconfig <alias> entry.
     */
    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-substitute.ui")]
    public class Substitute : Gtk.Grid {

        public string? family { get; set; default = null; }
        public Gtk.TreeModel? completion_model { get; set; default = null; }

        /**
         * prefer, accept, or default
         */
        public string? priority { get; set; default = null; }

        [GtkChild] unowned Gtk.Button close;
        [GtkChild] unowned Gtk.ComboBoxText type;
        [GtkChild] unowned Gtk.Entry target;

        public override void constructed () {
            target.completion  = new Gtk.EntryCompletion();
            BindingFlags flags = BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE;
            bind_property("completion-model", target.completion, "model",  flags);
            notify["completion-model"].connect_after(() => {
                target.completion.set_text_column(0);
            });
            var entry = (Gtk.Entry) get_bin_child(type);
            entry.bind_property("text", this, "priority", flags);
            target.bind_property("text", this, "family", flags);
            close.clicked.connect(() => {
                Gtk.Widget parent = this.get_parent();
                this.destroy();
                parent.destroy();
            });
            base.constructed();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-substitute-row.ui")]
    public class SubstituteRow : Gtk.Box {

        public string? family { get; set; default = null; }
        public Gtk.TreeModel? completion_model { get; set; default = null; }

        [GtkChild] unowned Gtk.Entry entry;
        [GtkChild] unowned Gtk.ListBox list;
        [GtkChild] unowned Gtk.Button add_button;

        public override void constructed () {
            entry.completion = new Gtk.EntryCompletion();
            BindingFlags flags = BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE;
            bind_property("completion-model", entry.completion, "model", flags);
            entry.bind_property("text", this, "family", flags);
            notify["completion-model"].connect_after(() => {
                entry.completion.set_text_column(0);
            });
            base.constructed();
            return;
        }

        [GtkCallback]
        void on_add_button_clicked () {
            var sub = new Substitute() { completion_model = completion_model };
            list.insert(sub, -1);
            sub.show();
            return;
        }

        [GtkCallback]
        void on_entry_changed () {
            set_control_sensitivity(add_button, entry.get_text() != null);
            return;
        }

        public SubstituteRow.from_element (AliasElement alias) {
            family = alias.family;
            string [] priorities = { "default", "accept", "prefer" };
            for (int i = 0; i < priorities.length; i++) {
                foreach (string family in alias[priorities[i]].list()) {
                    Substitute sub = new Substitute();
                    sub.completion_model = completion_model;
                    sub.family = family;
                    sub.priority = priorities[i];
                    list.insert(sub, -1);
                    sub.show();
                }
            }
        }

        public AliasElement to_element () {
            var res = new AliasElement(entry.get_text());
            int i = 0;
            var sub = (Substitute) get_bin_child(list.get_row_at_index(i));
            while (sub != null) {
                if (sub.family != null && sub.family != "")
                    res[sub.priority].add(sub.family);
                i++;
                sub = (Substitute) get_bin_child(list.get_row_at_index(i));
            }
            return res;
        }

    }

    public class SubstituteList : Gtk.ScrolledWindow {

        public signal void row_selected (Gtk.ListBoxRow? selected_row);

        public PlaceHolder place_holder { get; private set; }

        Gtk.ListBox list;
        Gtk.ListStore completion_model;

        construct {
            name = "FontManagerSubstituteList";
            string w1 = _("Font Substitutions");
            string w2 = _("Easily substitute one font family for another.");
            string w3 = _("To add a new substitute click the add button in the toolbar.");
            place_holder = new PlaceHolder(w1, w2, w3, "edit-find-replace-symbolic");
            list = new Gtk.ListBox();
            list.set_placeholder(place_holder);
            list.expand = true;
            add(list);
            list.row_selected.connect((r) => { row_selected(r); });
            list.show();
            place_holder.show();
            completion_model = new Gtk.ListStore(1, typeof(string));
            foreach (string family in list_available_font_families()) {
                Gtk.TreeIter iter;
                completion_model.append(out iter);
                completion_model.set(iter, 0, family, -1);
            }
        }

        public void on_add_row () {
            var row = new SubstituteRow() { completion_model = completion_model };
            list.insert(row, -1);
            row.show();
            return;
        }

        public void on_remove_row () {
            ((Gtk.Widget) list.get_selected_row()).destroy();
            return;
        }

        public bool discard () {
            while (list.get_row_at_index(0) != null)
                ((Gtk.Widget) list.get_row_at_index(0)).destroy();
            var aliases = new Aliases() {
                config_dir = get_user_fontconfig_directory(),
                target_file = "39-Aliases.conf"
            };
            File file = File.new_for_path(aliases.get_filepath());
            try {
                if (file.delete())
                    return true;
            } catch (Error e) {
                /* Try to save empty file */
                return save();
            }
            return false;
        }

        public bool load () {
            var aliases = new Aliases() {
                config_dir = get_user_fontconfig_directory(),
                target_file = "39-Aliases.conf"
            };
            bool res = aliases.load();
            foreach (AliasElement element in aliases.list()) {
                var row = new SubstituteRow.from_element(element);
                row.completion_model = completion_model;
                list.insert(row, -1);
                row.show();
            }
            list.set_sort_func((row1, row2) => {
                var a = (SubstituteRow) get_bin_child(row1);
                var b = (SubstituteRow) get_bin_child(row2);
                return natural_sort(a.family, b.family);
            });
            list.invalidate_sort();
            return res;
        }

        public bool save () {
            var aliases = new Aliases() {
                config_dir = get_user_fontconfig_directory(),
                target_file = "39-Aliases.conf"
            };
            int i = 0;
            var alias_row = (SubstituteRow) get_bin_child(list.get_row_at_index(i));
            while (alias_row != null) {
                AliasElement? element = alias_row.to_element();
                /* Empty rows are allowed in the list - don't save one */
                if (element != null && element.family != null && element.family != "")
                    aliases.add_element(element);
                i++;
                alias_row = (SubstituteRow) get_bin_child(list.get_row_at_index(i));
            }
            bool res = aliases.save();
            return res;
        }

    }

}

