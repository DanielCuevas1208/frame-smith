namespace FrameSmith {

public class FramesmithApp : Gtk.Application {
    private MainWindow? main_window;

    public FramesmithApp() {
        Object(application_id: "org.framesmith.FrameSmith",
               flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    protected override void activate() {
        if (main_window == null)
            main_window = new MainWindow(this);
        main_window.present();
    }

    protected override int command_line(ApplicationCommandLine command_line) {
        activate();
        string[] arguments = command_line.get_arguments();
        if (arguments.length > 1) {
            var window = main_window;
            if (window != null)
                window.open_file(arguments[1]);
        }
        return 0;
    }

    public static int main(string[] args) {
        return new FramesmithApp().run(args);
    }
}

}
