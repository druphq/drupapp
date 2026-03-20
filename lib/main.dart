import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Shorebird: silently install patches if available
  await _installShorebirdPatch();

  runApp(const ProviderScope(child: DrupApp()));
}

/// Checks for a Shorebird patch and downloads + installs it automatically.
/// Runs in a try/catch so it never blocks or crashes the app launch.
Future<void> _installShorebirdPatch() async {
  try {
    final updater = ShorebirdUpdater();

    if (!updater.isAvailable) return;

    final status = await updater.checkForUpdate();

    if (status == UpdateStatus.outdated) {
      await updater.update();
      // The patch will take effect on the next app restart.
    }
  } catch (_) {
    // Non-fatal — the app should launch normally even if the check fails
    // (e.g. no network, not a Shorebird-built binary, etc.).
  }
}

class DrupApp extends ConsumerWidget {
  const DrupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Drup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
