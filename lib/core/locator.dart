import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/repositories/auth_repository.dart';

final locator = GetIt.instance;

void configureDependencies() {
  // Register the Supabase client as a singleton
  locator.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Register AuthRepository as a lazy singleton
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(client: locator<SupabaseClient>()),
  );
}
