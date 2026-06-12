// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userRoleHash() => r'715d45621964578aaacb2a118bd0b15dfe0aae7a';

/// See also [userRole].
@ProviderFor(userRole)
final userRoleProvider = AutoDisposeFutureProvider<UserRole>.internal(
  userRole,
  name: r'userRoleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRoleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRoleRef = AutoDisposeFutureProviderRef<UserRole>;
String _$authHash() => r'cb0cee802d53edc945a4cc36939f90e2b740e732';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider = AutoDisposeNotifierProvider<Auth, User?>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = AutoDisposeNotifier<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
