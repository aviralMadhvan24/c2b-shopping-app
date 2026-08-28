import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'config/production_settings.dart';
import 'repositories/app_repositories.dart';
import 'providers/pagination_provider.dart';
import 'widgets/auth_gate.dart';

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

  // Construct the repositories once for the whole app. Rebuilding them per
  // widget build would re-initialise GoogleSignIn on every frame.
  final repositories = AppRepositories();

  runApp(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          repositories.productRepository,
        ),
      ],
      child: MyApp(repositories: repositories),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.repositories,
  });

  final AppRepositories? repositories;

  @override
  Widget build(BuildContext context) {
    final repos = repositories ?? AppRepositories();
    return MaterialApp(
      title: ProductionSettings.appTitle,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          AppTheme.darkTheme.textTheme,
        ),
      ),

      home: AuthGate(repositories: repos),
    );
  }
}
