import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './backdrop_state_provider.dart';

/// Menu button that toggles
///
/// <i class="material-icons md-36">menu</i> &#x2014; material icon named "menu".
/// <i class="material-icons md-36">close</i> &#x2014; material icon named "close".
class LeadingToggleButton extends ConsumerWidget {
  const LeadingToggleButton({
    Key key,
    this.tooltip = 'Toggle options page',
    this.icon = AnimatedIcons.menu_close,
  }) : super(key: key);

  final AnimatedIconData icon;
  final String tooltip;

  @override
  Widget build(context, watch) {
    final backdropState = watch(BackdropOpenState.current);

    final button = IconButton(
      onPressed: backdropState.toggleFrontLayer,
      tooltip: tooltip,
      icon: AnimatedIcon(
        icon: icon,
        progress: backdropState.controller,
      ),
    );
    return button;
  }
}
