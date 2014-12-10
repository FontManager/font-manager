/* Logger.vala
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

namespace Logging {

    public void setup (LogLevel level = LogLevel.WARN) {
        Logger.initialize(FontManager.About.NAME);
        Logger.DisplayLevel = level;
        return;
    }

    public void show_version_information () {
        message("%s %s", FontManager.About.NAME, FontManager.About.VERSION);
        message("Using GLib %u.%u.%u", Version.major, Version.minor, Version.micro);
        message("Using JSON-GLib %s", Json.VERSION_S);
        message("Using SQLite %s", Sqlite.VERSION);
        message("Using FontConfig %s", FontConfig.get_version_string());
        message("Using Pango %s", Pango.version_string());
        message("Using GTK+ %i.%i.%i", Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION);
        if (Gnome3())
            message("Running on %s", get_command_line_output("gnome-shell --version"));
        else
            message("Running on %s", Environment.get_variable("XDG_CURRENT_DESKTOP"));
        return;
    }

}

/* From libplank, namespace modified, "using" declarations removed. */

//
//  Copyright (C) 2011 Robert Dyer
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

/**
 * Controls what messages show in the console log.
 */
public enum LogLevel {
    /**
     * Extra debugging info. A *LOT* of messages.
     */
    VERBOSE,
    /**
     * Debugging messages that help track what the application is doing.
     */
    DEBUG,
    /**
     * General information messages. Similar to debug but perhaps useful to non-debug users.
     */
    INFO,
    /**
     * Messages that also show a libnotify message.
     */
    NOTIFY,
    /**
     * Any messsage that is a warning.
     */
    WARN,
    /**
     * Any message considered an error.  These can be recovered from but might make the application function abnormally.
     */
    ERROR,
    /**
     * Any message considered fatal.  These generally break the application.
     */
    FATAL;

    public string to_string () {
        switch (this) {
            case DEBUG:
                return "DEBUG";
            case WARN:
                return "WARNING";
            case ERROR:
                return "ERROR";
            case FATAL:
                return "FATAL";
            default:
                return "INFO";
        }
    }
}

enum ConsoleColor
{
    BLACK,
    RED,
    GREEN,
    YELLOW,
    BLUE,
    MAGENTA,
    CYAN,
    WHITE,
}

/**
 * A logging class to display all console messages in a nice colored format.
 */
public class Logger : GLib.Object
{
    class LogMessage : GLib.Object {

        public LogLevel level { get; construct; }
        public string message { get; construct; }

        public LogMessage (LogLevel level, string message) {
            GLib.Object (level : level, message : message);
        }
    }

    /**
     * The current log level.  Controls what log messages actually appear on the console.
     */
    public static LogLevel DisplayLevel { get; set; default = LogLevel.WARN; }

    static string name { get; set; }

    static Object? queue_lock = null;

    static Gee.ArrayList <LogMessage> log_queue;
    static bool is_writing;

    static Regex? re = null;

    /**
     * Initializes the logger for the application.
     *
     * @param app_name the name of the application
     */
    public static void initialize (string app_name) {
        name = app_name;
        is_writing = false;
        log_queue = new Gee.ArrayList <LogMessage> ();
        try {
            re = new Regex("""[(]?.*?([^/]*?)(\.2)?\.vala(:\d+)[)]?:\s*(.*)""");
        } catch { }

        Log.set_default_handler (glib_log_func);
    }

    static string format_message (string msg) {
        if (re != null && re.match(msg)) {
            var parts = re.split(msg);
            if (DisplayLevel <= LogLevel.DEBUG)
                return "[%s%s] %s".printf (parts[1], parts[3], parts[4]);
            else
                return "%s".printf (parts[4]);
        }
        return msg;
    }

    /**
     * Displays a log message using libnotify.  Also displays on the console.
     *
     * @param msg the log message to display
     * @param icon the icon to display in the notification
     */
    public static void notification (string msg, string icon = "") {
        // TODO display the message using libnotify
        write(LogLevel.NOTIFY, format_message (msg));
    }

    /**
     * Displays a verbose log message to the console.
     *
     * @param msg the log message to display
     */
    public static void verbose (string msg, ...) {
        // NOTE using a local var is needed for valac 0.12/0.14 to avoid invalid c-code
        var vargs = va_list ();
        write(LogLevel.VERBOSE, format_message (msg.vprintf (vargs)));
    }

    static string get_time () {
        var now = new DateTime.now_local ();
        return "%.2d:%.2d:%.2d".printf(now.get_hour (), now.get_minute (), now.get_second ());
    }

    static void write (LogLevel level, string msg) {
        if (level < DisplayLevel)
            return;

        if (is_writing) {
            lock(queue_lock)
                log_queue.add(new LogMessage (level, msg));
        } else {
            is_writing = true;

            if (log_queue.size > 0) {
                var logs = log_queue;
                lock(queue_lock)
                    log_queue = new Gee.ArrayList <LogMessage> ();

                foreach(var log in logs)
                    print_log(log);
            }

            print_log(new LogMessage (level, msg));
            is_writing = false;
        }
    }

    static void print_log (LogMessage log) {
        set_color_for_level(log.level);
        stdout.printf("[%s %s]", log.level.to_string (), get_time ());
        reset_color();
        stdout.printf(" %s\n", log.message);
    }

    static void set_color_for_level (LogLevel level) {
        switch (level) {
            case LogLevel.VERBOSE:
                set_foreground (ConsoleColor.CYAN);
                break;
            case LogLevel.DEBUG:
                set_foreground (ConsoleColor.GREEN);
                break;
            case LogLevel.INFO:
                set_foreground (ConsoleColor.BLUE);
                break;
            case LogLevel.NOTIFY:
                set_foreground (ConsoleColor.MAGENTA);
                break;
            case LogLevel.WARN:
            default:
                set_foreground (ConsoleColor.YELLOW);
                break;
            case LogLevel.ERROR:
                set_foreground (ConsoleColor.RED);
                break;
            case LogLevel.FATAL:
                set_background (ConsoleColor.RED);
                set_foreground (ConsoleColor.WHITE);
                break;
        }
    }

    static void reset_color () {
        stdout.printf ("\x001b[0m");
    }

    static void set_foreground (ConsoleColor color) {
        set_color (color, true);
    }

    static void set_background (ConsoleColor color) {
        set_color (color, false);
    }

    static void set_color (ConsoleColor color, bool isForeground) {
        var color_code = color + 30 + 60;
        if (!isForeground)
            color_code += 10;
        stdout.printf ("\x001b[%dm", color_code);
    }

    static void glib_log_func (string? d, LogLevelFlags flags, string msg) {
        var domain = "";
        if (d != null)
            domain = "[%s] ".printf(d ?? "");

        var message = msg.replace("\n", "").replace("\r", "");
        message = "%s%s".printf(domain, message);

        switch (flags) {
            case LogLevelFlags.LEVEL_CRITICAL:
                write(LogLevel.FATAL, format_message(message));
                write(LogLevel.FATAL, format_message("%s will not function properly.".printf(name)));
                break;

            case LogLevelFlags.LEVEL_ERROR:
                write(LogLevel.ERROR, format_message(message));
                break;

            case LogLevelFlags.LEVEL_INFO:
            case LogLevelFlags.LEVEL_MESSAGE:
                write(LogLevel.INFO, format_message(message));
                break;

            case LogLevelFlags.LEVEL_DEBUG:
                write (LogLevel.DEBUG, format_message(message));
                break;

            case LogLevelFlags.LEVEL_WARNING:
            default:
                write(LogLevel.WARN, format_message(message));
                break;
        }
    }
}
