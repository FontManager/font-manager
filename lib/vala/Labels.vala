/* Labels.vala
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

/**
 * PlaceHolder:
 *
 * It's intended use is to provide helpful information about an area
 * which is empty and the user may not yet be familiar with.
 */
public class PlaceHolder : Gtk.Box {

    public Gtk.Image image { get; private set; }
    public Gtk.Label label { get; private set; }

    public PlaceHolder (string? str, string? icon) {
        Object(name: "PlaceHolder", opacity: 0.75, expand: true,
               orientation: Gtk.Orientation.VERTICAL,
               valign: Gtk.Align.CENTER, halign: Gtk.Align.CENTER);
        image = new Gtk.Image.from_icon_name(icon, Gtk.IconSize.DIALOG);
        image.set_pixel_size(64);
        image.set("sensitive", false, "opacity", 0.25, "expand", true, null);
        label = new Gtk.Label(str);
        label.set("use-markup", true, "sensitive", false, "expand", true,
                  "wrap", true, "wrap_mode", Pango.WrapMode.WORD,
                  "valign", Gtk.Align.START, "halign", Gtk.Align.FILL,
                  "justify", Gtk.Justification.CENTER, "margin", 24, null);
        pack_start(image, false, false, 6);
        pack_end(label);
    }

    public override void show () {
        image.show();
        label.show();
        base.show();
        return;
    }

}

/**
 * ReactiveLabel:
 *
 * Label which reacts to mouseover and click events.
 * Is actually a #GtkEventBox containing a #GtkLabel since
 * events can not be added to widgets that have no window.
 */
public class ReactiveLabel : Gtk.EventBox {

    /**
     * ReactiveLabel::clicked:
     *
     * Emitted when the label is clicked
     */
    public signal void clicked ();

    /**
     * Reactivelabel:label:
     *
     * The actual #GtkLabel
     */
    public Gtk.Label label { get; private set; }

    public ReactiveLabel (string? str) {
        Object(name: "ReactiveLabel");
        label = new Gtk.Label(str);
        label.opacity = 0.65;
        add(label);
    }

    /**
     * {@inheritDoc}
     */
    public override void show () {
        label.show();
        base.show();
        return;
    }

    /**
     * {@inheritDoc}
     */
    public override bool enter_notify_event (Gdk.EventCrossing event) {
        label.opacity = 0.95;
        return false;
    }

    /**
     * {@inheritDoc}
     */
    public override bool leave_notify_event (Gdk.EventCrossing event) {
        label.opacity = 0.65;
        return false;
    }

    /**
     * {@inheritDoc}
     */
    public override bool button_press_event (Gdk.EventButton event) {
        clicked();
        return false;
    }

}
