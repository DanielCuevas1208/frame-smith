namespace FrameSmith {

public class HistogramWidget : Gtk.DrawingArea {
    private Histogram? histogram;
    private int max_count = 1;

    public HistogramWidget() {
        set_hexpand(true);
        set_size_request(0, 120);
        draw.connect(on_draw);
    }

    public void set_histogram(Histogram histogram) {
        this.histogram = histogram;
        max_count = histogram.max_count();
        if (max_count < 1)
            max_count = 1;
        queue_draw();
    }

    private bool on_draw(Cairo.Context cr) {
        int height = get_allocated_height();

        cr.set_source_rgb(0.16, 0.17, 0.19);
        cr.paint();

        var histogram = this.histogram;
        if (histogram == null) {
            cr.set_source_rgb(0.72, 0.74, 0.78);
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            cr.set_font_size(12.0);
            cr.move_to(12.0, 18.0);
            cr.show_text("Open an image to show its histogram.");
            return true;
        }

        int band_height = (height - 8) / 3;
        if (band_height < 8)
            band_height = 8;
        draw_band(cr, histogram.r, 4, band_height, 0.92, 0.30, 0.30);
        draw_band(cr, histogram.g, 4 + band_height, band_height, 0.28, 0.82, 0.32);
        draw_band(cr, histogram.b, 4 + 2 * band_height, band_height, 0.30, 0.48, 0.95);
        return true;
    }

    private void draw_band(Cairo.Context cr, int[] counts, int y, int band_height,
                           double r, double g, double b) {
        int width = get_allocated_width();
        if (width < 4)
            return;
        double slot = (double)width / 256.0;
        cr.set_source_rgb(r, g, b);
        for (int i = 0; i < 256; i++) {
            double bar_height = (double)counts[i] / max_count * band_height;
            cr.rectangle(i * slot, y + band_height - bar_height, slot, bar_height);
        }
        cr.fill();
    }
}

}
