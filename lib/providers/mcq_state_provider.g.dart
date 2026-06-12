// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcq_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mcqAnswersHash() => r'a559bc8744eefbd7884c5a36f25ca24bdefe5123';

/// See also [McqAnswers].
@ProviderFor(McqAnswers)
final mcqAnswersProvider =
    AutoDisposeNotifierProvider<McqAnswers, Map<String, String>>.internal(
      McqAnswers.new,
      name: r'mcqAnswersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mcqAnswersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$McqAnswers = AutoDisposeNotifier<Map<String, String>>;
String _$mcqTimerHash() => r'27932f39d9cf002e5fae7c45df3696782b128f3e';

/// See also [McqTimer].
@ProviderFor(McqTimer)
final mcqTimerProvider = AutoDisposeNotifierProvider<McqTimer, int>.internal(
  McqTimer.new,
  name: r'mcqTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mcqTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$McqTimer = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
