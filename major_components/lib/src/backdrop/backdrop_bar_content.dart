import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

typedef ContentLayoutBuilder = Widget Function(
  BuildContext context,
  BackdropBarContent content,
);
typedef WidgetLayoutBuilder = Widget Function(
    BuildContext context, Widget content);

// TODO could this be a regular stateless widget that has it's build overridden when composed?
/// A line of content to be composed into a [BackdropBar]
///
/// All arguments are optional, as they are coalesced intelligently across the stack
/// Cannot be rendered outside of a [BackdropBar]
class BackdropBarContent {
  const BackdropBarContent({
    this.leading,
    this.title,
    this.trailing = const SizedBox(width: 0, height: 0),
  });

  /// Leading icon or icon-like widget
  final Widget leading;

  /// Title or title-sized widget
  final Widget title;

  /// Trailing icon or icon-like widget
  final Widget trailing;
}

class BackdropBarContentLayout {
  const BackdropBarContentLayout({
    this.finalLayout,
    this.leading = defaultLeading,
    this.title = defaultTitle,
    this.trailing = defaultTrailing,
  });

  final ContentLayoutBuilder finalLayout;
  final WidgetLayoutBuilder leading;
  final WidgetLayoutBuilder title;
  final WidgetLayoutBuilder trailing;

  /// Apply the layout functions to the given [content]
  Widget apply(BuildContext context, BackdropBarContent content) =>
      (finalLayout ?? defaultFinalLayout)(
        context,
        BackdropBarContent(
          leading: leading(context, content.leading),
          title: title(context, content.title),
          trailing: trailing(context, content.trailing),
        ),
      );

  static Widget defaultLeading(BuildContext _, Widget leading) => Container(
        alignment: Alignment.center,
        width: 56.0,
        height: 56.0,
        child: leading,
      );

  static Widget defaultTrailing(BuildContext _, Widget trailing) =>
      (trailing != null) ? defaultLeading(_, trailing) : null;

  static Widget defaultTitle(BuildContext _, Widget title) => Expanded(
        child: Container(
          padding: EdgeInsets.only(top: 6.0),
          child: title,
        ),
      );

  /// Compose [wrappers] that don't need to know about the details of context
  static WidgetLayoutBuilder composeWrappers(
    Iterable<WidgetLayoutBuilder> wrappers,
  ) =>
      (context, widget) {
        var _widget = widget;
        for (final wrapper in wrappers) {
          _widget = wrapper(context, _widget);
        }
        return _widget;
      };

  /// Wrap a [contentBuilder] with a [wrapper] that doesn't need to know about the details of context
  static ContentLayoutBuilder wrap(
    WidgetLayoutBuilder wrapper,
    ContentLayoutBuilder contentBuilder,
  ) =>
      (context, content) => wrapper(context, contentBuilder(context, content));

  static Widget withPrimaryHeadlines(BuildContext context, Widget child) {
    final ThemeData theme = Theme.of(context);

    return IconTheme.merge(
      data: theme.primaryIconTheme,
      child: DefaultTextStyle(
        style: theme.primaryTextTheme.headline6,
        child: child,
      ),
    );
  }

  static Widget withSafeTopPadding(BuildContext context, Widget child) {
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: child,
    );
  }

  static Widget contentAsRow(
    BuildContext context,
    BackdropBarContent content,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content.leading,
          content.title,
          if (content.trailing != null) content.trailing
        ],
      );

  /// Adds usual styles to backdrop,
  /// such as primary icons, headline text, and notch padding.
  static final defaultFinalLayout = wrap(
    composeWrappers([
      withSafeTopPadding,
      withPrimaryHeadlines,
    ]),
    contentAsRow,
  );
}
