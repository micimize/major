typedef MapFn<A, B> = B Function(A a);

typedef IndexedMapFn<A, B> = B Function(A a, int index);

MapFn<A, B> withIndex<A, B>(IndexedMapFn<A, B> mapFn) {
  int index = -1;
  return (A a) => mapFn(a, ++index);
}

bool notNull(Object any) => any != null;
