import 'package:meta/meta.dart';
import 'package:gql/ast.dart';

import './definitions.dart';

export './definitions.dart';

@immutable
class ExecutableDocument extends ExecutableWithResolver {
  const ExecutableDocument(this.astNode, [GetExecutableType getType])
      : super(getType);

  @override
  final DocumentNode astNode;

  FragmentDefinition getFragment(String name) =>
      fragments.firstWhere((frag) => frag.name == name, orElse: () => null);

  List<ExecutableDefinition> get definitions => astNode.definitions
      .cast<ExecutableDefinitionNode>()
      .map((def) => ExecutableDefinition.fromNode(def, getType))
      .toList();

  List<FragmentDefinition> get fragments =>
      definitions.whereType<FragmentDefinition>().toList();

  List<OperationDefinition> get operations =>
      definitions.whereType<OperationDefinition>().toList();
}
