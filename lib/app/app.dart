import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../data/account_state.dart';
import '../data/settings_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'router.dart';

/// Root widget — sets up theme, locale, and router.
class MasterJiApp extends StatefulWidget {
  const MasterJiApp({super.key});

  @override
  State<MasterJiApp> createState() => _MasterJiAppState();
}

class _MasterJiAppState extends State<MasterJiApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(context.read<AccountState>());
  }

  @override
  Widget build(BuildContext context) {
    // Watch SettingsStore (now a ChangeNotifier) — rebuilds when language changes
    final settings = context.watch<SettingsStore>();
    final locale = Locale(settings.languageCode);

    return MaterialApp.router(
      title: 'MasterJi',
      debugShowCheckedModeBanner: kDebugMode,
      theme: AppTheme.light,
      routerConfig: _appRouter.router,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('or'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Fallback for locales not fully supported by Material (e.g. 'or')
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return const Locale('en');
        for (final s in supported) {
          if (s.languageCode == locale.languageCode) return s;
        }
        return const Locale('en');
      },
    );
  }
}
