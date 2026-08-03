namespace FrameSmith {

public class ChainHistory {
    private GenericArray<FilterChain> undo_stack;
    private GenericArray<FilterChain> redo_stack;

    public ChainHistory() {
        undo_stack = new GenericArray<FilterChain>();
        redo_stack = new GenericArray<FilterChain>();
    }

    public int undo_count {
        get { return undo_stack.length; }
    }

    public int redo_count {
        get { return redo_stack.length; }
    }

    public bool can_undo {
        get { return undo_stack.length > 0; }
    }

    public bool can_redo {
        get { return redo_stack.length > 0; }
    }

    public void push(FilterChain chain) {
        undo_stack.add(chain.clone());
        redo_stack = new GenericArray<FilterChain>();
    }

    public FilterChain? undo(FilterChain current) {
        if (undo_stack.length == 0)
            return null;
        var previous = undo_stack.remove_index(undo_stack.length - 1);
        redo_stack.add(current.clone());
        return previous;
    }

    public FilterChain? redo(FilterChain current) {
        if (redo_stack.length == 0)
            return null;
        var next = redo_stack.remove_index(redo_stack.length - 1);
        undo_stack.add(current.clone());
        return next;
    }

    public void clear() {
        undo_stack = new GenericArray<FilterChain>();
        redo_stack = new GenericArray<FilterChain>();
    }
}

}
