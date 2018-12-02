/* Application.vala
 *
 * Copyright (C) 2009 - 2018 Jerry Casiano
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

    public static GLib.Settings? settings = null;
    public static FontManager.Reject? reject = null;
    public static FontManager.Sources? sources = null;

    void update_database (DatabaseType type,
                          ProgressCallback? progress = null,
                          Cancellable? cancellable = null) {
        try {
            var main = get_database(DatabaseType.BASE);
            var child = get_database(type);
            sync_database.begin(
                child,
                type,
                progress,
                cancellable,
                (obj, res) => {
                    try {
                        bool success = sync_database.end(res);
                        child = null;
                        if (success) {
                            main.attach(type);
                        } else {
                            critical("%s failed to update", Database.get_type_name(type));
                        }
                    } catch (Error e) {
                        critical(e.message);
                    }
                }
            );
        } catch (Error e) {
            critical(e.message);
        }
        return;
    }

    void update_database_tables (ProgressCallback? progress = null,
                                 Cancellable? cancellable = null) {
        try {
            var db = get_database(DatabaseType.BASE);
            DatabaseType [] types = { DatabaseType.FONT,
                                      DatabaseType.METADATA,
                                      DatabaseType.ORTHOGRAPHY };
            foreach (var type in types)
                db.detach(type);
        } catch (Error e) {
            critical(e.message);
        }
        update_database(DatabaseType.FONT, progress, cancellable);
        update_database(DatabaseType.METADATA, progress, cancellable);
        update_database(DatabaseType.ORTHOGRAPHY, progress, cancellable);
        return;
    }

    StringHashset? get_command_line_files (ApplicationCommandLine cl) {
        VariantDict options = cl.get_options_dict();
        Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
        if (argv == null)
            return null;
        string* [] filelist = argv.get_bytestring_array();
        if (filelist.length == 0)
            return null;
        var files = new StringHashset();
        foreach (var file in filelist)
            files.add(cl.create_file_for_arg(file).get_path());
        return files;
    }

    StringHashset? get_command_line_input (VariantDict options) {
        Variant argv = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
        if (argv == null)
            return null;
        string* [] list = argv.get_bytestring_array();
        if (list.length == 0)
            return null;
        var input = new StringHashset();
        foreach (var str in list)
            input.add(str);
        return input;
    }

    [DBus (name = "org.gnome.FontManager")]
    public class Application: Gtk.Application  {

        [DBus (visible = false)]
        public bool update_in_progress { get; private set; default = false; }
        [DBus (visible = false)]
        public StringHashset? available_font_families { get; set; default = null; }

        bool category_update_required = false;
        MainWindow? main_window = null;
        StringHashset? attached = null;

        const OptionEntry[] options = {
            { "about", 'a', 0, OptionArg.NONE, null, "About the application", null },
            { "version", 'v', 0, OptionArg.NONE, null, "Show application version", null },
            { "install", 'i', 0, OptionArg.NONE, null, "Space separated list of files to install.", null },
            { "enable", 'e', 0, OptionArg.NONE, null, "Enable specified font families", null },
            { "disable", 'd', 0, OptionArg.NONE, null, "Disable specified font families", null },
            { "list", 0, 0, OptionArg.NONE, null, "List available font families.", null },
            { "list-full", 0, 0, OptionArg.NONE, null, "Full listing including face information. (JSON)", null },
            { "fatal", 'F', 0, OptionArg.NONE, null, "Fatal errors", null },
            { "", 0, 0, OptionArg.FILENAME_ARRAY, null, null, null },
            { null }
        };

        uint dbus_id = 0;

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
            add_main_option_entries(options);
        }

        public static Gtk.Window? get_current_window () {
            Gtk.Application application = GLib.Application.get_default() as Gtk.Application;
            unowned GLib.List <weak Gtk.Window> windows = application.get_windows();
            Gtk.Window? most_recent = null;
            if (windows != null)
                most_recent = windows.nth_data(0);
            return most_recent;
        }

        void update_interface_on_db_change () {
            if (main_window == null)
                return;
            if (category_update_required &&
                attached.contains("Fonts") &&
                attached.contains("Metadata")) {
                /* Re-select category after an update to prevent blank list */
                if (main_window.sidebar.standard.selected_category != null) {
                    int index = main_window.sidebar.standard.selected_category.index;
                    var path = new Gtk.TreePath.from_indices(index, -1);
                    var tree = main_window.sidebar.standard.category_tree.tree;
                    var selection = tree.get_selection();
                    selection.unselect_all();
                    main_window.sidebar.category_model.update();
                    selection.select_path(path);
                } else {
                    main_window.sidebar.category_model.update();
                    main_window.sidebar.standard.category_tree.select_first_row();
                }
                main_window.fontlist.queue_draw();
                main_window.browser.treeview.queue_draw();
                category_update_required = false;
            }
            if (attached.contains("Fonts") &&
                attached.contains("Metadata") &&
                attached.contains("Orthography")) {
                update_in_progress = false;
                enable_user_font_configuration(true);
                main_window.fontlist.samples = get_non_latin_samples();
                if (main_window.fontlist.samples == null)
                    warning("Failed to generate previews for fonts which do not support Basic Latin");
            }
            return;
        }

        bool update_status () {
            attached.clear();
            try {
                var db = get_database(DatabaseType.BASE);
                db.execute_query("PRAGMA database_list");
                foreach (unowned Sqlite.Statement row in db)
                    attached.add(row.column_text(1));
            } catch (Error e) { return true; }
            update_interface_on_db_change();
            return false;
        }

        int authorizer (Sqlite.Action action,
                        string? name, string? unused,
                        string? db, string? trigger) {
            if (action == Sqlite.Action.ATTACH || action == Sqlite.Action.DETACH)
                Timeout.add(250, () => { return update_status(); });
            return Sqlite.OK;
        }

        public override void startup () {
            SimpleAction quit = new SimpleAction("quit", null);
            add_action(quit);
            quit.activate.connect(() => {
                if (main_window != null)
                    main_window.close();
                Idle.add(() => { this.quit(); return false; });
            });
            string? accels [] = {"<Ctrl>q", null };
            set_accels_for_action("app.quit", accels);
            settings = get_gsettings(BUS_ID);
            available_font_families = new StringHashset();
            sources = new Sources();
            reject = new Reject();
            reject.load();
            sources.load();
            base.startup();
            return;
        }

        public override void open (File [] files, string hint) {
            try {
                DBusConnection conn = Bus.get_sync(BusType.SESSION);
                conn.call_sync(FontViewer.BUS_ID,
                                FontViewer.BUS_PATH,
                                FontViewer.BUS_ID,
                                "ShowUri",
                                new Variant("(s)", files[0].get_uri()),
                                null,
                                DBusCallFlags.NONE,
                                -1,
                                null);
            } catch (Error e) {
                critical("Method call to %s failed : %s", FontViewer.BUS_ID, e.message);
            }
            return;
        }

        public override int command_line (ApplicationCommandLine cl) {
            hold();

            VariantDict options = cl.get_options_dict();
            StringHashset? filelist = get_command_line_files(cl);

            if (options.contains("fatal"))
                Log.set_always_fatal(LogLevelFlags.LEVEL_CRITICAL);

            if (filelist == null) {
                activate();
            } else if (options.contains("install")) {
                var installer = new Library.Installer();
                installer.process_sync(filelist);
            } else {
                File [] files = { File.new_for_path(filelist[0]) };
                open(files, "preview");
            }

            release();
            return 0;
        }

        public override int handle_local_options (VariantDict options) {

            int exit_status = -1;

            if (options.contains("version")) {
                show_version();
                exit_status = 0;
            }

            if (options.contains("about")) {
                show_about();
                exit_status = 0;
            }

            if (("enable" in options || "disable" in options) && reject == null) {
                reject = new Reject();
                reject.load();
            }

            if (("list" in options || "list-full" in options) && sources == null) {
                sources = new Sources();
                sources.load();
            }

            if (options.contains("enable")) {
                var accept = get_command_line_input(options);
                return_val_if_fail(accept != null, -1);
                foreach (var family in accept)
                    if (family in reject)
                        reject.remove(family);
                reject.save();
                exit_status = 0;
            }

            if (options.contains("disable")) {
                var rejects = get_command_line_input(options);
                return_val_if_fail(rejects != null, -1);
                foreach (var family in rejects)
                    reject.add(family);
                reject.save();
                exit_status = 0;
            }

            if (options.contains("list")) {
                load_user_font_resources(null, sources.list_objects());
                GLib.List <string> families = list_available_font_families();
                assert(families.length() > 0);
                foreach (string family in families)
                    stdout.printf("%s\n", family);
                exit_status = 0;
            }

            if (options.contains("list-full")) {
                update_font_configuration();
                load_user_font_resources(reject.get_rejected_files(), sources.list_objects());
                Json.Object available_fonts = get_available_fonts(null);
                Json.Array sorted_fonts = sort_json_font_listing(available_fonts);
                stdout.printf("\n%s\n\n", print_json_array(sorted_fonts, true));
                exit_status = 0;
            }

            return exit_status;
        }

        [DBus (visible = false)]
        public void refresh () requires (main_window != null) {
            if (update_in_progress)
                return;
            update_in_progress = true;
            category_update_required = true;
            enable_user_font_configuration(false);
            update_font_configuration();
            load_user_font_resources(reject.get_rejected_files(), sources.list_objects());
            Json.Object available_fonts = get_available_fonts(null);
            available_font_families.clear();
            Json.Array sorted_fonts = sort_json_font_listing(available_fonts);
            FontModel model = new FontModel();
            model.source_array = sorted_fonts;
            main_window.model = model;
            foreach (string family in available_fonts.get_members())
                available_font_families.add(family);
            update_database_tables();
            return;
        }

        protected override void activate () {
            main_window = new MainWindow();
            add_window(main_window);
            main_window.present();
            attached = new StringHashset();
            try {
                Database main = get_database(DatabaseType.BASE);
                main.db.set_authorizer(this.authorizer);
            } catch (Error e) {
                critical(e.message);
            }
            refresh();
            return;
        }

        [DBus (visible = false)]
        public new void quit () {
            /* Prevent noise during memcheck */
            {
                try {
                    Database main_db = get_database(DatabaseType.BASE);
                    main_db.unref();
                    main_db = null;
                    settings = null;
                    reject = null;
                    sources = null;
                } catch (Error e) {}
            }
            base.quit();
            return;
        }

        [DBus (visible = false)]
        public void about () {
            Gtk.show_about_dialog(main_window,
                                "program-name", About.DISPLAY_NAME,
                                "logo-icon-name", About.ICON,
                                "version", About.VERSION,
                                "copyright", About.COPYRIGHT,
                                "comments", About.COMMENT,
                                "website", About.HOMEPAGE,
                                "authors", About.AUTHORS,
                                "license", About.LICENSE,
                                "translator-credits", About.TRANSLATORS,
                                null);
            return;
        }

        [DBus (visible = false)]
        public void help () {
            try {
                Gtk.show_uri(null, "help:%s".printf(Config.PACKAGE_NAME), Gdk.CURRENT_TIME);
            } catch (Error e) {
                critical("There was an error displaying help contents : %s", e.message);
            }
            return;
        }

        [DBus (visible = false)]
        public void shortcuts () {
            string ui = Path.build_path("/", BUS_PATH, "ui", "shortcuts.ui");
            var builder = new Gtk.Builder.from_resource(ui);
            var shortcuts_window = builder.get_object("shortcuts-window") as Gtk.Window;
            shortcuts_window.delete_event.connect(() => {
                shortcuts_window.destroy();
                return true;
            });
            shortcuts_window.set_transient_for(main_window);
            shortcuts_window.present();
            return;
        }

        public override bool dbus_register (DBusConnection conn, string path) throws Error {
            base.dbus_register(conn, path);
            dbus_id = conn.register_object (BUS_PATH, this);
            if (dbus_id == 0)
                critical("Could not register Font Manager service ");
            return true;
        }

        public override void dbus_unregister (DBusConnection conn, string path) {
            if (dbus_id != 0)
                conn.unregister_object(dbus_id);
            base.dbus_unregister(conn, path);
        }

        public static int main (string [] args) {
            GLib.Intl.bindtextdomain(Config.PACKAGE_NAME, null);
            GLib.Intl.bind_textdomain_codeset(Config.PACKAGE_NAME, null);
            GLib.Intl.textdomain(Config.PACKAGE_NAME);
            GLib.Intl.setlocale(GLib.LocaleCategory.ALL, null);
            Environment.set_application_name(About.DISPLAY_NAME);
            //enable_user_font_configuration(false);
            Gtk.init(ref args);
            if (update_declined())
                return 0;
            set_application_style(BUS_PATH);
            ApplicationFlags FLAGS = (ApplicationFlags.HANDLES_OPEN |
                                      ApplicationFlags.HANDLES_COMMAND_LINE);
            return new Application(BUS_ID, FLAGS).run(args);
        }

    }

}
