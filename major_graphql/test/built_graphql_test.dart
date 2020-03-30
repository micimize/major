import 'package:test/test.dart';
import 'package:major_graphql/major_graphql.dart';

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
