package none.george.munny;

public interface Listener<T> {
    void on(T result);
    void error(Exception e);
}
