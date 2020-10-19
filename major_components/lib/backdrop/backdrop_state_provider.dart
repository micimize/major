import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Container for backdrop open state state
@immutable
class BackdropOpenState {
  const BackdropOpenState({
    @required this.isOpen,
    @required this.controller,
    this.onOpenChanged,
  });

  /// Whether the backdrop is expanded, semantically
  final bool isOpen;

  /// Callback to trigger when the backdrop wants to change the open state
  final ValueChanged<bool> onOpenChanged;

  final AnimationController controller;

  static final current = ScopedProvider<BackdropOpenState>(
    (_) => throw UnimplementedError(),
  );

  BackdropOpenState withListener(
    ValueChanged<bool> onOpenChangedListener,
  ) =>
      BackdropOpenState(
          isOpen: isOpen,
          controller: controller,
          onOpenChanged: (bool newValue) {
            if (onOpenChanged != null) {
              onOpenChanged(newValue);
            }
            onOpenChangedListener(newValue);
          });

  @override
  bool operator ==(Object other) =>
      (other is BackdropOpenState) &&
      controller == other.controller &&
      isOpen == other.isOpen &&
      onOpenChanged == other.onOpenChanged;
}
