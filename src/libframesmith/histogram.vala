namespace FrameSmith {

public class Histogram {
    public int[] r;
    public int[] g;
    public int[] b;

    public Histogram() {
        r = new int[256];
        g = new int[256];
        b = new int[256];
    }

    public static Histogram from_image(Image image) {
        var histogram = new Histogram();
        for (int i = 0; i < image.pixels.length; i += 4) {
            histogram.r[(int)image.pixels[i]]++;
            histogram.g[(int)image.pixels[i + 1]]++;
            histogram.b[(int)image.pixels[i + 2]]++;
        }
        return histogram;
    }

    public int max_count() {
        int max = 0;
        for (int i = 0; i < 256; i++) {
            if (r[i] > max) max = r[i];
            if (g[i] > max) max = g[i];
            if (b[i] > max) max = b[i];
        }
        return max;
    }
}

}
