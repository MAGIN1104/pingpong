import 'package:get_it/get_it.dart';
import '../../features/game/data/repositories/shared_preferences_game_repository.dart';
import '../../features/game/domain/repositories/game_repository.dart';
import '../../features/game/presentation/bloc/game_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Repositories
  getIt.registerLazySingleton<GameRepository>(
    () => SharedPreferencesGameRepository(),
  );

  // BLoCs
  getIt.registerFactory<GameBloc>(() => GameBloc(getIt<GameRepository>()));
}
