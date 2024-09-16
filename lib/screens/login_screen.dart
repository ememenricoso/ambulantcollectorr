import 'package:ambulantcollector/reusable_widgets/reusable_widgets.dart';
import 'package:ambulantcollector/screens/dashboard.dart';
import 'package:ambulantcollector/screens/reser_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 226, 232, 227), // Set the background color of the container to green
    ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically if needed
              crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally if needed
              children: <Widget>[
                const Text(
                  "WELCOME TO \n CARBONRENT \n \n ", // Replace with your desired text
                  style: TextStyle(
                    fontSize: 35, // Adjust the font size as needed
                    color: Color.fromARGB(255, 10, 151, 10), // Change text color if necessary
                    fontWeight: FontWeight.bold, // Make text bold if needed
                  ),
                ),
                reusableTextField("Enter Email", Icons.person_outline, false,
                    _emailTextController),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Password", Icons.lock_outline, true,
                    _passwordTextController),
                const SizedBox(
                  height: 5,
                ),
                forgetPassword(context),
                firebaseUIButton(context, "Sign In", () {
                  _loginUser();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loginUser() {
    final email = _emailTextController.text;
    final password = _passwordTextController.text;

    // Sign in with Firebase Auth
    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .then((value) {
      // Store login information in Firestore
      FirebaseFirestore.instance.collection('user_ambulant').doc(value.user?.uid).set({
        'email': email,
        'loginTimestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Dashboard()));
      }).catchError((error) {
        print("Failed to add user: $error");
      });
    }).catchError((error) {
      _handleAuthError(error);
    });
  }

  void _handleAuthError(FirebaseAuthException error) {
    if (error.code == 'user-not-found') {
      _showErrorDialog("No user found for that email.");
    } else if (error.code == 'wrong-password') {
      _showErrorDialog("Wrong password provided.");
    } else if (error.code == 'too-many-requests') {
      _showErrorDialog("Access to this account has been temporarily disabled due to many failed login attempts. You can immediately restore it by resetting your password or you can try again later.");
    } else {
      _showErrorDialog("An error occurred: ${error.message}");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
          textAlign: TextAlign.right,
        ),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const ResetPassword())),
      ),
    );
  }
}
