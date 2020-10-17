part of './backdrop.dart';

class BackdropController {
  const BackdropController({
    @required this.isOpen,
    @required this.controller,
    this.onOpenChanged,
  });

  /// Whether the backdrop is expanded, semantically
  final bool isOpen;

  /// Callback to trigger when the backdrop wants to change the open state
  final ValueChanged<bool> onOpenChanged;

  final AnimationController controller;

  BackdropController withListener(
    ValueChanged<bool> onOpenChangedListener,
  ) =>
      BackdropController(
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
      (other is BackdropController) &&
      controller == other.controller &&
      isOpen == other.isOpen &&
      onOpenChanged == other.onOpenChanged;
}
