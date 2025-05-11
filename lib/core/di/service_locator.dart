import 'package:get_it/get_it.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/reports/services/report_service.dart';
import '../../features/reports/viewmodels/report_viewmodel.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // Репозитории
    // sl.registerLazySingleton<SomeRepository>(() => SomeRepositoryImpl());

    // Сервисы
    sl.registerLazySingleton<AuthService>(() => AuthService());
    sl.registerLazySingleton<ReportService>(() => ReportService());

    // ViewModels
    sl.registerFactory<AuthViewModel>(
      () => AuthViewModel(sl<AuthService>()),
    );
    sl.registerFactory<ReportViewModel>(
      () => ReportViewModel(),
    );
  }
} 