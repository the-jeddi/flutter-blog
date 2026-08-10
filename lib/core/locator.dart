import 'package:flutter_blog/features/comments/repositories/comment_repository.dart';
import 'package:flutter_blog/features/posts/repositories/post_repository.dart';
import 'package:flutter_blog/features/profile/repositories/profile_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_blog/features/auth/repositories/auth_repository.dart';

final locator = GetIt.instance;

void configureDependencies() {
  // Register the Supabase client as a singleton
  locator.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Register Lazy Singletons
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(client: locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(client: locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<PostRepository>(
    () => PostRepository(client: locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<CommentRepository>(
    () => CommentRepository(client: locator<SupabaseClient>()),
  );
}
