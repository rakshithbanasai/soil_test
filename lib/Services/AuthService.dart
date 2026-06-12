import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/UserRegistration.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> registerUser(UserRegistration user) async {
    try {
      // 1. Create user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        // 2. Store additional details in Firestore using the Auth UID
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true, 'id': firebaseUser.uid};
      }

      return {'success': false, 'message': 'Registration failed.'};
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (e.g., email already in use)
      String message = 'An error occurred';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}