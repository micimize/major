import 'package:flutter/material.dart' show debugPrint;
import 'package:graphql/src/utilities/traverse.dart';
import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart' show LazyCacheMap;

final JsonEncoder encoder = const JsonEncoder.withIndent('  ');

class LazyCacheMapTraversal extends Traversal {
  LazyCacheMapTraversal() : super((Object n) => null);

  @override
  Object traverse(Object node) {
    final seen = alreadySeen(node);
    if (node is LazyCacheMap) {
      if (seen) {
        return '...';
      }
      node = Map<String, dynamic>.fromEntries((node as LazyCacheMap).entries);
    }
    if (seen) {
      return node;
    }
    if (node is List<Object>) {
      return node.map<Object>((Object node) => traverse(node)).toList();
    }
    if (node is Map<String, Object>) {
      return traverseValues(node);
    }
    return node;
  }
}

dynamic getJson(LazyCacheMap cacheMap) {
  return LazyCacheMapTraversal().traverse(cacheMap);
}

void pprint(dynamic json) {
  final dynamic _json = (json is LazyCacheMap) ? getJson(json) : json;
  debugPrint(encoder.convert(_json));
}
