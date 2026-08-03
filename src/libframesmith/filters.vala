namespace FrameSmith {

public class FilterParam {
    public string id { get; private set; }
    public string label { get; private set; }
    public double minimum { get; private set; }
    public double maximum { get; private set; }
    public double step { get; private set; }
    public double value { get; set; }

    public FilterParam(string id, string label, double minimum, double maximum, double step, double value) {
        this.id = id;
        this.label = label;
        this.minimum = minimum;
        this.maximum = maximum;
        this.step = step;
        this.value = value;
    }
}

public abstract class Filter : Object {
    public abstract string filter_id { get; }
    public abstract string display_name { get; }

    private GenericArray<FilterParam> parameters;

    protected Filter() {
        parameters = new GenericArray<FilterParam>();
    }

    protected void add_param(FilterParam parameter) {
        parameters.add(parameter);
    }

    public int param_count {
        get { return parameters.length; }
    }

    public FilterParam? get_param(int index) {
        if (index < 0 || index >= parameters.length)
            return null;
        return parameters.get(index);
    }

    public double get_value(string id) {
        var parameter = find_param(id);
        return parameter == null ? 0.0 : parameter.value;
    }

    public void set_value(string id, double value) {
        var parameter = find_param(id);
        if (parameter != null)
            parameter.value = value;
    }

    protected FilterParam? find_param(string id) {
        for (int i = 0; i < parameters.length; i++)
            if (parameters.get(i).id == id)
                return parameters.get(i);
        return null;
    }

    protected void copy_params_to(Filter target) {
        for (int i = 0; i < parameters.length; i++) {
            var parameter = parameters.get(i);
            target.set_value(parameter.id, parameter.value);
        }
    }

    public abstract Filter clone();
    public abstract Image apply(Image input);
    public abstract string describe();
}

public class BlurFilter : Filter {
    public BlurFilter() {
        add_param(new FilterParam("radius", "Radius", 0.0, 8.0, 0.5, 2.0));
    }

    public override string filter_id {
        get { return "blur"; }
    }

    public override string display_name {
        get { return "Blur"; }
    }

    public override Image apply(Image input) {
        double radius = get_value("radius");
        if (radius <= 0.0)
            return input.copy();
        return Convolution.apply(input, Kernel.gaussian(radius));
    }

    public override string describe() {
        return "Blur (radius %g)".printf(get_value("radius"));
    }

    public override Filter clone() {
        var copy = new BlurFilter();
        copy_params_to(copy);
        return copy;
    }
}

public class SharpenFilter : Filter {
    public SharpenFilter() {
        add_param(new FilterParam("amount", "Amount", 0.0, 4.0, 0.1, 1.0));
        add_param(new FilterParam("radius", "Radius", 0.0, 8.0, 0.5, 1.0));
    }

    public override string filter_id {
        get { return "sharpen"; }
    }

    public override string display_name {
        get { return "Sharpen"; }
    }

    public override Image apply(Image input) {
        double amount = get_value("amount");
        if (amount <= 0.0)
            return input.copy();

        var gaussian = Kernel.gaussian(get_value("radius"));
        var kernel = new Kernel(gaussian.size);
        int center = gaussian.size / 2;
        for (int y = 0; y < gaussian.size; y++)
            for (int x = 0; x < gaussian.size; x++) {
                double g = gaussian.get_weight(x, y) / gaussian.divisor;
                if (x == center && y == center)
                    kernel.set_weight(x, y, 1.0 + amount - amount * g);
                else
                    kernel.set_weight(x, y, -amount * g);
            }
        return Convolution.apply(input, kernel);
    }

    public override string describe() {
        return "Sharpen (amount %g)".printf(get_value("amount"));
    }

    public override Filter clone() {
        var copy = new SharpenFilter();
        copy_params_to(copy);
        return copy;
    }
}

public class EdgeFilter : Filter {
    public EdgeFilter() {
        add_param(new FilterParam("amplify", "Amplify", 0.5, 3.0, 0.1, 1.0));
        add_param(new FilterParam("invert", "Invert", 0.0, 1.0, 1.0, 0.0));
    }

    public override string filter_id {
        get { return "edge"; }
    }

    public override string display_name {
        get { return "Edge detect"; }
    }

    public override Image apply(Image input) {
        bool invert = get_value("invert") >= 0.5;
        var output = Convolution.sobel(input, get_value("amplify"));
        if (!invert)
            return output;
        for (int i = 0; i < output.pixels.length; i += 4) {
            output.pixels[i] = (uint8)(255 - output.pixels[i]);
            output.pixels[i + 1] = (uint8)(255 - output.pixels[i + 1]);
            output.pixels[i + 2] = (uint8)(255 - output.pixels[i + 2]);
        }
        return output;
    }

    public override string describe() {
        return "Edge detect (amplify %g)".printf(get_value("amplify"));
    }

    public override Filter clone() {
        var copy = new EdgeFilter();
        copy_params_to(copy);
        return copy;
    }
}

public class ThresholdFilter : Filter {
    public ThresholdFilter() {
        add_param(new FilterParam("threshold", "Threshold", 0.0, 255.0, 1.0, 128.0));
        add_param(new FilterParam("invert", "Invert", 0.0, 1.0, 1.0, 0.0));
    }

    public override string filter_id {
        get { return "threshold"; }
    }

    public override string display_name {
        get { return "Threshold"; }
    }

    public override Image apply(Image input) {
        double threshold = get_value("threshold");
        bool invert = get_value("invert") >= 0.5;

        var output = new Image(input.width, input.height);
        for (int y = 0; y < input.height; y++)
            for (int x = 0; x < input.width; x++) {
                int idx = input.pixel_index(x, y);
                double luminance = 0.299 * input.pixels[idx] +
                                   0.587 * input.pixels[idx + 1] +
                                   0.114 * input.pixels[idx + 2];
                uint8 value = luminance < threshold ? (uint8)0 : (uint8)255;
                if (invert)
                    value = (uint8)(255 - value);
                int out = output.pixel_index(x, y);
                output.pixels[out] = value;
                output.pixels[out + 1] = value;
                output.pixels[out + 2] = value;
                output.pixels[out + 3] = input.pixels[idx + 3];
            }
        return output;
    }

    public override string describe() {
        return "Threshold (%g)".printf(get_value("threshold"));
    }

    public override Filter clone() {
        var copy = new ThresholdFilter();
        copy_params_to(copy);
        return copy;
    }
}

public class LevelsFilter : Filter {
    public LevelsFilter() {
        add_param(new FilterParam("black", "Black point", 0.0, 255.0, 1.0, 0.0));
        add_param(new FilterParam("white", "White point", 0.0, 255.0, 1.0, 255.0));
        add_param(new FilterParam("gamma", "Gamma", 0.1, 3.0, 0.05, 1.0));
    }

    public override string filter_id {
        get { return "levels"; }
    }

    public override string display_name {
        get { return "Levels"; }
    }

    public override Image apply(Image input) {
        double black = get_value("black");
        double white = get_value("white");
        if (white <= black)
            white = black + 1.0;
        double range = white - black;
        double gamma_inverse = 1.0 / get_value("gamma");

        var output = new Image(input.width, input.height);
        for (int y = 0; y < input.height; y++)
            for (int x = 0; x < input.width; x++) {
                int idx = input.pixel_index(x, y);
                for (int c = 0; c < 3; c++) {
                    double t = (input.pixels[idx + c] - black) / range;
                    if (t < 0.0) t = 0.0;
                    else if (t > 1.0) t = 1.0;
                    t = Math.pow(t, gamma_inverse);
                    output.pixels[idx + c] = Convolution.to_byte(t * 255.0);
                }
                output.pixels[idx + 3] = input.pixels[idx + 3];
            }
        return output;
    }

    public override string describe() {
        return "Levels (gamma %g)".printf(get_value("gamma"));
    }

    public override Filter clone() {
        var copy = new LevelsFilter();
        copy_params_to(copy);
        return copy;
    }
}

public class FilterFactory {
    public static string[] available_ids() {
        return { "blur", "sharpen", "edge", "threshold", "levels" };
    }

    public static Filter? create(string id) {
        switch (id) {
            case "blur":
                return new BlurFilter();
            case "sharpen":
                return new SharpenFilter();
            case "edge":
                return new EdgeFilter();
            case "threshold":
                return new ThresholdFilter();
            case "levels":
                return new LevelsFilter();
            default:
                return null;
        }
    }

    public static string display_name(string id) {
        switch (id) {
            case "blur":
                return "Blur";
            case "sharpen":
                return "Sharpen";
            case "edge":
                return "Edge detect";
            case "threshold":
                return "Threshold";
            case "levels":
                return "Levels";
            default:
                return id;
        }
    }
}

}
