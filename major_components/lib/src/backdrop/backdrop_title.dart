import 'package:flutter/material.dart';

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
