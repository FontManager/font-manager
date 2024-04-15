using FontManager;

MainLoop loop;
ProgressDialog? dialog = null;

uint font = 0;
uint metadata = 0;
uint orthography = 0;

void quit ()
{
    dialog.destroy();
    loop.quit();
}

void update_progress_dialog (ProgressData data) {
    string message = _("Updating Database…");
    if (data.message == "Fonts")
        font = data.processed;
    else if (data.message == "Metadata")
        metadata = data.processed;
    else if (data.message == "Orthography")
        orthography = data.processed;
    uint processed = font + metadata + orthography;
    var progress = new ProgressData(message, processed / 3, data.total);
    dialog.update(progress);
    return;
}

int main () {
    Gtk.init();
    set_application_style();
    loop = new MainLoop();
    dialog = new ProgressDialog(_("Font Manager")) { show_app_icon = true };
    var db = new DatabaseProxy();
    db.set_progress_callback((data) => {
        data.ref();
        update_progress_dialog(data);
        data.unref();
        return GLib.Source.REMOVE;
    });
    db.update_complete.connect(() => { quit(); });
    var available_fonts = get_available_fonts(null);
    GLib.Source source = new IdleSource();
    source.attach(loop.get_context());
    source.set_callback(() => {
        db.update(available_fonts);
        return GLib.Source.REMOVE;
    });
    dialog.show();
    loop.run();
    return 0;
}


