import 'package:meta/meta.dart';
import 'package:gql/ast.dart';

import './definitions.dart';

class ExecutableDocument extends ExecutableGraphQLEntity {
  const ExecutableDocument(this.astNode);

  @override
  final DocumentNode astNode;

  List<ExecutableDefinition> get definitions => astNode.definitions
      .cast<ExecutableDefinitionNode>()
      .map(ExecutableDefinition.fromNode)
      .toList();

  List<FragmentDefinition> get fragments =>
      definitions.whereType<FragmentDefinition>().toList();

  List<OperationDefinition> get operations =>
      definitions.whereType<OperationDefinition>().toList();
}
