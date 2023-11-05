module yeti16.types;

struct Vec2(T) {
	T x, y;

	this(T px, T py) {
		x = px;
		y = py;
	}
}
