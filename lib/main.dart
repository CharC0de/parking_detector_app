import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:firebase_core/firebase_core.dart";
import 'firebase_options.dart';
import 'utilities/server_util.dart';
import 'register.dart';
import 'dashboard.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  bool error = false;
  Map<String, dynamic> userFormData = {
    'email': '',
    'password': '',
  };

  Future<void> loginUser(String email, String password, context) async {
    try {
      var userCredential = await userRef.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        debugPrint("login success");
        var result = await dbref.child('users/${user.uid}').get();
        if (result.value != null) {
          final userData =
              (result.value as Map<dynamic, dynamic>).cast<String, dynamic>();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => Dashboard(userData: userData)));
          debugPrint('$userData');
        } else {
          setState(() {
            error = true;
          });
        }
      } else {
        setState(() {
          error = true;
        });
      }
    } catch (e) {
      Navigator.of(context).pop();
      debugPrint("Error while logging in: $e");
      setState(() {
        error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/Logo.png',
                        fit: BoxFit.cover,
                        cacheHeight: 250,
                        cacheWidth: 250,
                      ),
                    ),
                    const Text(
                      'Login',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              onSaved: (newValue) {
                                userFormData['email'] = newValue;
                              },
                              decoration: const InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)))),
                              validator: (value) {
                                return value == null || value == ""
                                    ? "Please Input Your Email "
                                    : null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextFormField(
                              obscureText: true,
                              onSaved: (newValue) {
                                userFormData['password'] = newValue;
                              },
                              decoration: const InputDecoration(
                                  labelText: "Password",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)))),
                              validator: (value) {
                                return value == null || value == ""
                                    ? "Please Input Your Password "
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            loginUser(userFormData['email'],
                                userFormData['password'], context);
                          }
                        },
                        child: const Text("Login")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const Register()));
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "New to ParkEase? ",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        )),
                    Visibility(
                        visible: error,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'Invalid Credentials',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ))
                  ],
                ),
              ))),
    );
  }
}
