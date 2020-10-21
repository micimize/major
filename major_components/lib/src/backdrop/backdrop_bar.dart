import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './pop_in.dart';
import './cross_fade.dart';

import './backdrop_state_provider.dart';
import './leading_toggle_button.dart';
import 'package:major_components/src/backdrop/_simple_switcher.dart';

typedef ContentLayoutBuilder = Widget Function(
  BuildContext context,
  BackdropBarContent content,
);
typedef WidgetLayoutBuilder = Widget Function(
    BuildContext context, Widget content);

typedef ApplyTheme = Widget Function(ThemeData context, Widget content);

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

  static final defaultFinalLayout = wrap(
    withPrimaryHeadlines,
    contentAsRow,
  );
}

class BackdropBar extends StatefulWidget {
  BackdropBar({
    Key key,
    this.top,
    this.front,
    this.back,
    this.contentLayout = const BackdropBarContentLayout(),
  })  : assert(front != null || back != null || top != null),
        super(key: key);

  final BackdropBarContent back;

  final BackdropBarContent front;
  final double pixelToPercent = 0.01;

  final BackdropBarContentLayout contentLayout;

  /// A "top level" navigation element that is expected to be the same across pages.
  ///
  /// This allows for, say, having both detail front and categorical back content,
  /// as well as a overarching tab navigation.
  final BackdropBarContent top;

  @override
  _BackdropBarState createState() => _BackdropBarState();
}

class _BackdropBarState extends State<BackdropBar> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, _) {
        final backdropState = watch(BackdropOpenState.current);
        return _BackdropBarRenderer(
          openState: backdropState,
          stack: widget,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Renders the given backdrops
///
/// Takes care of messy details like cross-fading defaults,
/// TODO and "peak" animations
///
/// Having this be it's own class also makes
/// managing the backdrop state easier
class _BackdropBarRenderer extends StatelessWidget {
  const _BackdropBarRenderer({
    Key key,
    @required this.openState,
    @required this.stack,
  }) : super(key: key);

  final BackdropOpenState openState;
  final BackdropBar stack;

  BackdropBarContent get top => stack.top;

  BackdropBarContent get front => stack.front;

  BackdropBarContent get back => stack.back;

  /// Applies peak animation to top bar if necessary
  Animation<double> get topBarAnimation {
    if (openState.peakBehavior == null) {
      return openState.controller.view;
    }
    return AnimationMax(
        openState.controller.view, openState.peakBehavior.controller.view);
  }

  Widget _withTop(Widget item, Widget top) {
    if (top == null) {
      return item;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PopIn(animation: topBarAnimation, child: top),
        item,
      ],
    );
  }

  SimpleSwitcher switcher(Widget item) => SimpleSwitcher(
        alignment: Alignment.centerLeft,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        duration: Duration(milliseconds: 250),
        sizeCurve: Interval(0.0, 0.5, curve: Curves.linear),
        fadeCurve: Interval(0.5, 1.0, curve: Curves.linear),
        child: item ?? SizedBox(width: 0, height: 0),
      );

  /// Intelligently stack a BackdropBar widget
  Widget _stacked(Widget front, Widget back, Widget top) {
    if (back == null && front == null) {
      return top;
    }
    final item = crossFade(
      openState.isOpen,
      openState.controller,
      back,
      front,
    );
    return _withTop(
      switcher(item),
      switcher(top),
    );
  }

  Widget get leading {
    final lead = _stacked(front?.leading, back?.leading, top?.leading) ??
        LeadingToggleButton();
    assert(
      lead != null,
      'There must be at least one non-null leading widget in the BackdropBar stack.',
    );
    return lead;
  }

  Widget get title {
    final title = _stacked(front?.title, back?.title, top?.title);
    assert(
      title != null,
      'There must be at least one non-null title widget in the BackdropBar stack.',
    );
    return title;
  }

  Widget get trailing =>
      _stacked(front?.trailing, back?.trailing, top?.trailing);

  @override
  Widget build(BuildContext context) {
    final content = BackdropBarContent(
      leading: leading,
      title: title,
      trailing: trailing,
    );
    final bar = stack.contentLayout.apply(context, content);

    /// TODO should be own abstraction for handling the theming of the backdrop
    final color = Theme.of(context).primaryColor;
    return Hero(
      tag: 'major_components.BackdropBar',
      child: Material(
        color: color,
        child: bar,
      ),
    );
  }
}

class BackdropTitle extends StatelessWidget {
  const BackdropTitle({Key key, this.text, this.child})
      : assert(text != null || child != null),
        super(key: key);

  static BackdropTitle fromText(String text) =>
      BackdropTitle(text: text, key: Key(text));

  final Widget child;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
      child: child ??
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .headline5
                .copyWith(color: Colors.white),
          ),
    );
  }
}
