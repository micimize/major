import 'package:major_graphql_generator/major_graphql_generator.dart';
import 'package:test/test.dart';

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
