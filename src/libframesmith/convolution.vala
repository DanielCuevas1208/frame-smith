namespace FrameSmith {

public class Kernel {
    public int size { get; private set; }
    public double[] weights { get; private set; }
    public double divisor { get; set; }

    public Kernel(int size) {
        assert(size > 0 && size % 2 == 1);
        this.size = size;
        weights = new double[size * size];
        divisor = 1.0;
    }

    public void set_weight(int x, int y, double value) {
        weights[y * size + x] = value;
    }

    public double get_weight(int x, int y) {
        return weights[y * size + x];
    }

    public static Kernel identity() {
        var kernel = new Kernel(3);
        kernel.set_weight(1, 1, 1.0);
        return kernel;
    }

    public static Kernel gaussian(double radius) {
        double sigma = radius / 2.0;
        if (sigma < 0.25)
            sigma = 0.25;
        int extent = (int)Math.ceil(2.0 * sigma);
        int size = 2 * extent + 1;
        var kernel = new Kernel(size);
        double sum = 0.0;
        for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++) {
                double dx = x - extent;
                double dy = y - extent;
                double value = Math.exp(-(dx * dx + dy * dy) / (2.0 * sigma * sigma));
                kernel.set_weight(x, y, value);
                sum += value;
            }
        kernel.divisor = sum;
        return kernel;
    }
}

public class Convolution {
    public static uint8 to_byte(double value) {
        double rounded = Math.round(value);
        if (rounded < 0.0) return 0;
        if (rounded > 255.0) return 255;
        return (uint8)rounded;
    }

    public static Image apply(Image source, Kernel kernel) {
        if (kernel.size == 1)
            return source.copy();

        var output = new Image(source.width, source.height);
        int half = kernel.size / 2;

        for (int y = 0; y < source.height; y++)
            for (int x = 0; x < source.width; x++) {
                double acc_r = 0.0;
                double acc_g = 0.0;
                double acc_b = 0.0;
                for (int ky = 0; ky < kernel.size; ky++) {
                    int sy = y + (ky - half);
                    if (sy < 0) sy = 0;
                    else if (sy >= source.height) sy = source.height - 1;
                    for (int kx = 0; kx < kernel.size; kx++) {
                        int sx = x + (kx - half);
                        if (sx < 0) sx = 0;
                        else if (sx >= source.width) sx = source.width - 1;
                        double weight = kernel.get_weight(kx, ky) / kernel.divisor;
                        int idx = source.pixel_index(sx, sy);
                        acc_r += weight * source.pixels[idx];
                        acc_g += weight * source.pixels[idx + 1];
                        acc_b += weight * source.pixels[idx + 2];
                    }
                }
                int out = output.pixel_index(x, y);
                output.pixels[out] = to_byte(acc_r);
                output.pixels[out + 1] = to_byte(acc_g);
                output.pixels[out + 2] = to_byte(acc_b);
                output.pixels[out + 3] = source.pixels[source.pixel_index(x, y) + 3];
            }
        return output;
    }

    public static Image sobel(Image source, double amplify) {
        double[] gx_weights = { -1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0 };
        double[] gy_weights = { -1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0 };

        var output = new Image(source.width, source.height);
        for (int y = 0; y < source.height; y++)
            for (int x = 0; x < source.width; x++) {
                double accx_r = 0.0;
                double accx_g = 0.0;
                double accx_b = 0.0;
                double accy_r = 0.0;
                double accy_g = 0.0;
                double accy_b = 0.0;
                for (int ky = 0; ky < 3; ky++) {
                    int sy = y + ky - 1;
                    if (sy < 0) sy = 0;
                    else if (sy >= source.height) sy = source.height - 1;
                    for (int kx = 0; kx < 3; kx++) {
                        int sx = x + kx - 1;
                        if (sx < 0) sx = 0;
                        else if (sx >= source.width) sx = source.width - 1;
                        double wx = gx_weights[ky * 3 + kx];
                        double wy = gy_weights[ky * 3 + kx];
                        int idx = source.pixel_index(sx, sy);
                        accx_r += wx * source.pixels[idx];
                        accx_g += wx * source.pixels[idx + 1];
                        accx_b += wx * source.pixels[idx + 2];
                        accy_r += wy * source.pixels[idx];
                        accy_g += wy * source.pixels[idx + 1];
                        accy_b += wy * source.pixels[idx + 2];
                    }
                }
                int out = output.pixel_index(x, y);
                output.pixels[out] = to_byte(Math.sqrt(accx_r * accx_r + accy_r * accy_r) * amplify);
                output.pixels[out + 1] = to_byte(Math.sqrt(accx_g * accx_g + accy_g * accy_g) * amplify);
                output.pixels[out + 2] = to_byte(Math.sqrt(accx_b * accx_b + accy_b * accy_b) * amplify);
                output.pixels[out + 3] = source.pixels[source.pixel_index(x, y) + 3];
            }
        return output;
    }
}

}
