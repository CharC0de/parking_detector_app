import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'utilities/util.dart';
import 'utilities/server_util.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  var success = false;
  final pcon = TextEditingController();
  final confcon = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> registerFormData = {'type': "regular"};

  File? _image;

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        registerFormData["pfp"] = pickedFile.path.split('/').last;
        debugPrint(registerFormData["pfp"]);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        registerFormData["pfp"] = pickedFile.path.split('/').last;
        debugPrint(registerFormData["pfp"]);
      });
    }
  }

  AlertDialog choosePfpPopup(BuildContext context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        title: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text("Upload Picture"),
              GestureDetector(
                  onTap: () => Navigator.pop(context, 'exit'),
                  child: Icon(Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.primary))
            ])),
        content: const Text("How would you like to take your picture"),
        actions: [
          FilledButton(
            onPressed: () {
              _takePicture();
              Navigator.pop(context, 'exit');
            },
            child: const Text('Take Picture'),
          ),
          FilledButton(
            onPressed: () {
              _pickImage();
              Navigator.pop(context, 'exit');
            },
            child: const Text('Choose Picture'),
          ),
        ],
      );

  Future<void> uploadImage(String folder, File? file, String fileName) async {
    try {
      await storageRef.child("$folder/$fileName").putFile(file!);
      debugPrint('File uploaded to Firestore in folder: $folder');
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }
  }

  UserCredential? userCredential;
  Future<bool> registerUser(String email, String password) async {
    try {
      userCredential = await userRef.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint(userCredential!.user!.uid);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      if (e is FirebaseAuthException) {
        if (context.mounted) {
          Navigator.of(context).pop();
          showDialog(
              context: context,
              builder: (context) => e.code == 'email-already-in-use'
                  ? const AlertDialog(
                      title: Text('Email is Already in Use'),
                      content: Text(
                          'Email address is already in use. Please choose another one.'),
                    )
                  : const AlertDialog(
                      title: Text('Error Has Occured'),
                      content: Text('Please call the Administrator'),
                    ));
        }
        return false;
      }
    }
    return true;
  }

  Future<void> saveUserData(String user, Map<String, dynamic> userData) async {
    try {
      debugPrint(user);
      await dbref.child("users").child(user).set(userData);
      debugPrint("Data saved successfully");
    } catch (e) {
      debugPrint("Error while saving data: $e");
      // You can handle the error here, e.g., show an error message to the user.
    }
  }

  Future<void> registerUserWithProfile(
      Map<String, dynamic> registerFormData) async {
    final email = registerFormData["email"];
    final password = registerFormData["password"];

    final userData = {
      "username": registerFormData["username"],
      "first_name": registerFormData["firstName"],
      "last_name": registerFormData["lastName"],
      "pfp": registerFormData["pfp"],
      "type": registerFormData["type"],
    };
    if (await registerUser(email, password)) {
      try {
        debugPrint("id:${userCredential!.user!.uid} data $userData");
        await saveUserData(userCredential!.user!.uid, userData);
        if (userData["pfp"] != null) {
          uploadImage(
              userCredential!.user!.uid, _image, registerFormData["pfp"]);
        }
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        setState(() {
          _formKey.currentState!.reset();
          pcon.clear();
          confcon.clear();

          setState(() {
            _image = null;
            success = true;
          });

          debugPrint(registerFormData.toString());
        });
      }
    }
  }

  Widget textInput({required String formName, required String label}) {
    String? Function(String?) validator = (value) {
      return value == null || value == "" ? "Please Input Your $label " : null;
    };

    switch (label) {
      case 'Email':
        validator = (value) {
          return value == null || value == ""
              ? "Please Input Your $label "
              : !isEmailValidated(value)
                  ? "Email structure is invalid"
                  : null;
        };
        break;
      case 'Username':
        validator = (value) {
          return value == null || value == ""
              ? "Please Input Your $label "
              : !isUsernameValidated(value)
                  ? "Username must not have unnecessary symbols"
                  : null;
        };

        break;

      default:
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: TextFormField(
        onSaved: (newValue) {
          registerFormData[formName] = newValue;
        },
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)))),
        validator: validator,
      ),
    );
  }

  Widget passInput({required String formName, required String label}) {
    dynamic controller = pcon;
    void Function(String?) onSaved = (newValue) {
      registerFormData[formName] = newValue;
    };
    String? Function(String?) validator = (value) {
      return value == null || value == ""
          ? "Please Input Your $label "
          : value.length < 6
              ? "Password must at least be 6 characters long"
              : pcon.text != value
                  ? "Passwords do not match"
                  : null;
    };

    switch (label) {
      case 'Confirm Password':
        onSaved = (newValue) {};
        controller = confcon;
        validator = (value) {
          return value == null || value == ""
              ? "Please Input Your $label"
              : pcon.text != value
                  ? "Passwords do not match"
                  : null;
        };
        break;

      default:
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: TextFormField(
        obscureText: true,
        controller: controller,
        onSaved: onSaved,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)))),
        validator: validator,
      ),
    );
  }

  AlertDialog confirmRegisterPopup(BuildContext context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        title: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text("Confirm Register"),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.primary))
            ])),
        content:
            const Text("Are you sure you want to finalize the registration?"),
        actions: [
          FilledButton(
            onPressed: () {
              _formKey.currentState!.save();
              registerUserWithProfile(registerFormData);
              debugPrint(registerFormData.toString());
              Navigator.pop(context);
            },
            child: const Text('Yes'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
        ),
        body: Center(
            child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                  key: _formKey,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * .75,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(20),
                              child: _image != null
                                  ? TextButton(
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all(
                                              const CircleBorder())),
                                      onPressed: () {
                                        setState(() {
                                          _image = null;
                                          registerFormData['pfp'] = '';
                                        });
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: CircleAvatar(
                                            radius: 100,
                                            backgroundImage:
                                                FileImage(_image!, scale: 50),
                                          )))
                                  : Icon(Icons.account_circle,
                                      size: 100,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                          Row(
                            children: [
                              Expanded(
                                  child: textInput(
                                      formName: 'firstName',
                                      label: 'First Name')),
                              Expanded(
                                  child: textInput(
                                      formName: 'lastName',
                                      label: 'Last Name')),
                            ],
                          ),
                          textInput(formName: 'username', label: 'Username'),
                          textInput(formName: 'email', label: 'Email'),
                          passInput(formName: 'password', label: 'Password'),
                          passInput(
                              formName: 'password', label: 'Confirm Password'),
                          FilledButton(
                            onPressed: () => showDialog<String>(
                                context: context,
                                builder: (context) => choosePfpPopup(context)),
                            child: const Text(
                              'Take a Profile Photo',
                            ),
                          ),
                          FilledButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  showDialog(
                                      context: context,
                                      builder: (context) =>
                                          confirmRegisterPopup(context));
                                }
                              },
                              child: const Text(
                                "Register",
                              )),
                          Visibility(
                              visible: success,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  'Registration Success',
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                              ))
                        ]),
                  ))
            ],
          ),
        )));
  }
}
