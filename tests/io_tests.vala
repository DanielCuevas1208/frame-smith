using FrameSmith;
using FrameSmith.Tests;

int main(string[] args) {
    var runner = new Runner("io");
    if (args.length < 2) {
        stderr.printf("usage: test-io <path-to-sample.png>\n");
        return 2;
    }
    string sample_path = args[1];
    runner.run("loads the sample image", (r) => test_load(r, sample_path));
    runner.run("round trips png losslessly", (r) => test_roundtrip(r, sample_path));
    return runner.finish();
}

private void test_load(Runner runner, string path) throws GLib.Error {
    var pixbuf = new Gdk.Pixbuf.from_file(path);
    runner.check_eq_int(pixbuf.width, 128, "sample width");
    runner.check_eq_int(pixbuf.height, 128, "sample height");
    runner.check_eq_int(pixbuf.n_channels, 4, "sample channel count");

    var image = PixbufIO.to_image(pixbuf);
    runner.check_eq_int(image.width, 128, "image width");
    runner.check_eq_int(image.height, 128, "image height");
    runner.check_pixel(image, 0, 0, 96, 160, 224, "top-left sky pixel");
    runner.check_pixel(image, 0, 120, 214, 214, 208, "checker strip pixel");
}

private void test_roundtrip(Runner runner, string path) throws GLib.Error {
    var pixbuf = new Gdk.Pixbuf.from_file(path);
    var image = PixbufIO.to_image(pixbuf);
    var out_pixbuf = PixbufIO.from_image(image);

    string tmp_path = GLib.Path.build_filename(GLib.Environment.get_tmp_dir(), "framesmith-roundtrip.png");
    out_pixbuf.save(tmp_path, "png");
    var reloaded = new Gdk.Pixbuf.from_file(tmp_path);
    FileUtils.unlink(tmp_path);

    runner.check_eq_int(reloaded.width, 128, "reload width");
    runner.check_eq_int(reloaded.n_channels, 4, "reload channel count");

    var image2 = PixbufIO.to_image(reloaded);
    runner.check_images_equal(image, image2, "round trip must be lossless");
}
