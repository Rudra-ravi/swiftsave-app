import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'utils/simple_theme.dart';
import 'core/di/service_locator.dart';
import 'services/background_service.dart';
import 'services/engine/download_engine_provider.dart';
import 'services/queue_service.dart';
import 'services/settings_service.dart';
import 'services/download/notification_manager.dart';
import 'screens/onboarding/setup_wizard_screen.dart';

/// Tracks critical service initialization errors to show to user
class ServiceInitializationState {
  static String? initializationError;
  static bool get hasError => initializationError != null;
}

void main() async {
  // Add global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack Trace: ${details.stack}');
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      String? notificationError;
      try {
        await NotificationManager.initialize();
      } catch (e, stack) {
        debugPrint('Notification initialization error: $e');
        debugPrint('Stack trace: $stack');
        notificationError = 'Notifications failed to initialize';
      }

      // Initialize Dependency Injection
      await configureDependencies();

      // Get singleton instances (same instances that are registered in DI)
      final queueService = QueueService.instance;
      final settingsService = SettingsService.instance;

      // Initialize services with proper error tracking
      final List<String> initErrors = [];
      if (notificationError != null) {
        initErrors.add(notificationError);
      }

      // Critical services - track errors
      try {
        await DownloadEngineProvider.instance.initialize();
      } catch (e, stack) {
        debugPrint('Download engine initialization error: $e');
        debugPrint('Stack trace: $stack');
        initErrors.add('Download engine failed to initialize');
      }

      try {
        await BackgroundDownloadService.initialize();
      } catch (e, stack) {
        debugPrint('Background service initialization error: $e');
        debugPrint('Stack trace: $stack');
        initErrors.add('Background download service failed');
      }

      try {
        await queueService.initialize();
      } catch (e, stack) {
        debugPrint('Queue service initialization error: $e');
        debugPrint('Stack trace: $stack');
        initErrors.add('Download queue failed to initialize');
      }

      try {
        await settingsService.initialize();
      } catch (e, stack) {
        debugPrint('Settings service initialization error: $e');
        debugPrint('Stack trace: $stack');
        // Settings failure is recoverable - will use defaults
      }

      // Store error for UI to display
      if (initErrors.isNotEmpty) {
        ServiceInitializationState.initializationError = initErrors.join('\n');
      }

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: queueService),
            ChangeNotifierProvider.value(value: settingsService),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught Error: $error');
      debugPrint('Stack Trace: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home = const SetupWizardScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'SwiftSave',
          debugShowCheckedModeBanner: false,
          theme: SimpleTheme.lightTheme(),
          darkTheme: SimpleTheme.darkTheme(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
          builder: (context, child) {
            // Show error dialog on first build if initialization failed
            if (ServiceInitializationState.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final error = ServiceInitializationState.initializationError;
                ServiceInitializationState.initializationError =
                    null; // Clear to prevent repeat
                if (error != null && context.mounted) {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Initialization Error'),
                        ],
                      ),
                      content: Text(
                        'Some services failed to start:\n\n$error\n\nThe app may not function correctly.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Continue Anyway'),
                        ),
                      ],
                    ),
                  );
                }
              });
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
