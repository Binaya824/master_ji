import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/account_state.dart';
import '../data/local_repository.dart';
import '../data/settings_store.dart';
import '../services/auth_service.dart';
import '../services/mock_auth_service.dart';
import '../services/mock_scan_service.dart';
import '../services/scan_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise settings store (SharedPreferences)
  final settingsStore = await SettingsStore.create();

  runApp(
    MultiProvider(
      providers: [
        // Settings/locale — ChangeNotifier so language switches rebuild the app
        ChangeNotifierProvider<SettingsStore>.value(value: settingsStore),

        // Account state
        ChangeNotifierProvider<AccountState>(
          create: (_) => AccountState(settingsStore),
        ),

        // Local data repository
        Provider<LocalRepository>(
          create: (_) => LocalRepository(),
        ),

        // Services — swap MockScanService / MockAuthService for real ones here
        Provider<ScanService>(
          create: (_) => MockScanService(),
        ),
        Provider<AuthService>(
          create: (_) => MockAuthService(),
        ),
      ],
      child: const MasterJiApp(),
    ),
  );
}
