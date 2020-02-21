import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

String dartName(String name) => ReCase(name).camelCase;
String className(String name) => ReCase(name).pascalCase;

typedef ItemTemplate<T> = Iterable<String> Function(T item);

/// Templating helper for printing iterables
@immutable
class ListPrinter<T> {
  ListPrinter({
    this.itemTemplate,
    this.items,
    this.spacing = ' ',
    this.divider = ',',
    this.leading = '',
    this.trailing = '',
  });

  /// Template with which to render [items].
  ///
  /// Each individual result will be joined with [spacing],
  /// and the collective result will be joined with [divider].
  final ItemTemplate<T> itemTemplate;

  /// The items to render
  final Iterable<T> items;

  /// Spacing to add between each item returned by [template]
  final String spacing;

  /// Divider to join the results of [template] on
  final String divider;

  /// Leading prefix for the final result with **if** it is not empty
  final String leading;

  /// Trailing suffix for the final result with **if** it is not empty
  final String trailing;

  ListPrinter<T> copyWith({
    ItemTemplate<T> itemTemplate,
    Iterable<T> items,
    String spacing,
    String divider,
    String leading,
    String trailing,
  }) =>
      ListPrinter(
        itemTemplate: itemTemplate ?? this.itemTemplate,
        items: items ?? this.items,
        spacing: spacing ?? this.spacing,
        divider: divider ?? this.divider,
        leading: this.leading ?? leading,
        trailing: this.trailing ?? trailing,
      );

  ListPrinter<T> over(Iterable<T> items) => copyWith(items: items);

  ListPrinter<T> map(ItemTemplate<T> itemTemplate) =>
      copyWith(itemTemplate: itemTemplate);

  /// Wraps the printer in { }. alias for `copyWith(leading: '{', trailing: '}')`
  ListPrinter<T> get braced => copyWith(leading: '{', trailing: '}');

  /// Alias for `copyWith(divider: ';\n');`
  ListPrinter<T> get semicolons => copyWith(divider: ';\n');

  @override
  String toString() {
    final results =
        items.map((item) => itemTemplate(item).join(spacing)).join(divider);
    return results.isEmpty ? results : '$leading$results$trailing';
  }
}
