import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/admin_providers.dart';
import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'services/admin_auth_service.dart';
import 'theme/admin_theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: NiyatiAdminApp()));
}

class NiyatiAdminApp extends StatelessWidget {
  const NiyatiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niyati Mart Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      home: const _AdminGate(),
    );
  }
}

/// Two gates, not one: Firebase Auth says who you are, the `admins` collection
/// says whether you may be here. Both have to pass before the console renders,
/// and the same pair is enforced by the Firestore rules on every read.
class _AdminGate extends ConsumerStatefulWidget {
  const _AdminGate();

  @override
  ConsumerState<_AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends ConsumerState<_AdminGate> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const _Splash(),
      error: (e, _) => Scaffold(body: ErrorPanel(error: e)),
      data: (user) {
        if (user == null) return const LoginScreen();

        final adminAsync = ref.watch(currentAdminProvider);
        return adminAsync.when(
          loading: () => const _Splash(message: 'Checking your access…'),
          // A denied read of `admins/{uid}` is itself the answer: not an admin.
          error: (e, _) => NotAuthorisedScreen(
            uid: user.uid,
            email: user.email ?? '',
          ),
          data: (admin) {
            if (admin == null || !admin.active) {
              return NotAuthorisedScreen(
                uid: user.uid,
                email: user.email ?? '',
              );
            }
            return _SeededShell(admin: admin);
          },
        );
      },
    );
  }
}

/// Plants the default sections on the first admin sign-in, then shows the
/// console. Seeding lives behind the admin gate so an unauthorised visitor can
/// never trigger a write, and it is fire-and-forget: a failure here must not
/// keep the owner out of their own store.
class _SeededShell extends ConsumerStatefulWidget {
  const _SeededShell({required this.admin});

  final AdminUser admin;

  @override
  ConsumerState<_SeededShell> createState() => _SeededShellState();
}

class _SeededShellState extends ConsumerState<_SeededShell> {
  @override
  void initState() {
    super.initState();
    ref.read(sectionServiceProvider).ensureSeeded().catchError((Object e) {
      debugPrint('Section seeding skipped: $e');
    });
  }

  @override
  Widget build(BuildContext context) => AdminShell(admin: widget.admin);
}

class _Splash extends StatelessWidget {
  const _Splash({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.sidebar,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.storefront, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 22),
            const Text(
              'Niyati Mart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: Color(0xFF8FA6C9), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
