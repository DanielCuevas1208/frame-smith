namespace FrameSmith {

public class PixbufIO {
    public static Gdk.Pixbuf? load(string path, out string? message) {
        message = null;
        try {
            return new Gdk.Pixbuf.from_file(path);
        } catch (GLib.Error e) {
            message = e.message;
            return null;
        }
    }

    public static Image to_image(Gdk.Pixbuf pixbuf) {
        var image = new Image(pixbuf.width, pixbuf.height);
        int channels = pixbuf.n_channels;
        int stride = pixbuf.rowstride;
        unowned uint8[] source = pixbuf.get_pixels_with_length();
        for (int y = 0; y < image.height; y++)
            for (int x = 0; x < image.width; x++) {
                int s = y * stride + x * channels;
                int d = image.pixel_index(x, y);
                image.pixels[d] = source[s];
                image.pixels[d + 1] = source[s + 1];
                image.pixels[d + 2] = source[s + 2];
                image.pixels[d + 3] = channels >= 4 ? source[s + 3] : (uint8)255;
            }
        return image;
    }

    public static Gdk.Pixbuf from_image(Image image) {
        var pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, image.width, image.height);
        int stride = pixbuf.rowstride;
        unowned uint8[] dest = pixbuf.get_pixels_with_length();
        for (int y = 0; y < image.height; y++)
            for (int x = 0; x < image.width; x++) {
                int s = image.pixel_index(x, y);
                int d = y * stride + x * 4;
                dest[d] = image.pixels[s];
                dest[d + 1] = image.pixels[s + 1];
                dest[d + 2] = image.pixels[s + 2];
                dest[d + 3] = image.pixels[s + 3];
            }
        return pixbuf;
    }
}

}
