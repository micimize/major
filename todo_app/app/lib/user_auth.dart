import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart' show AuthLink;

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>['email', 'profile'],
);
final FirebaseAuth _auth = FirebaseAuth.instance;

FirebaseUser _currentUser;

Future<FirebaseUser> _googleToFirebase(GoogleSignInAccount googleUser) async {
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
  print("signed in " + user.displayName);
  return user;
}

Future<FirebaseUser> _handleSignIn() async =>
    _googleToFirebase(await _googleSignIn.signIn());

final _onUserChange = _auth.onAuthStateChanged.listen;

bool get isAuthenticated => _currentUser != null;

final googleSignInLink = AuthLink(getToken: () async {
  final token = (await _currentUser?.getIdToken()).token;
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
    _onUserChange((FirebaseUser account) {
      setState(() {
        _currentUser = account;
      });
    });
    _silentSignIn();
  }

  void _handleSignIn() async {
    try {
      await _handleSignIn();
    } catch (error) {
      print(error);
    }
  }

  void _silentSignIn() async => _googleToFirebase(
      await _googleSignIn.signInSilently(suppressErrors: true));

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
