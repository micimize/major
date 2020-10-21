typedef MapFn<A, B> = B Function(A a);

typedef IndexedMapFn<A, B> = B Function(A a, int index);

MapFn<A, B> withIndex<A, B>(IndexedMapFn<A, B> mapFn) {
  int index = -1;
  return (A a) => mapFn(a, ++index);
}

typedef WithPrevious<A, B> = B Function(
  A current, {
  B previousResult,
});

MapFn<A, B> withPrevious<A, B>(WithPrevious<A, B> mapFn) {
  B previousResult;
  return (A current) {
    final result = mapFn(current, previousResult: previousResult);
    previousResult = result;
    return result;
  };
}

bool notNull(Object any) => any != null;
