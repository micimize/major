part of './backdrop.dart';

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
          Iterable<WidgetLayoutBuilder> wrappers) =>
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
          style: theme.primaryTextTheme.headline6, child: child),
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

enum BackdropBarPeakBehavior {
  /// No implicit affordance for peaking the `top` bar content from the `frontLayer`
  None,

  /// Logically the same as `None`, but semantically indicates an explicit affordance
  Manual,

  /// Peak and hide the `top` bar content based on a drag down from the user on the `frontLayer`
  DragFrontLayer,
}

class BackdropBar extends StatefulWidget {
  BackdropBar({
    Key key,
    this.top,
    this.front,
    this.back,
    this.peakBehavior = BackdropBarPeakBehavior.DragFrontLayer,
    this.backgroundColor,
    this.contentLayout = const BackdropBarContentLayout(),
  })  : assert(front != null || back != null || top != null),
        super(key: key);

  final BackdropBarContent back;

  final BackdropBarContent front;
  final BackdropBarPeakBehavior peakBehavior;
  final double pixelToPercent = 0.01;

  final Color backgroundColor;

  final BackdropBarContentLayout contentLayout;

  /// A "top level" navigation element that is expected to be the same across pages.
  ///
  /// This allows for, say, having both detail front and categorical back content,
  /// as well as a overarching tab navigation.
  final BackdropBarContent top;

  @override
  _BackdropBarState createState() => _BackdropBarState();

  /// Returns true to cancel bubbling
  void applyPeakBehavior(
    AnimationController peakController,
    ScrollUpdateNotification notification,
  ) {
    if (peakBehavior != BackdropBarPeakBehavior.DragFrontLayer) {
      return null;
    }
    if (notification.dragDetails == null) {
      return applyPeakSnapBehavior(peakController, notification);
    }

    peakController.value += notification.dragDetails.primaryDelta / 56;
  }

  void applyPeakSnapBehavior(
    AnimationController peakController,
    ScrollNotification notification,
  ) async {
    if (peakController.isAnimating ||
        peakController.status == AnimationStatus.completed) return;
    peakController.fling(velocity: peakController.value > 0.5 ? 1.0 : -1.0);
  }
}

class _BackdropBarState extends State<BackdropBar> {
  @override
  Widget build(BuildContext context) {
    final backdropState = Backdrop.of(context);
    return _BackdropBarRenderer(
      peakBehavior: widget.peakBehavior,
      isOpen: backdropState.isOpen,
      backdropController: backdropState.controller,
      peakController: Provider.of<AnimationController>(context),
      stack: widget,
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
    @required this.isOpen,
    @required this.backdropController,
    @required this.peakController,
    @required this.peakBehavior,
    @required this.stack,
  }) : super(key: key);

  final AnimationController backdropController;
  final bool isOpen;
  final BackdropBarPeakBehavior peakBehavior;
  final AnimationController peakController;
  final BackdropBar stack;

  BackdropBarContent get top => stack.top;

  BackdropBarContent get front => stack.front;

  BackdropBarContent get back => stack.back;

  BackdropBarContent get peakBar => stack.top;

  Widget _withTop(Widget item, Widget top) {
    if (top == null) {
      return item;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PopIn(
          animation: AnimationMax(backdropController.view, peakController.view),
          child: top,
        ),
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
      isOpen,
      backdropController,
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

    final ThemeData theme = Theme.of(context);
    return Container(
      color: stack.backgroundColor ?? theme.primaryColor,
      child: stack.contentLayout.apply(context, content),
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
