/* Dialogs.vala
 *
 * Copyright (C) 2009-2024 Jerry Casiano
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

    public const string [] FONT_MIMETYPES = {
        "application/x-font-ttf",
        "application/x-font-ttc",
        "application/x-font-otf",
        "application/x-font-type1",
        "font/ttf",
        "font/ttc",
        "font/otf",
        "font/type1",
        "font/collection"
    };

    namespace FileSelector {

        public Gtk.FileDialog get_executable () {
            var dialog = new Gtk.FileDialog() {
                modal = true,
                accept_label = _("_Select"),
                title = _("Select executable"),
            };
            File bindir = File.new_for_path(BINDIR);
            dialog.set_initial_folder(bindir);
            return dialog;
        }

        public Gtk.FileDialog get_target_directory () {
            var dialog = new Gtk.FileDialog() {
                modal = true,
                accept_label = _("_Select"),
                title = _("Select destination"),
            };
            return dialog;
        }

        public Gtk.FileDialog get_selections () {
            var filter = new Gtk.FileFilter();
            var file_roller = new ArchiveManager();
            if (file_roller.available)
                foreach (string mimetype in file_roller.get_supported_types())
                    filter.add_mime_type(mimetype);
            foreach (var mimetype in FONT_MIMETYPES)
                filter.add_mime_type(mimetype);
            var dialog = new Gtk.FileDialog() {
                modal = true,
                title = _("Select files to install"),
            };
            dialog.set_default_filter(filter);
            return dialog;
        }

        public Gtk.FileDialog get_selected_sources () {
            var dialog = new Gtk.FileDialog() {
                modal = true,
                title = _("Select source folders"),
            };
            return dialog;
        }

    }

    public class ExportSettings : PreferenceList {

        public Gtk.Switch settings { get; private set; }
        public Gtk.Switch collections { get; private set; }
        public Gtk.Switch sources { get; private set; }
        public Gtk.Switch fonts { get; private set; }
        public Gtk.Switch actions { get; private set; }

        public ExportSettings () {
            controls.set_visible(false);
            settings = add_preference_switch(_("Font Configuration"));
            collections = add_preference_switch(_("Font Collections"));
            sources = add_preference_switch(_("Font Sources"));
            fonts = add_preference_switch(_("Installed Fonts"));
            actions = add_preference_switch(_("Custom Actions"));
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-export-dialog.ui")]
    public class ExportDialog : Gtk.Window {

        public ExportSettings export_settings { get; private set; }

        public ExportDialog (Gtk.Window? parent) {
            set_transient_for(parent);
            export_settings = new ExportSettings();
            set_child(export_settings);
        }

        [GtkCallback]
        void on_cancel_clicked () {
            destroy();
            return;
        }

        [GtkCallback]
        void on_export_clicked () {
            destroy();
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-progress-dialog.ui")]
    public class ProgressDialog : Gtk.Window {

        public bool show_app_icon {
            get {
                return app_icon.visible;
            }
            set {
                app_icon.set_visible(value);
            }
        }

        [GtkChild] public unowned Gtk.Label title_label { get; }
        [GtkChild] public unowned Gtk.Label message_label { get; }
        [GtkChild] public unowned Gtk.Overlay overlay { get; }
        [GtkChild] public unowned Gtk.ProgressBar progress_bar { get; }

        [GtkChild] unowned Gtk.Image app_icon;

        public ProgressDialog (string? title) {
            widget_set_name(this, "FontManagerProgressDialog");
            widget_set_expand(progress_bar, true);
            add_css_class("dialog");
            title_label.set_label(title != null ? title : "");
        }

        public void update (ProgressData data) {
            message_label.set_label(data.message);
            progress_bar.set_fraction(data.progress);
            return;
        }

    }

    [GtkTemplate (ui = "/org/gnome/FontManager/ui/font-manager-remove-dialog.ui")]
    public class RemoveDialog : Gtk.Window {

        public signal void start_removal ();
        public signal void end_removal ();

        [GtkChild] public unowned Gtk.Button cancel_button { get; }
        [GtkChild] public unowned Gtk.Button delete_button { get; }
        [GtkChild] public unowned RemoveListView remove_list { get; }

        public RemoveDialog (Gtk.Window? parent) {
            set_transient_for(parent);
            var fonts = get_available_fonts(null);
            var sorted_fonts = sort_json_font_listing(fonts);
            sorted_fonts.foreach_element((a, i, n) => {
                Json.Object family = n.get_object();
                family.set_boolean_member("active", false);
                Json.Array variations = family.get_array_member("variations");
                variations.foreach_element((a, i, n) => {
                    n.get_object().set_boolean_member("active", false);
                });
            });
            update_item_preview_text(sorted_fonts);
            remove_list.available_fonts = sorted_fonts;
            delete_button.set_sensitive(false);
            remove_list.changed.connect(() => {
                bool sensitive = remove_list.selected_files.size > 0;
                delete_button.set_sensitive(sensitive);
                if (sensitive) {
                    cancel_button.add_css_class(STYLE_CLASS_SUGGESTED_ACTION);
                    delete_button.add_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
                } else {
                    cancel_button.remove_css_class(STYLE_CLASS_SUGGESTED_ACTION);
                    delete_button.remove_css_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
                }
            });
        }

        [GtkCallback]
        void on_cancel_clicked () {
            destroy();
            return;
        }

        [GtkCallback]
        void on_delete_clicked () {
            hide();
            start_removal();
            Library.remove.begin(remove_list.selected_files,(obj, res) => {
                Library.remove.end(res);
                end_removal();
                destroy();
            });
            return;
        }

    }

}

