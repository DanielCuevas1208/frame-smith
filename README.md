# Frame Smith

Frame Smith is a desktop image editor. It applies a chain of filters to an image. You see the result at once. You can reorder the filters in the chain.

The project uses the Vala language and the GTK toolkit. It builds with Meson. It is a compact portfolio project.

## Features

- Open common image formats through GdkPixbuf.
- Blur images with a Gaussian kernel.
- Sharpen images with an unsharp mask.
- Detect edges with the Sobel operator.
- Split luminance with a threshold.
- Adjust black point, white point, and gamma.
- Reorder the filter chain.
- View a per-channel histogram.
- Save the result as PNG, JPEG, BMP, or TIFF.

## Architecture

The project has two layers.

The core layer is `src/libframesmith`. It holds the pixel math. It has no toolkit code. This layer runs without a display. The tests use this layer directly.

The GUI layer is `src/framesmith`. It handles the window and the controls. It converts between `Image` and `Gdk.Pixbuf`. It never processes pixels itself.

The processing flow is simple:

1. Load an image from a file.
2. Convert the image to the internal RGBA format.
3. Apply each filter in the chain.
4. Convert the result back to a pixbuf.
5. Show the result and its histogram.

## Requirements

Build the project on Linux. Use these packages:

- GTK 3.22 or newer
- GdkPixbuf 2.40 or newer
- Vala 0.48 or newer
- Meson 0.61 or newer
- Ninja

On Ubuntu, install them with this command:

```
sudo apt install valac meson ninja-build libgtk-3-dev libgdk-pixbuf-2.0-dev
```

## Build

Do these steps to build the project:

1. Run `meson setup build`.
2. Run `meson compile -C build`.

The build uses `--fatal-warnings`. A Vala warning stops the build.

## Test

Run the tests with this command:

```
meson test -C build --print-errorlogs
```

The tests run without a display. They cover the filter math, the chain, and the file round trip.

## Run

Start the program with this command:

```
./build/framesmith data/sample.png
```

The file `data/sample.png` is a test image. It has a sky, a sun, a hill, and a checker strip.

## Use

Follow these steps to edit an image:

1. Click Open and choose an image.
2. Choose a filter and click Add.
3. Select the filter in the list.
4. Change the filter parameters.
5. Use the Up and Down buttons to reorder the chain.
6. Click Save As to write the result.

## Sample output

The test programs print lines like these:

```
ok   identity kernel preserves pixels
ok   gaussian blur keeps constant image
ok   gaussian blur spreads an impulse
ok   sharpen keeps constant image
ok   sharpen amplifies contrast
ok   edge finds a step edge
ok   edge ignores flat regions
ok   threshold splits luminance
ok   threshold invert
ok   levels remap and clamp
ok   levels gamma
ok   histogram counts channels
ok   chain applies in order
ok   chain move reorders
ok   empty chain is a copy
core: 15 passed, 0 failed
ok   loads the sample image
ok   round trips png losslessly
io: 2 passed, 0 failed
```

The expected visual effects are simple. Blur softens the hill edge. Sharpen makes the checker squares stand out. Edge detect turns the shapes into outlines. Threshold turns the image into black and white.

## Fixture

The script `tools/generate_sample.py` creates the sample image. It uses only the Python standard library. The image is deterministic. The script has a `--check` mode. This mode compares decoded pixels, not file bytes.

## Limitations

- The project builds on Linux. Windows builds are not supported.
- The preview renders at full resolution. Very large images can be slow.
- There is no undo or redo yet.
- The chain order changes with buttons, not by dragging.
- Each filter has one parameter set. There is no curves editor yet.

## Roadmap

Version 0.2:

- Add drag-and-drop reordering.
- Add undo and redo.
- Add preview downscaling for large images.

Version 0.3:

- Port the GUI to GTK 4.
- Add a per-channel curves editor.

Version 0.4:

- Add sepia, vignette, and noise filters.
- Add batch processing from the command line.

## License

Frame Smith is released under the MIT License. See the `LICENSE` file.
