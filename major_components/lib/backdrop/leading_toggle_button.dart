part of './backdrop.dart';

/// Menu button that toggles
///
/// <i class="material-icons md-36">menu</i> &#x2014; material icon named "menu".
/// <i class="material-icons md-36">close</i> &#x2014; material icon named "close".
class LeadingToggleButton extends StatelessWidget {
  const LeadingToggleButton({
    Key key,
    this.tooltip = 'Toggle options page',
    this.icon = AnimatedIcons.menu_close,
  }) : super(key: key);

  final AnimatedIconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final backdropState = Backdrop.of(context);
    return IconButton(
      onPressed: backdropState.toggleFrontLayer,
      tooltip: tooltip,
      icon: AnimatedIcon(
        icon: icon,
        progress: backdropState.controller,
      ),
    );
  }
}
