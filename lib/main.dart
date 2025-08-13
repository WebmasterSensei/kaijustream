import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:KaijuStream/src/auth/auth_provider.dart';
import 'package:KaijuStream/src/auth/login_screen.dart';
import 'package:KaijuStream/src/screens/home_screen.dart';
import 'package:KaijuStream/src/widgets/search/anime-details.dart';
import 'package:provider/provider.dart';

final storage = FlutterSecureStorage();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

Future<bool> _hasToken() async {
  final token = await storage.read(key: 'auth_token');
  return token != null && token.isNotEmpty;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Panda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red, fontFamily: 'Poppins'),

      // Define routes here
      routes: {
        '/anime-details': (context) => AnimeDetailsPage(), // <-- new route
      },

      home: FutureBuilder<bool>(
        future: _hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final loggedIn = snapshot.data == true;
          return loggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

