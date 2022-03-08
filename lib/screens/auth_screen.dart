import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/http_exception.dart';
import '../providers/auth.dart';

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
              colors: [
                Color.fromRGBO(215, 117, 255, 1).withOpacity(0.5),
                Color.fromRGBO(255, 188, 117, 1).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0, 1],
            )),
          ),
          SingleChildScrollView(
            child: Container(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 94),
                      transform: Matrix4.rotationZ(-10 * pi / 180)
                        ..translate(-5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.deepOrange.shade900,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'My Shop',
                        style: TextStyle(
                          color:
                              Theme.of(context).accentTextTheme.headline6.color,
                          fontSize: 50,
                          fontFamily: 'Anton',
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: deviceSize.width > 600 ? 2 : 1,
                    child: AuthCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  @override
  _AuthCardState createState() => _AuthCardState();
}

enum AuthMode { Login, SingUp }

class _AuthCardState extends State<AuthCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();
  AnimationController _controller;
  Animation<Offset> _slideAnimation;
  Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.15),
      end: Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    _formKey.currentState.save();
    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        await Provider.of<Auth>(context, listen: false)
            .login(_authData['email'], _authData['password']);
      } else {
        await Provider.of<Auth>(context, listen: false)
            .signUp(_authData['email'], _authData['password']);
      }
    } on HttpException catch (error) {
      var errorMessage = 'Authentication failed';
      if (error.toString().contains('EMAIL_EXISTS')) {
        errorMessage =
            'The email address is already in use by another account.';
      } else if (error.toString().contains('INVALID_EMAIL')) {
        errorMessage = 'The email address is badly formatted.';
      } else if (error.toString().contains('WEAK_PASSWORD')) {
        errorMessage = 'The password must be 6 characters long or more.';
      } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
        errorMessage =
            'There is no user record corresponding to this identifier. The user may have been deleted.';
      } else if (error.toString().contains('INVALID_PASSWORD')) {
        errorMessage =
            'The password is invalid or the user does not have a password.';
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage = 'Could\'t Authenticate. Please try again later.';
      _showErrorDialog(errorMessage);
      print(error);
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Ann Error Occurred!'),
              content: Text(message),
              actions: [
                FlatButton(
                  child: Text('Okay!'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ));
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.SingUp;
      });
      _controller.forward();
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 8.0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
        height: _authMode == AuthMode.SingUp ? 320 : 260,
        constraints:
            BoxConstraints(minHeight: _authMode == AuthMode.SingUp ? 320 : 260),
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val.isEmpty || !val.contains('@')) {
                        return 'Invail Email';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      _authData['email'] = val;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    controller: _passwordController,
                    validator: (val) {
                      if (val.isEmpty || val.length < 5) {
                        return 'Password is too short';
                      }
                      return null;
                    },
                    onSaved: (val) {
                      _authData['password'] = val;
                    },
                  ),
                  AnimatedContainer(
                    constraints: BoxConstraints(
                      minHeight: _authMode == AuthMode.SingUp ? 60 : 0,
                      maxHeight: _authMode == AuthMode.SingUp ? 120 : 0,
                    ),
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: TextFormField(
                          enabled: _authMode == AuthMode.SingUp,
                          decoration:
                              InputDecoration(labelText: 'Confirm Password'),
                          obscureText: true,
                          validator: _authMode == AuthMode.SingUp
                              ? (val) {
                                  if (val != _passwordController.text) {
                                    return 'Password don\'t Match';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_isLoading) CircularProgressIndicator(),
                  RaisedButton(
                    child:
                        Text(_authMode == AuthMode.Login ? 'Login' : 'Sign Up'),
                    onPressed: _submit,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    color: Theme.of(context).primaryColor,
                    textColor:
                        Theme.of(context).primaryTextTheme.headline6.color,
                  ),
                  FlatButton(
                    child: Text(
                        '${_authMode == AuthMode.Login ? 'Sign Up' : 'Login'}'),
                    onPressed: _switchAuthMode,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 4),
                    textColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
