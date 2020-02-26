import 'package:build/build.dart' show BuilderOptions, AssetId;

import './src/builders/schema/builder.dart';
import './src/builders/executable/builder.dart';

SchemaBuilder schemaBuilder(BuilderOptions options) {
  return SchemaBuilder();
}

ExecutableDocumentBuilder executableBuilder(BuilderOptions options) {
  return ExecutableDocumentBuilder(
    schemaId: AssetId.parse(options.config['schema'] as String),
  );
}
