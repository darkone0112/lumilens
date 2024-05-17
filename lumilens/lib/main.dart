import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart'; // Make sure to have HomeScreen imported

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LumiLensApp());
}

class LumiLensApp extends StatelessWidget {
  const LumiLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumiLens',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87, // Black transparent color for AppBar
          iconTheme: IconThemeData(color: Color.fromARGB(169, 255, 255, 255)), // Icon color
          titleTextStyle: TextStyle(color: Color.fromARGB(169, 255, 255, 255)), // Text color and size
        ),
        scaffoldBackgroundColor: Colors.black, // Background color for the entire app
      ),
      home: LandingPage(), // Use LandingPage to handle the initial screen based on authentication status
    );
  }
}

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          // Check if the snapshot has data which indicates there is an active session
          User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return HomeScreen(email: user.email ?? 'No Email'); // Assuming HomeScreen takes a 'email' parameter
        } else {
          // Show loading indicator while waiting for auth data
          return Scaffold(
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
