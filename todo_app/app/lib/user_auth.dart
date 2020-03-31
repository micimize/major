import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:graphql_flutter/graphql_flutter.dart' show AuthLink;

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>['email', 'profile'],
);

GoogleSignInAccount _currentUser;

final _onUserChange = _googleSignIn.onCurrentUserChanged.listen;

bool get isAuthenticated => _currentUser != null;

Future<String> get _token async {
  final auth = await _googleSignIn.currentUser?.authentication;
  return auth?.idToken;
}

final googleSignInLink = AuthLink(getToken: () async {
  final token = await _token;
  return 'Bearer $token';
});

class AuthenticationProvider extends StatefulWidget {
  AuthenticationProvider({@required this.child});

  final Widget child;

  @override
  _AuthenticationProviderState createState() => _AuthenticationProviderState();

  static Map<String, WidgetBuilder> forRoutes(
      Map<String, WidgetBuilder> routes) {
    return routes.map((key, builder) {
      return MapEntry(
        key,
        (BuildContext context) => AuthenticationProvider(
          child: builder(context),
        ),
      );
    });
  }
}

class _AuthenticationProviderState extends State<AuthenticationProvider> {
  @override
  void initState() {
    super.initState();
    _onUserChange((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently(suppressErrors: true);
  }

  void _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Widget get signInPage => Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign In'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            const Text("You are not currently signed in."),
            RaisedButton(
              onPressed: _handleSignIn,
              child: const Text('SIGN IN'),
            ),
          ],
        ),
      ));

  @override
  Widget build(BuildContext context) {
    return isAuthenticated ? widget.child : signInPage;
  }
}

class SignOut extends StatelessWidget {
  SignOut();

  void _handleSignOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: _handleSignOut,
      child: const Text('SIGN OUT'),
    );
  }
}

class CopyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () async {
        final auth = await _googleSignIn.currentUser.authentication;
        return Clipboard.setData(ClipboardData(
          text: auth.idToken,
        ));
      },
      child: const Text('COPY TOKEN'),
    );
  }
}
