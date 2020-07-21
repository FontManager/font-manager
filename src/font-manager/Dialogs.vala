/* Dialogs.vala
 *
 * Copyright (C) 2009 - 2020 Jerry Casiano
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

    public class ProgressDialog : Gtk.MessageDialog {

        Gtk.ProgressBar progress_bar;

        public ProgressDialog (string? title) {
            Object(transient_for: main_window, modal: true, text: title);
            progress_bar = new Gtk.ProgressBar();
            ((Gtk.Box) get_message_area()).pack_end(progress_bar);
            set_default_size(475, 125);
        }

        public void set_progress (ProgressData data) {
            secondary_text = data.message;
            if (!progress_bar.is_visible())
                progress_bar.show();
            progress_bar.set_fraction(data.progress);
            return;
        }

    }

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

        public string? get_target_directory () {
            var dialog = new Gtk.FileChooserNative(_("Select Destination"),
                                                    main_window,
                                                    Gtk.FileChooserAction.SELECT_FOLDER,
                                                    _("_Select"),
                                                    _("_Cancel"));
            dialog.set_select_multiple(false);
            dialog.set_do_overwrite_confirmation(true);
            dialog.set_create_folders(true);
            string? selection = null;
            if (dialog.run() == Gtk.ResponseType.ACCEPT)
                selection = dialog.get_filename();
            dialog.destroy();
            return selection;
        }

        public StringHashset get_selections () {
            var selections = new StringHashset();
            var dialog = new Gtk.FileChooserNative(_("Select files to install"),
                                                    main_window,
                                                    Gtk.FileChooserAction.OPEN,
                                                    _("_Open"),
                                                    _("_Cancel"));
            var filter = new Gtk.FileFilter();
            var file_roller = new ArchiveManager();
            if (file_roller.available)
                foreach (string mimetype in file_roller.get_supported_types())
                    filter.add_mime_type(mimetype);
            foreach (var mimetype in FONT_MIMETYPES)
                filter.add_mime_type(mimetype);
            dialog.set_filter(filter);
            dialog.set_select_multiple(true);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                foreach (var uri in dialog.get_uris())
                    selections.add(File.new_for_uri(uri).get_path());
            }
            dialog.destroy();
            return selections;
        }

        public string? [] get_selected_sources () {
            string? [] arr = { };
            var dialog = new Gtk.FileChooserNative(_("Select source folders"),
                                                    main_window,
                                                    Gtk.FileChooserAction.SELECT_FOLDER,
                                                    _("_Open"),
                                                    _("_Cancel"));
            dialog.set_select_multiple(true);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                foreach (var uri in dialog.get_uris())
                    arr += uri;
            }
            dialog.destroy();
            return arr;
        }

    }

    namespace RemoveDialog {

        public StringHashset get_selections (Gtk.TreeModel model) {
            Gtk.HeaderBar? header = null;
            bool use_csd = main_window != null ? main_window.use_csd : false;
            var selections = new StringHashset();
            FontListPane? tree = null;
            var dialog = new Gtk.Dialog();
            dialog.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            if (use_csd)
                header = new Gtk.HeaderBar();
            var content_area = dialog.get_content_area();
            var filter = new UserFonts();
            filter.update();

            if (filter.size > 0) {
                var scroll = new Gtk.ScrolledWindow(null, null);
                if (use_csd) {
                    header.set_title(_("Select fonts to remove"));
                    var cancel = new Gtk.Button.with_mnemonic(_("_Cancel"));
                    var remove = new Gtk.Button.with_mnemonic(_("_Delete"));
                    cancel.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    remove.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    cancel.clicked.connect(() => { dialog.response(Gtk.ResponseType.CANCEL); });
                    remove.clicked.connect(() => { dialog.response(Gtk.ResponseType.ACCEPT); });
                    header.pack_start(cancel);
                    header.pack_end(remove);
                    dialog.set_titlebar(header);
                    header.show_all();
                } else {
                    dialog.set_title(_("Select fonts to remove"));
                    dialog.add_buttons(_("_Cancel"), Gtk.ResponseType.CANCEL,
                                       _("_Delete"), Gtk.ResponseType.ACCEPT,
                                       null);
                }
                tree = new FontListPane();
                tree.fontlist = new UserFontList();
                tree.set("model", model, "filter", filter, "expand", true, null);
                scroll.add(tree);
                content_area.add(scroll);
                dialog.set_size_request(540, 480);
                scroll.show_all();
            } else {
                var tmpl = "<big>%s</big>";
                var msg = _("Fonts installed in your home directory will appear here.");
                var content = new PlaceHolder(tmpl.printf(msg), "go-home-symbolic");
                if (use_csd)
                    header.show_close_button = true;
                content_area.add(content);
                content.expand = true;
                content.show();
                dialog.set_size_request(270, 240);
            }

            dialog.set("modal", true, "destroy-with-parent", true, null);
            dialog.set_transient_for(main_window);
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                dialog.hide();
                selections = ((UserFontList) tree.fontlist).get_selections();
            }
            dialog.destroy();
            return selections;
        }

    }

}
