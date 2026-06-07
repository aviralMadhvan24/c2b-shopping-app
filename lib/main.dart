import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'config/production_settings.dart';
import 'repositories/app_repositories.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'data/product_seeder.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed demo products if the database is empty
  await ProductSeeder.seedProducts();

  debugPrint('=================================');
  debugPrint('Firebase Connected Successfully');
  debugPrint(
    'Project ID: ${Firebase.app().options.projectId}',
  );
  debugPrint('=================================');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    AppRepositories? repositories,
  }) : repositories = repositories ?? AppRepositories();

  final AppRepositories repositories;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ProductionSettings.appTitle,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          AppTheme.darkTheme.textTheme,
        ),
      ),

      home: StreamBuilder<User?>(
        stream: repositories.authRepository.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return HomeScreen(repositories: repositories);
          }

          return LoginScreen(repositories: repositories);
        },
      ),
    );
  }
}