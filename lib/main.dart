import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/widgets/splash_wrapper.dart';
import 'shared/providers/theme_provider.dart';

Future<void> _loadGoogleSansFont() async {
  try {
    final fontLoader = FontLoader('GoogleSans');
    fontLoader.addFont(rootBundle.load('assets/fonts/GoogleSans-Regular.ttf'));
    fontLoader.addFont(rootBundle.load('assets/fonts/GoogleSans-Medium.ttf'));
    fontLoader.addFont(rootBundle.load('assets/fonts/GoogleSans-SemiBold.ttf'));
    fontLoader.addFont(rootBundle.load('assets/fonts/GoogleSans-Bold.ttf'));
    await fontLoader.load();

    final fontLoaderSpaced = FontLoader('Google Sans');
    fontLoaderSpaced.addFont(rootBundle.load('assets/fonts/GoogleSans-Regular.ttf'));
    fontLoaderSpaced.addFont(rootBundle.load('assets/fonts/GoogleSans-Medium.ttf'));
    fontLoaderSpaced.addFont(rootBundle.load('assets/fonts/GoogleSans-SemiBold.ttf'));
    fontLoaderSpaced.addFont(rootBundle.load('assets/fonts/GoogleSans-Bold.ttf'));
    await fontLoaderSpaced.load();
  } catch (e) {
    debugPrint('Google Sans FontLoader: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadGoogleSansFont();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'TVR',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontFamilyFallback: AppTheme.fontFallbacks,
            letterSpacing: 0,
          ),
          child: SplashWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
