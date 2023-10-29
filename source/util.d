module yeti16.util;

T Op(T, char op)(T v1, T v2) {
	mixin("return v1" ~ op ~ "v2;");
}
