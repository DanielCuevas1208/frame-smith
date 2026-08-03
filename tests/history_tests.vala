using FrameSmith;
using FrameSmith.Tests;

int main(string[] args) {
    var runner = new Runner("history");
    runner.run("history starts empty", test_empty);
    runner.run("push records a snapshot", test_push);
    runner.run("undo restores the previous state", test_undo);
    runner.run("redo restores the undone state", test_redo);
    runner.run("undo clears on new push", test_undo_clears_redo);
    runner.run("push keeps past history", test_push_keeps_history);
    runner.run("clear resets stacks", test_clear);
    runner.run("snapshots are independent", test_independent);
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

private Filter make_filter(string id) {
    var filter = FilterFactory.create(id);
    assert(filter != null);
    if (filter != null)
        return filter;
    return new BlurFilter();
}

private void check_chain_renders(Runner runner, FilterChain chain,
                                 Image input, string name) throws GLib.Error {
    var manual = new FilterChain();
    for (int i = 0; i < chain.size; i++) {
        var filter = chain.get(i);
        if (filter == null)
            continue;
        var copy = FilterFactory.create(filter.filter_id);
        if (copy == null)
            continue;
        for (int p = 0; p < filter.param_count; p++) {
            var param = filter.get_param(p);
            if (param != null)
                copy.set_value(param.id, param.value);
        }
        manual.add(copy);
    }
    runner.check_images_equal(chain.apply(input), manual.apply(input), name);
}

private void test_empty(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    runner.check_eq_int(history.undo_count, 0, "undo count starts empty");
    runner.check_eq_int(history.redo_count, 0, "redo count starts empty");
    runner.check(!history.can_undo, "cannot undo at start");
    runner.check(!history.can_redo, "cannot redo at start");
}

private void test_push(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();
    history.push(chain);
    chain.add(make_filter("blur"));
    runner.check(history.can_undo, "push enables undo");
    runner.check_eq_int(history.undo_count, 1, "one undo step");
    runner.check_eq_int(history.redo_count, 0, "redo stays empty");
}

private void test_undo(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();
    var input = make_gradient(8, 8);

    history.push(chain);
    chain.add(make_filter("blur"));
    history.push(chain);
    chain.add(make_filter("threshold"));

    var restored = history.undo(chain);
    runner.check(restored != null, "undo returns a chain");
    runner.check_eq_int(restored.size, 1, "restored chain has one filter");
    runner.check(history.can_undo, "one undo step remains");
    runner.check(history.can_redo, "undo enables redo");
    check_chain_renders(runner, restored, input, "undo restores the blur state");
}

private void test_redo(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();
    var input = make_gradient(8, 8);

    history.push(chain);
    chain.add(make_filter("blur"));
    history.push(chain);

    var undone = history.undo(chain);
    runner.check(undone != null, "undo returns a chain");

    var restored = history.redo(undone);
    runner.check(restored != null, "redo returns a chain");
    runner.check_eq_int(restored.size, 1, "redone chain has one filter");
    runner.check(!history.can_redo, "redo empties after redo");
    runner.check(history.can_undo, "redo restores undo availability");
    check_chain_renders(runner, restored, input, "redo restores the blur state");
}

private void test_undo_clears_redo(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();

    history.push(chain);
    chain.add(make_filter("blur"));
    history.push(chain);

    var undone = history.undo(chain);
    runner.check(undone != null, "undo returns a chain");
    runner.check(history.can_redo, "redo available before a new edit");

    history.push(undone);
    runner.check(!history.can_redo, "a new edit clears redo");
    runner.check_eq_int(history.undo_count, 2, "undo grows with the new edit");
}

private void test_push_keeps_history(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();

    history.push(chain);
    chain.add(make_filter("blur"));
    history.push(chain);
    chain.add(make_filter("edge"));
    history.push(chain);

    runner.check_eq_int(history.undo_count, 3, "three undo steps");
    runner.check_eq_int(history.redo_count, 0, "redo empty");

    var restored = history.undo(chain);
    runner.check_eq_int(restored.size, 2, "first undo returns a two-filter chain");
    restored = history.undo(restored);
    runner.check_eq_int(restored.size, 1, "second undo returns a one-filter chain");
    restored = history.undo(restored);
    runner.check_eq_int(restored.size, 0, "third undo returns the empty chain");
    runner.check_eq_int(history.undo_count, 0, "all undo steps consumed");
    runner.check(!history.can_undo, "cannot undo after all steps");
}

private void test_clear(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();
    history.push(chain);
    chain.add(make_filter("blur"));
    history.push(chain);
    var undone = history.undo(chain);
    runner.check(undone != null, "undo available before clear");

    history.clear();
    runner.check_eq_int(history.undo_count, 0, "undo cleared");
    runner.check_eq_int(history.redo_count, 0, "redo cleared");
    runner.check(!history.can_undo, "cannot undo after clear");
    runner.check(!history.can_redo, "cannot redo after clear");
}

private void test_independent(Runner runner) throws GLib.Error {
    var history = new ChainHistory();
    var chain = new FilterChain();
    var blur = new BlurFilter();
    blur.set_value("radius", 2.0);
    chain.add(blur);

    history.push(chain);
    var live = chain.get(0);
    if (live != null)
        live.set_value("radius", 5.0);

    var restored = history.undo(chain);
    runner.check(restored != null, "undo returns a chain");

    var restored_filter = restored.get(0);
    runner.check(restored_filter != null, "restored chain has a filter");
    if (restored_filter != null)
        runner.check_close(restored_filter.get_value("radius"), 2.0, 0.001, "snapshot keeps the pushed radius");

    var live_filter = chain.get(0);
    runner.check(live_filter != null, "live chain has a filter");
    if (live_filter != null)
        runner.check_close(live_filter.get_value("radius"), 5.0, 0.001, "live chain keeps the edited radius");
}
