import 'package:flutter/material.dart';
import 'package:major_components/src/backdrop/models/open_state.dart';

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
  Widget build(context) {
    final open = BackdropOpenState.of(context);

    final button = IconButton(
      onPressed: open.toggleOpen,
      tooltip: tooltip,
      icon: AnimatedIcon(icon: icon, progress: open.animation),
    );
    return button;
  }
}
