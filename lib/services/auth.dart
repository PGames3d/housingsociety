import 'package:firebase_auth/firebase_auth.dart';
import 'package:housingsociety/models/user.dart';
import 'package:housingsociety/services/database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseService db = DatabaseService();

  CurrentUser? _userFromFireBase(User? user) {
    return user != null
        ? CurrentUser(
            uid: user.uid,
            email: user.email ?? "",
            name: user.displayName ?? "",
            profilePicture: user.photoURL ?? "")
        : null;
  }

  Stream<CurrentUser?> get user {
    return _auth.userChanges().map(_userFromFireBase);
  }

  Future createUserWithEmailAndPassword(String email, String password,
      String name, String wing, String flatno) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      userCredential.user?.updateProfile(displayName: name).then((_) {
        User? user = _auth.currentUser;
        user?.reload();
        User? updateduser = _auth.currentUser;
        print(updateduser?.displayName);
        db.setProfileonRegistration(user?.uid, name, wing, flatno);
        return _userFromFireBase(updateduser);
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        return null;
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future logInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      return _userFromFireBase(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        return null;
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  String userName() {
    final User? user = _auth.currentUser;
    return user?.displayName ?? "";
  }

  String userId() {
    final User? user = _auth.currentUser;
    return user?.uid ?? "";
  }

  Future signOut() async {
    await _auth.signOut();
    return null;
  }

  Future updateDisplayName(updatedName) async {
    _auth.currentUser?.updateProfile(
      displayName: updatedName,
    )
        .then((_) {
      User? user = _auth.currentUser;
      user?.reload();
      User? updateduser = _auth.currentUser;
      return _userFromFireBase(updateduser);
    });
    return userName();
  }

  Future updateProfilePicture(updatedProfilePicture) async {
    _auth.currentUser?.updateProfile(
      photoURL: updatedProfilePicture,
    );
    return _userFromFireBase(_auth.currentUser);
  }

  Future<String> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No user is currently signed in.';
      }

      // Re-authenticate the user with current email and password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update the email
      await user.updateEmail(newEmail);

      // Re-authenticate again (optional, can be removed if not needed)
      final newCredential = EmailAuthProvider.credential(
        email: newEmail,
        password: password,
      );
      await user.reauthenticateWithCredential(newCredential);

      return 'Email updated successfully';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is invalid.';
      } else if (e.code == 'requires-recent-login') {
        return 'Please re-authenticate and try again.';
      } else {
        return 'FirebaseAuth error: ${e.message}';
      }
    } catch (e) {
      print(e);
      return 'An unexpected error occurred. Please try again.';
    }
  }


  Future<String> updatePassword(String oldPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return 'No user is currently signed in.';
      }

      // Re-authenticate with old password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);

      // (Optional) Re-authenticate with the new password
      final newCredential = EmailAuthProvider.credential(
        email: user.email!,
        password: newPassword,
      );

      await user.reauthenticateWithCredential(newCredential);

      return 'Password updated successfully';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'The old password is incorrect.';
        case 'weak-password':
          return 'The new password is too weak.';
        case 'requires-recent-login':
          return 'Please re-authenticate and try again.';
        default:
          return 'Firebase error: ${e.message}';
      }
    } catch (e) {
      print('Unexpected error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }


  Future? delteAccount() {
    _auth.signOut();
    return _auth.currentUser?.delete();
  }
}
