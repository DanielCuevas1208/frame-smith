namespace FrameSmith {

public class FilterChain {
    private GenericArray<Filter> filters;

    public FilterChain() {
        filters = new GenericArray<Filter>();
    }

    public int size {
        get { return filters.length; }
    }

    public void add(Filter filter) {
        filters.add(filter);
    }

    public Filter? get(int index) {
        if (index < 0 || index >= filters.length)
            return null;
        return filters.get(index);
    }

    public bool remove_at(int index) {
        if (index < 0 || index >= filters.length)
            return false;
        filters.remove_index(index);
        return true;
    }

    public bool move(int from, int to) {
        if (from < 0 || from >= filters.length)
            return false;
        if (to < 0 || to >= filters.length)
            return false;
        if (from == to)
            return true;
        var filter = filters.get(from);
        filters.remove_index(from);
        filters.insert(to, filter);
        return true;
    }

    public void clear() {
        filters = new GenericArray<Filter>();
    }

    public Image apply(Image input) {
        if (filters.length == 0)
            return input.copy();
        Image result = input;
        for (int i = 0; i < filters.length; i++)
            result = filters.get(i).apply(result);
        return result;
    }

    public FilterChain clone() {
        var copy = new FilterChain();
        for (int i = 0; i < filters.length; i++)
            copy.add(filters.get(i).clone());
        return copy;
    }
}

}
