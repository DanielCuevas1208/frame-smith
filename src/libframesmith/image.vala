namespace FrameSmith {

public class Image {
    public int width { get; private set; }
    public int height { get; private set; }
    public uint8[] pixels { get; private set; }

    public Image(int width, int height) {
        this.width = width;
        this.height = height;
        pixels = new uint8[width * height * 4];
    }

    public int pixel_index(int x, int y) {
        return (y * width + x) * 4;
    }

    public void fill_rgba(uint8 r, uint8 g, uint8 b, uint8 a) {
        for (int i = 0; i < pixels.length; i += 4) {
            pixels[i] = r;
            pixels[i + 1] = g;
            pixels[i + 2] = b;
            pixels[i + 3] = a;
        }
    }

    public Image copy() {
        var result = new Image(width, height);
        for (int i = 0; i < pixels.length; i++)
            result.pixels[i] = pixels[i];
        return result;
    }
}

}
