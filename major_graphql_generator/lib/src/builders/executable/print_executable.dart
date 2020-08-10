import 'package:major_graphql_generator/src/builders/executable/print_fragment.dart';
import 'package:major_graphql_generator/src/builders/executable/print_operation.dart';
import 'package:major_graphql_generator/src/operation.dart';
import 'package:major_graphql_generator/src/builders/utils.dart';

String printExecutable(
  ExecutableDocument document,
  String serializersUniqueName,
  List<String> importedSerializers,
) {
  final rootPath = PathFocus.root();
  return format('''
  ${document.fragments.map((frag) => printFragment(frag, rootPath)).join('\n')}

  ${document.operations.map((op) => printOperation(op, rootPath)).join('\n')}

  ${printModuleSerializers(
    serializersUniqueName,
    importedSerializers,
    rootPath.manager.usedNames
        .where((name) => !name.contains('Builder'))
        .toSet(),
  )}

  ${ignoreLints}
  ''');
}

String printModuleSerializers(
  String serializersUniqueName,
  List<String> importedSerializers,
  Iterable<String> serializables,
) {
  final valueClasses = serializables.toSet();
  final fragments = <String>{};
  for (var ss in serializables.where((name) => name.endsWith('SelectionSet'))) {
    final fragmentName = ss.substring(0, ss.length - 'SelectionSet'.length);
    valueClasses.remove(fragmentName);
    fragments.add(fragmentName);
  }

  final serializers = '(serializers.toBuilder()..addAll([' +
      fragments.map((f) => '$f.serializer').join(',') +
      '])).build()';

  return '''
  const ${serializersUniqueName} = <Type>[
    ${importedSerializers.map((s) => '...$s').join(', ')},
    ${valueClasses.join(',')}
  ];

  ${moduleSerializers(serializersUniqueName, serializers)}
  ''';
}
