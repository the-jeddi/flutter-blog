import 'package:flutter_blog/features/profile/repositories/profile_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_blog/features/auth/repositories/auth_repository.dart';

final locator = GetIt.instance;

void configureDependencies() {
  // Register the Supabase client as a singleton
  locator.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Register Lazy Singletons
  // Register AuthRepository
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(client: locator<SupabaseClient>()),
  );
  // Register ProfileRepository
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(client: locator<SupabaseClient>()),
  );
}
