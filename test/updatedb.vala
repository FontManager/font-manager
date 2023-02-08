using FontManager;

MainLoop loop;
Gtk.MessageDialog dialog;

uint font = 0;
uint metadata = 0;
uint orthography = 0;

void quit ()
{
    dialog.destroy();
    loop.quit();
}

void update_progress_dialog (ProgressData data) {
    if (data.message == "Fonts")
        font = data.processed;
    else if (data.message == "Metadata")
        metadata = data.processed;
    else if (data.message == "Orthography")
        orthography = data.processed;
    var progress = new ProgressData("Updating font database…",
                                    font + metadata + orthography,
                                    data.total * 3);
    ProgressDialog.update(dialog, progress);
    return;
}

int main () {
    Gtk.init();
    loop = new MainLoop();
    dialog = ProgressDialog.create(null, "Font Manager");
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

