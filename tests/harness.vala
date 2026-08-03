namespace FrameSmith.Tests {

public delegate void TestFunction(Runner runner) throws GLib.Error;

public class Runner {
    public string suite_name { get; private set; }
    private int passed;
    private int failed;
    private GLib.Quark quark;

    public Runner(string suite_name) {
        this.suite_name = suite_name;
        quark = GLib.Quark.from_string("framesmith-test");
    }

    public void run(string name, TestFunction test) {
        try {
            test(this);
            passed++;
            stdout.printf("ok   %s\n", name);
        } catch (GLib.Error e) {
            failed++;
            stderr.printf("FAIL %s: %s\n", name, e.message);
        }
    }

    public void check(bool condition, string message) throws GLib.Error {
        if (!condition)
            throw new GLib.Error(quark, 1, "%s", message);
    }

    public void check_eq_int(int actual, int expected, string message) throws GLib.Error {
        if (actual != expected)
            throw new GLib.Error(quark, 1, "%s: expected %d, got %d", message, expected, actual);
    }

    public void check_close(double actual, double expected, double tolerance, string message) throws GLib.Error {
        if (Math.fabs(actual - expected) > tolerance)
            throw new GLib.Error(quark, 1, "%s: expected %g +/- %g, got %g",
                                 message, expected, tolerance, actual);
    }

    public void check_pixel(Image image, int x, int y, uint8 r, uint8 g, uint8 b, string message) throws GLib.Error {
        int idx = image.pixel_index(x, y);
        if (image.pixels[idx] != r || image.pixels[idx + 1] != g || image.pixels[idx + 2] != b)
            throw new GLib.Error(quark, 1,
                "%s: pixel (%d,%d) = (%d,%d,%d), expected (%d,%d,%d)",
                message, x, y,
                (int)image.pixels[idx], (int)image.pixels[idx + 1], (int)image.pixels[idx + 2],
                (int)r, (int)g, (int)b);
    }

    public void check_images_equal(Image a, Image b, string message) throws GLib.Error {
        if (a.width != b.width || a.height != b.height)
            throw new GLib.Error(quark, 1, "%s: size mismatch %dx%d vs %dx%d",
                                 message, a.width, b.width, a.height, b.height);
        for (int i = 0; i < a.pixels.length; i++)
            if (a.pixels[i] != b.pixels[i])
                throw new GLib.Error(quark, 1, "%s: pixels differ at index %d", message, i);
    }

    public int finish() {
        stdout.printf("%s: %d passed, %d failed\n", suite_name, passed, failed);
        return failed == 0 ? 0 : 1;
    }
}

}
