import 'package:get_it/get_it.dart';
import '../interfaces/i_download_engine.dart';
import '../interfaces/i_python_service.dart';
import '../interfaces/i_queue_repository.dart';
import '../interfaces/i_settings_repository.dart';
import '../interfaces/i_tool_manager.dart';
import '../../services/python_service.dart';
import '../../services/queue_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/settings_service.dart';
import '../../services/engine/download_engine_provider.dart';
import '../../services/tools/tool_manager_service.dart';
import '../../viewmodels/settings_view_model.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Register Services
  // Use .instance to maintain singleton behavior consistently
  getIt.registerLazySingleton<IPythonService>(() => PythonService.instance);
  getIt.registerLazySingleton<IDownloadEngine>(
    () => DownloadEngineProvider.instance,
  );
  getIt.registerLazySingleton<IToolManager>(() => ToolManagerService());
  getIt.registerLazySingleton<IQueueRepository>(() => QueueService.instance);
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService.instance,
  );
  getIt.registerLazySingleton<ISettingsRepository>(
    () => SettingsService.instance,
  );

  // Register ViewModels
  getIt.registerFactory<SettingsViewModel>(
    () => SettingsViewModel(getIt<ISettingsRepository>()),
  );
}
