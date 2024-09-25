import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> _getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }

  Future<void> _updateBirthdate(String birthdate) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'birthdate': birthdate,
      });
    }
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      String formattedDate = "${selectedDate.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      await _updateBirthdate(formattedDate);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Birthday updated to $formattedDate'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user is logged in'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching user info'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('User info not found'));
        }

        Map<String, dynamic>? userInfo = snapshot.data;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.photoURL != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL!),
                  radius: 50,
                ),
              const SizedBox(height: 20),
              Text('Name: ${user.displayName}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text('Email: ${user.email}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              if (userInfo != null && userInfo['birthdate'] != null) ...[
                Text('Birthdate: ${userInfo['birthdate']}', style: const TextStyle(fontSize: 16)),
              ] else ...[
                Text('Birthdate not set', style: const TextStyle(fontSize: 16)),
                ElevatedButton(
                  onPressed: () => _selectBirthdate(context),
                  child: const Text('Set Birthday'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
