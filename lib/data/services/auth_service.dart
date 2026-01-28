import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

/// Google Sign-In result containing user data for API authentication
class GoogleSignInResult {
  final String idToken;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;

  GoogleSignInResult({
    required this.idToken,
    this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
  });
}

class ExternalAuthService {
  User? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Sign in with Google
  Future<GoogleSignInResult?> loginWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google Sign-In cancelled by user');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null) {
        print('Failed to get Google ID token');
        return null;
      }

      // Parse name into first and last name
      String? firstName;
      String? lastName;
      final displayName = googleUser.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        final nameParts = displayName.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      return GoogleSignInResult(
        idToken: idToken,
        email: googleUser.email,
        firstName: firstName,
        lastName: lastName,
        profileImage: googleUser.photoUrl,
      );
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out error: $e');
    }
  }

  /// Check if user is signed in with Google
  Future<bool> isGoogleSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    await signOutGoogle();
  }

  /// Get current user
  User? getCurrentUser() {
    return _currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }
}
