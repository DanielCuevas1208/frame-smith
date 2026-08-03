using FrameSmith;
using FrameSmith.Tests;

int main(string[] args) {
    var runner = new Runner("core");
    runner.run("identity kernel preserves pixels", test_identity_kernel);
    runner.run("gaussian blur keeps constant image", test_blur_constant);
    runner.run("gaussian blur spreads an impulse", test_blur_impulse);
    runner.run("sharpen keeps constant image", test_sharpen_constant);
    runner.run("sharpen amplifies contrast", test_sharpen_impulse);
    runner.run("edge finds a step edge", test_edge_step);
    runner.run("edge ignores flat regions", test_edge_flat);
    runner.run("threshold splits luminance", test_threshold);
    runner.run("threshold invert", test_threshold_invert);
    runner.run("levels remap and clamp", test_levels);
    runner.run("levels gamma", test_levels_gamma);
    runner.run("histogram counts channels", test_histogram);
    runner.run("chain applies in order", test_chain_order);
    runner.run("chain move reorders", test_chain_move);
    runner.run("empty chain is a copy", test_chain_empty);
    return runner.finish();
}

private Image make_gradient(int width, int height) {
    var image = new Image(width, height);
    for (int y = 0; y < height; y++)
        for (int x = 0; x < width; x++) {
            int idx = image.pixel_index(x, y);
            image.pixels[idx] = (uint8)((x * 7 + y * 3) % 256);
            image.pixels[idx + 1] = (uint8)((x * 3 + y * 11) % 256);
            image.pixels[idx + 2] = (uint8)((x * 13 + y) % 256);
            image.pixels[idx + 3] = 255;
        }
    return image;
}

private void test_identity_kernel(Runner runner) throws GLib.Error {
    var image = make_gradient(9, 9);
    var result = Convolution.apply(image, Kernel.identity());
    runner.check_images_equal(image, result, "identity kernel must not change pixels");
}

private void test_blur_constant(Runner runner) throws GLib.Error {
    var image = new Image(7, 7);
    image.fill_rgba(200, 120, 40, 255);
    var result = new BlurFilter().apply(image);
    runner.check_images_equal(image, result, "blur must keep a constant image");
}

private void test_blur_impulse(Runner runner) throws GLib.Error {
    var image = new Image(5, 5);
    image.fill_rgba(0, 0, 0, 255);
    int center = image.pixel_index(2, 2);
    image.pixels[center] = 255;
    image.pixels[center + 1] = 255;
    image.pixels[center + 2] = 255;

    var blur = new BlurFilter();
    blur.set_value("radius", 1.0);
    var result = blur.apply(image);

    runner.check_close(result.pixels[result.pixel_index(2, 2)], 158.0, 1.0, "impulse center");
    runner.check_close(result.pixels[result.pixel_index(3, 2)], 21.0, 1.0, "impulse neighbor");
    runner.check_close(result.pixels[result.pixel_index(0, 0)], 0.0, 1.0, "impulse far corner");
}

private void test_sharpen_constant(Runner runner) throws GLib.Error {
    var image = new Image(8, 8);
    image.fill_rgba(100, 150, 200, 255);
    var result = new SharpenFilter().apply(image);
    runner.check_images_equal(image, result, "sharpen must keep a constant image");
}

private void test_sharpen_impulse(Runner runner) throws GLib.Error {
    var image = new Image(5, 5);
    image.fill_rgba(0, 0, 0, 255);
    int center = image.pixel_index(2, 2);
    image.pixels[center] = 200;
    image.pixels[center + 1] = 200;
    image.pixels[center + 2] = 200;

    var sharpen = new SharpenFilter();
    sharpen.set_value("amount", 1.0);
    sharpen.set_value("radius", 1.0);
    var result = sharpen.apply(image);

    runner.check_close(result.pixels[result.pixel_index(2, 2)], 255.0, 1.0, "sharpen amplifies the impulse");
    runner.check_eq_int((int)result.pixels[result.pixel_index(0, 0)], 0, "sharpen leaves background dark");
}

private void test_edge_step(Runner runner) throws GLib.Error {
    var image = new Image(5, 5);
    image.fill_rgba(0, 0, 0, 255);
    for (int y = 0; y < 2; y++)
        for (int x = 0; x < 5; x++) {
            int idx = image.pixel_index(x, y);
            image.pixels[idx] = 255;
            image.pixels[idx + 1] = 255;
            image.pixels[idx + 2] = 255;
        }

    var result = new EdgeFilter().apply(image);
    runner.check_eq_int((int)result.pixels[result.pixel_index(2, 0)], 0, "flat white row stays black");
    runner.check_eq_int((int)result.pixels[result.pixel_index(2, 1)], 255, "upper edge row is white");
    runner.check_eq_int((int)result.pixels[result.pixel_index(2, 2)], 255, "lower edge row is white");
    runner.check_eq_int((int)result.pixels[result.pixel_index(2, 3)], 0, "flat black row stays black");
}

private void test_edge_flat(Runner runner) throws GLib.Error {
    var image = new Image(6, 6);
    image.fill_rgba(80, 90, 100, 255);
    var result = new EdgeFilter().apply(image);
    for (int i = 0; i < result.pixels.length; i += 4)
        runner.check_eq_int((int)result.pixels[i], 0, "flat image must be black");
}

private void test_threshold(Runner runner) throws GLib.Error {
    uint8[] values = { (uint8)0, (uint8)100, (uint8)127, (uint8)129, (uint8)200, (uint8)255 };
    var image = new Image(1, values.length);
    for (int y = 0; y < values.length; y++) {
        int idx = image.pixel_index(0, y);
        image.pixels[idx] = values[y];
        image.pixels[idx + 1] = values[y];
        image.pixels[idx + 2] = values[y];
        image.pixels[idx + 3] = 255;
    }

    var threshold = new ThresholdFilter();
    threshold.set_value("threshold", 128.0);
    var result = threshold.apply(image);

    for (int y = 0; y < values.length; y++) {
        uint8 expected = values[y] < 128 ? (uint8)0 : (uint8)255;
        runner.check_eq_int((int)result.pixels[result.pixel_index(0, y)], expected,
                            "threshold row %d".printf(y));
    }
}

private void test_threshold_invert(Runner runner) throws GLib.Error {
    var image = new Image(1, 2);
    int bright = image.pixel_index(0, 0);
    image.pixels[bright] = 200;
    image.pixels[bright + 1] = 200;
    image.pixels[bright + 2] = 200;
    int dark = image.pixel_index(0, 1);
    image.pixels[dark] = 50;
    image.pixels[dark + 1] = 50;
    image.pixels[dark + 2] = 50;

    var threshold = new ThresholdFilter();
    threshold.set_value("threshold", 100.0);
    threshold.set_value("invert", 1.0);
    var result = threshold.apply(image);

    runner.check_eq_int((int)result.pixels[result.pixel_index(0, 0)], 0, "bright pixel inverts to black");
    runner.check_eq_int((int)result.pixels[result.pixel_index(0, 1)], 255, "dark pixel inverts to white");
}

private void test_levels(Runner runner) throws GLib.Error {
    var image = new Image(1, 1);
    int idx = image.pixel_index(0, 0);
    image.pixels[idx] = 50;
    image.pixels[idx + 1] = 50;
    image.pixels[idx + 2] = 50;
    image.pixels[idx + 3] = 255;

    var levels = new LevelsFilter();
    levels.set_value("black", 0.0);
    levels.set_value("white", 100.0);
    levels.set_value("gamma", 1.0);
    var result = levels.apply(image);
    runner.check_eq_int((int)result.pixels[result.pixel_index(0, 0)], 128, "half of range maps to 128");

    levels.set_value("black", 100.0);
    levels.set_value("white", 200.0);
    result = levels.apply(image);
    runner.check_eq_int((int)result.pixels[result.pixel_index(0, 0)], 0, "below black clamps to 0");
}

private void test_levels_gamma(Runner runner) throws GLib.Error {
    var image = new Image(1, 1);
    int idx = image.pixel_index(0, 0);
    image.pixels[idx] = 50;
    image.pixels[idx + 1] = 50;
    image.pixels[idx + 2] = 50;
    image.pixels[idx + 3] = 255;

    var levels = new LevelsFilter();
    levels.set_value("black", 0.0);
    levels.set_value("white", 255.0);
    levels.set_value("gamma", 2.0);
    var result = levels.apply(image);
    runner.check_close(result.pixels[result.pixel_index(0, 0)], 113.0, 1.0, "gamma lifts midtones");
}

private void test_histogram(Runner runner) throws GLib.Error {
    var image = new Image(2, 2);
    image.fill_rgba(0, 0, 0, 255);
    int p0 = image.pixel_index(0, 0);
    image.pixels[p0] = 255;
    int p1 = image.pixel_index(1, 0);
    image.pixels[p1 + 1] = 255;
    int p2 = image.pixel_index(0, 1);
    image.pixels[p2 + 2] = 255;

    var histogram = Histogram.from_image(image);
    runner.check_eq_int(histogram.r[255], 1, "red count");
    runner.check_eq_int(histogram.g[255], 1, "green count");
    runner.check_eq_int(histogram.b[255], 1, "blue count");
    runner.check_eq_int(histogram.r[0], 3, "red zero count");
    runner.check_eq_int(histogram.g[0], 3, "green zero count");
    runner.check_eq_int(histogram.b[0], 3, "blue zero count");
    runner.check_eq_int(histogram.max_count(), 3, "max count");
}

private void test_chain_order(Runner runner) throws GLib.Error {
    var image = make_gradient(12, 12);
    var blur = new BlurFilter();
    blur.set_value("radius", 1.5);
    var threshold = new ThresholdFilter();
    threshold.set_value("threshold", 120.0);

    var chain = new FilterChain();
    chain.add(blur);
    chain.add(threshold);
    var result = chain.apply(image);

    var manual = threshold.apply(blur.apply(image));
    runner.check_images_equal(result, manual, "chain order matches manual application");

    chain.move(1, 0);
    var reordered = chain.apply(image);
    bool differs = false;
    for (int i = 0; i < result.pixels.length; i++)
        if (result.pixels[i] != reordered.pixels[i]) {
            differs = true;
            break;
        }
    runner.check(differs, "reordering must change the output");
}

private void test_chain_move(Runner runner) throws GLib.Error {
    var image = make_gradient(10, 10);
    var blur = new BlurFilter();
    blur.set_value("radius", 1.0);
    var edge = new EdgeFilter();
    var threshold = new ThresholdFilter();
    threshold.set_value("threshold", 128.0);

    var chain = new FilterChain();
    chain.add(blur);
    chain.add(edge);
    chain.add(threshold);
    runner.check(chain.move(2, 0), "move must succeed");

    var manual = edge.apply(blur.apply(threshold.apply(image)));
    var result = chain.apply(image);
    runner.check_images_equal(result, manual, "moved chain matches manual order");
}

private void test_chain_empty(Runner runner) throws GLib.Error {
    var image = make_gradient(6, 6);
    var result = new FilterChain().apply(image);
    runner.check_images_equal(image, result, "empty chain copies the input");
}
