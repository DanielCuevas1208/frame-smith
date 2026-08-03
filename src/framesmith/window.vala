namespace FrameSmith {

public class MainWindow : Gtk.ApplicationWindow {
    private Image? source_image;
    private FilterChain chain;
    private ChainHistory history;
    private Gtk.Image preview_view;
    private Gtk.ScrolledWindow preview_scroller;
    private Gtk.Stack preview_stack;
    private Gtk.ListBox filter_list;
    private Gtk.Box params_box;
    private Gtk.ComboBoxText filter_chooser;
    private Gtk.Button undo_button;
    private Gtk.Button redo_button;
    private HistogramWidget histogram_widget;
    private Gtk.Statusbar statusbar;
    private uint status_context;
    private uint status_message_id;
    private uint preview_timer;
    private int selected_index = -1;

    public MainWindow(Gtk.Application app) {
        Object(application: app,
               title: "Frame Smith",
               default_width: 1000,
               default_height: 700);
    }

    construct {
        chain = new FilterChain();
        history = new ChainHistory();

        var header = new Gtk.HeaderBar();
        header.title = "Frame Smith";
        header.subtitle = "Convolution image lab";
        header.show_close_button = true;

        var open_button = new Gtk.Button.from_icon_name("document-open", Gtk.IconSize.LARGE_TOOLBAR);
        open_button.tooltip_text = "Open an image";
        open_button.clicked.connect(on_open_clicked);
        header.pack_start(open_button);

        var save_button = new Gtk.Button.from_icon_name("document-save-as", Gtk.IconSize.LARGE_TOOLBAR);
        save_button.tooltip_text = "Save the result";
        save_button.clicked.connect(on_save_clicked);
        header.pack_start(save_button);

        undo_button = new Gtk.Button.from_icon_name("edit-undo", Gtk.IconSize.LARGE_TOOLBAR);
        undo_button.tooltip_text = "Undo the last change";
        undo_button.clicked.connect(on_undo_clicked);
        header.pack_start(undo_button);

        redo_button = new Gtk.Button.from_icon_name("edit-redo", Gtk.IconSize.LARGE_TOOLBAR);
        redo_button.tooltip_text = "Redo the undone change";
        redo_button.clicked.connect(on_redo_clicked);
        header.pack_start(redo_button);
        set_titlebar(header);

        var accel_group = new Gtk.AccelGroup();
        add_accel_group(accel_group);
        undo_button.add_accelerator("clicked", accel_group, Gdk.Key.z,
                                    Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        redo_button.add_accelerator("clicked", accel_group, Gdk.Key.z,
                                    Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK,
                                    Gtk.AccelFlags.VISIBLE);
        update_history_buttons();

        var placeholder = new Gtk.Label("Open an image to start.");
        placeholder.set_vexpand(true);

        preview_view = new Gtk.Image();
        preview_scroller = new Gtk.ScrolledWindow(null, null);
        preview_scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        preview_scroller.add(preview_view);

        preview_stack = new Gtk.Stack();
        preview_stack.add_named(placeholder, "placeholder");
        preview_stack.add_named(preview_scroller, "preview");
        preview_stack.set_visible_child_name("placeholder");

        var right_panel = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        right_panel.set_size_request(320, -1);
        right_panel.margin_start = 8;
        right_panel.margin_end = 8;
        right_panel.margin_top = 8;
        right_panel.margin_bottom = 8;

        histogram_widget = new HistogramWidget();
        histogram_widget.set_size_request(-1, 120);
        var histogram_frame = new Gtk.Frame("Histogram");
        histogram_frame.add(histogram_widget);
        right_panel.pack_start(histogram_frame, false, false, 0);

        filter_chooser = new Gtk.ComboBoxText();
        foreach (string id in FilterFactory.available_ids())
            filter_chooser.append(id, FilterFactory.display_name(id));
        filter_chooser.active = 0;

        var add_button = new Gtk.Button.with_label("Add");
        add_button.clicked.connect(on_add_filter_clicked);

        var add_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        add_row.pack_start(filter_chooser, true, true, 0);
        add_row.pack_start(add_button, false, false, 0);

        filter_list = new Gtk.ListBox();
        filter_list.set_selection_mode(Gtk.SelectionMode.SINGLE);
        filter_list.row_selected.connect(on_row_selected);

        var list_scroller = new Gtk.ScrolledWindow(null, null);
        list_scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        list_scroller.set_min_content_height(150);
        list_scroller.add(filter_list);

        var up_button = new Gtk.Button.with_label("Up");
        up_button.clicked.connect(() => on_move_filter(-1));

        var down_button = new Gtk.Button.with_label("Down");
        down_button.clicked.connect(() => on_move_filter(1));

        var remove_button = new Gtk.Button.with_label("Remove");
        remove_button.clicked.connect(on_remove_filter_clicked);

        var move_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        move_row.pack_start(up_button, true, true, 0);
        move_row.pack_start(down_button, true, true, 0);
        move_row.pack_start(remove_button, true, true, 0);

        var chain_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        chain_box.pack_start(add_row, false, false, 0);
        chain_box.pack_start(list_scroller, true, true, 0);
        chain_box.pack_start(move_row, false, false, 0);

        var chain_frame = new Gtk.Frame("Filter chain");
        chain_frame.add(chain_box);
        right_panel.pack_start(chain_frame, true, true, 0);

        params_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        params_box.margin_start = 8;
        params_box.margin_end = 8;
        params_box.margin_top = 8;
        params_box.margin_bottom = 8;

        var params_scroller = new Gtk.ScrolledWindow(null, null);
        params_scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        params_scroller.set_max_content_height(180);
        params_scroller.add(params_box);

        var params_frame = new Gtk.Frame("Parameters");
        params_frame.add(params_scroller);
        right_panel.pack_start(params_frame, false, false, 0);

        var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
        paned.pack1(preview_stack, true, false);
        paned.pack2(right_panel, false, false);
        paned.position = 700;

        statusbar = new Gtk.Statusbar();
        status_context = statusbar.get_context_id("main");
        set_status("Open an image to start.");

        var layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        layout.pack_start(paned, true, true, 0);
        layout.pack_start(statusbar, false, false, 0);
        add(layout);
    }

    public void open_file(string path) {
        string? message;
        var pixbuf = PixbufIO.load(path, out message);
        if (pixbuf == null) {
            set_status("Could not open %s: %s".printf(Path.get_basename(path), message ?? "unknown error"));
            return;
        }
        var image = PixbufIO.to_image(pixbuf);
        source_image = image;
        chain.clear();
        history.clear();
        update_history_buttons();
        selected_index = -1;
        refresh_filter_list();
        preview_stack.set_visible_child_name("preview");
        set_status("Loaded %s (%d x %d)".printf(Path.get_basename(path), image.width, image.height));
        queue_preview();
    }

    private void on_open_clicked() {
        var dialog = new Gtk.FileChooserNative("Open image", this, Gtk.FileChooserAction.OPEN, "Open", "Cancel");
        var images = new Gtk.FileFilter();
        images.set_name("Images");
        images.add_pixbuf_formats();
        dialog.add_filter(images);
        var all = new Gtk.FileFilter();
        all.set_name("All files");
        all.add_pattern("*");
        dialog.add_filter(all);
        if (dialog.run() == Gtk.ResponseType.ACCEPT) {
            string? path = dialog.get_filename();
            if (path != null)
                open_file(path);
        }
        dialog.destroy();
    }

    private void on_save_clicked() {
        var source = source_image;
        if (source == null) {
            set_status("Open an image before saving.");
            return;
        }
        var dialog = new Gtk.FileChooserNative("Save image", this, Gtk.FileChooserAction.SAVE, "Save", "Cancel");
        dialog.set_do_overwrite_confirmation(true);

        var png = new Gtk.FileFilter();
        png.set_name("PNG image");
        png.add_mime_type("image/png");
        dialog.add_filter(png);

        var jpeg = new Gtk.FileFilter();
        jpeg.set_name("JPEG image");
        jpeg.add_mime_type("image/jpeg");
        dialog.add_filter(jpeg);

        dialog.set_current_name("output.png");
        if (dialog.run() != Gtk.ResponseType.ACCEPT) {
            dialog.destroy();
            return;
        }
        string? path = dialog.get_filename();
        dialog.destroy();
        if (path == null)
            return;

        var result = chain.apply(source);
        var out_pixbuf = PixbufIO.from_image(result);
        string format = guess_format(path);
        try {
            out_pixbuf.save(path, format);
        } catch (GLib.Error e) {
            set_status("Save failed: %s".printf(e.message));
            return;
        }
        set_status("Saved to %s".printf(Path.get_basename(path)));
    }

    private string guess_format(string path) {
        string lower = path.down();
        if (lower.has_suffix(".jpg") || lower.has_suffix(".jpeg"))
            return "jpeg";
        if (lower.has_suffix(".bmp"))
            return "bmp";
        if (lower.has_suffix(".tiff") || lower.has_suffix(".tif"))
            return "tiff";
        return "png";
    }

    private void on_add_filter_clicked() {
        string? id = filter_chooser.get_active_id();
        if (id == null)
            return;
        var filter = FilterFactory.create(id);
        if (filter == null)
            return;
        history.push(chain);
        chain.add(filter);
        selected_index = chain.size - 1;
        refresh_filter_list();
        update_history_buttons();
        queue_preview();
    }

    private void on_remove_filter_clicked() {
        if (selected_index < 0)
            return;
        history.push(chain);
        chain.remove_at(selected_index);
        if (selected_index >= chain.size)
            selected_index = chain.size - 1;
        refresh_filter_list();
        update_history_buttons();
        queue_preview();
    }

    private void on_move_filter(int delta) {
        if (selected_index < 0)
            return;
        int target = selected_index + delta;
        if (target < 0 || target >= chain.size)
            return;
        history.push(chain);
        chain.move(selected_index, target);
        selected_index = target;
        refresh_filter_list();
        update_history_buttons();
        queue_preview();
    }

    private void on_undo_clicked() {
        var restored = history.undo(chain);
        if (restored == null)
            return;
        chain = restored;
        selected_index = -1;
        refresh_filter_list();
        update_history_buttons();
        queue_preview();
    }

    private void on_redo_clicked() {
        var restored = history.redo(chain);
        if (restored == null)
            return;
        chain = restored;
        selected_index = -1;
        refresh_filter_list();
        update_history_buttons();
        queue_preview();
    }

    private void update_history_buttons() {
        undo_button.sensitive = history.can_undo;
        redo_button.sensitive = history.can_redo;
    }

    private void on_row_selected(Gtk.ListBox? box, Gtk.ListBoxRow? row) {
        selected_index = row != null ? row.get_index() : -1;
        rebuild_params();
    }

    private void refresh_filter_list() {
        var children = filter_list.get_children();
        foreach (var child in children)
            filter_list.remove(child);

        for (int i = 0; i < chain.size; i++) {
            var filter = chain.get(i);
            if (filter == null)
                continue;
            var label = new Gtk.Label(filter.describe());
            label.set_xalign(0.0f);
            label.margin_start = 8;
            label.margin_top = 6;
            label.margin_bottom = 6;
            filter_list.add(label);
        }

        if (chain.size == 0) {
            selected_index = -1;
            rebuild_params();
            return;
        }
        if (selected_index < 0)
            selected_index = 0;
        if (selected_index >= chain.size)
            selected_index = chain.size - 1;

        var row = filter_list.get_row_at_index(selected_index);
        if (row != null)
            filter_list.select_row(row);
    }

    private void rebuild_params() {
        var children = params_box.get_children();
        foreach (var child in children)
            params_box.remove(child);

        var filter = selected_index >= 0 ? chain.get(selected_index) : null;
        if (filter == null) {
            var hint = new Gtk.Label("Select a filter to edit its parameters.");
            hint.set_xalign(0.0f);
            params_box.pack_start(hint, false, false, 0);
            params_box.show_all();
            return;
        }

        for (int i = 0; i < filter.param_count; i++) {
            var param = filter.get_param(i);
            if (param == null)
                continue;
            if (param.step == 1.0 && param.minimum == 0.0 && param.maximum == 1.0) {
                var toggle = new Gtk.CheckButton.with_label(param.label);
                toggle.active = param.value >= 0.5;
                toggle.toggled.connect(() => {
                    double new_value = toggle.active ? 1.0 : 0.0;
                    if (new_value != param.value) {
                        history.push(chain);
                        update_history_buttons();
                    }
                    param.value = new_value;
                    queue_preview();
                });
                params_box.pack_start(toggle, false, false, 0);
            } else {
                var label = new Gtk.Label(param.label);
                label.set_xalign(0.0f);
                label.set_size_request(90, -1);

                var adjustment = new Gtk.Adjustment(param.value, param.minimum, param.maximum,
                                                    param.step, param.step, 0.0);
                var scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, adjustment);
                scale.set_hexpand(true);
                scale.draw_value = true;
                scale.button_press_event.connect((event) => {
                    history.push(chain);
                    update_history_buttons();
                    return false;
                });
                scale.scroll_event.connect((event) => {
                    history.push(chain);
                    update_history_buttons();
                    return false;
                });
                scale.key_press_event.connect((event) => {
                    switch (event.keyval) {
                        case Gdk.Key.Up:
                        case Gdk.Key.Down:
                        case Gdk.Key.Left:
                        case Gdk.Key.Right:
                        case Gdk.Key.Page_Up:
                        case Gdk.Key.Page_Down:
                        case Gdk.Key.Home:
                        case Gdk.Key.End:
                            history.push(chain);
                            update_history_buttons();
                            break;
                        default:
                            break;
                    }
                    return false;
                });
                scale.value_changed.connect(() => {
                    param.value = adjustment.get_value();
                    queue_preview();
                });

                var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
                row.pack_start(label, false, false, 0);
                row.pack_start(scale, true, true, 0);
                params_box.pack_start(row, false, false, 0);
            }
        }
        params_box.show_all();
    }

    private void queue_preview() {
        if (preview_timer != 0)
            Source.remove(preview_timer);
        preview_timer = Timeout.add(120, () => {
            render_preview();
            return false;
        });
    }

    private void render_preview() {
        preview_timer = 0;
        var source = source_image;
        if (source == null)
            return;
        var result = chain.apply(source);
        preview_view.pixbuf = PixbufIO.from_image(result);
        histogram_widget.set_histogram(Histogram.from_image(result));
    }

    private void set_status(string text) {
        if (status_message_id != 0)
            statusbar.remove(status_context, status_message_id);
        status_message_id = statusbar.push(status_context, text);
    }
}

}
