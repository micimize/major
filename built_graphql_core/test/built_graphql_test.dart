import 'package:test/test.dart';
import 'package:built_graphql_core/built_graphql_core.dart';

void main() {
  group('A group of tests', () {
    Object awesome;

    setUp(() {
      awesome = 'wow';
    });

    test('First Test', () {
      expect(awesome == 'wow', isTrue);
    });
  });
}
