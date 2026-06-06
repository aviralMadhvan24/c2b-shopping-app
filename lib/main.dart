import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'config/production_settings.dart';
import 'repositories/app_repositories.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('=================================');
  debugPrint('Firebase Connected Successfully');
  debugPrint(
    'Project ID: ${Firebase.app().options.projectId}',
  );
  debugPrint('=================================');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.repositories = const AppRepositories(),
  });

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

      home: HomeScreen(
        repositories: repositories,
      ),
    );
  }
}