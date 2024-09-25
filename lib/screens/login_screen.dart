import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed:
            () {
          signInWithGoogle(context);
        },
            child: const Text('Login With Google')),
      ),
      // appBar: AppBar(
      //   title: Text('Login with Google '),
      //   backgroundColor: Color(0xFF673AB7), // Primary Color: Deep Purple
      // ),
      // body: Padding(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       // Email/Username Text Field
      //       TextField(
      //         decoration: InputDecoration(
      //           labelText: 'Email or Username',
      //           labelStyle: TextStyle(color: Color(0xFF757575)), // Secondary text color
      //           border: OutlineInputBorder(),
      //           focusedBorder: OutlineInputBorder(
      //             borderSide: BorderSide(color: Color(0xFF673AB7)), // Primary Color
      //           ),
      //         ),
      //       ),
      //       SizedBox(height: 16.0),
      //       // Password Text Field
      //       TextField(
      //         obscureText: true,
      //         decoration: InputDecoration(
      //           labelText: 'Password',
      //           labelStyle: TextStyle(color: Color(0xFF757575)), // Secondary text color
      //           border: OutlineInputBorder(),
      //           focusedBorder: OutlineInputBorder(
      //             borderSide: BorderSide(color: Color(0xFF673AB7)), // Primary Color
      //           ),
      //         ),
      //       ),
      //       SizedBox(height: 24.0),
      //       // Login Button
      //       ElevatedButton(
      //         onPressed: () {
      //           // Navigate to the Home screen upon successful login
      //           Navigator.pushReplacementNamed(context, '/home');
      //         },
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: Color(0xFF673AB7), // Updated to backgroundColor
      //           padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
      //         ),
      //         child: Text(
      //           'Login',
      //           style: TextStyle(color: Colors.white),
      //         ),
      //       ),
      //       SizedBox(height: 16.0),
      //       // Register Button
      //       TextButton(
      //         onPressed: () {
      //           // Navigate to the Register screen
      //           Navigator.pushNamed(context, '/register'); // Assuming register route is set up
      //         },
      //         child: Text(
      //           'Don\'t have an account? Register',
      //           style: TextStyle(color: Color(0xFF03A9F4)), // Secondary Color: Light Blue
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }


  signInWithGoogle(BuildContext context) async {
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);
    User? user = userCredential.user;

    // Check if the user is not null
    if (user != null) {
      // Get a reference to the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Check if the user already exists in the 'users' collection
      //DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        // Handle document if it exists
        if (!userDoc.exists) {
          // If the user does not exist in the Firestore, create a new document
          await firestore.collection('users').doc(user.uid).set({
            'displayName': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
            'birthdate': null, // You can update birthdate later if needed
          });
        }
      } catch (e) {
        print('Error fetching user document: $e');
        // Display error message to the user
      }



      // Navigate to the home screen after successful login
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}