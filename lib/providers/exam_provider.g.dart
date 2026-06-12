// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$examServiceHash() => r'bfa56ec9c1cefa47a4519c699c182848d5a0e5f0';

/// See also [examService].
@ProviderFor(examService)
final examServiceProvider = AutoDisposeProvider<ExamService>.internal(
  examService,
  name: r'examServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$examServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExamServiceRef = AutoDisposeProviderRef<ExamService>;
String _$activeExamsHash() => r'41ca90207d64cc076c6ba6c75caf5e18380e0bb3';

/// See also [activeExams].
@ProviderFor(activeExams)
final activeExamsProvider = AutoDisposeFutureProvider<List<Exam>>.internal(
  activeExams,
  name: r'activeExamsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeExamsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveExamsRef = AutoDisposeFutureProviderRef<List<Exam>>;
String _$teacherExamsHash() => r'4044087b3d25ae9f93b9ae1f6907bb50cf4ba825';

/// See also [teacherExams].
@ProviderFor(teacherExams)
final teacherExamsProvider = AutoDisposeFutureProvider<List<Exam>>.internal(
  teacherExams,
  name: r'teacherExamsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherExamsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TeacherExamsRef = AutoDisposeFutureProviderRef<List<Exam>>;
String _$currentExamHash() => r'2452ce3b516d29ce80d401b3f95ef582908a4737';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [currentExam].
@ProviderFor(currentExam)
const currentExamProvider = CurrentExamFamily();

/// See also [currentExam].
class CurrentExamFamily extends Family<AsyncValue<Exam?>> {
  /// See also [currentExam].
  const CurrentExamFamily();

  /// See also [currentExam].
  CurrentExamProvider call(String code) {
    return CurrentExamProvider(code);
  }

  @override
  CurrentExamProvider getProviderOverride(
    covariant CurrentExamProvider provider,
  ) {
    return call(provider.code);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentExamProvider';
}

/// See also [currentExam].
class CurrentExamProvider extends AutoDisposeFutureProvider<Exam?> {
  /// See also [currentExam].
  CurrentExamProvider(String code)
    : this._internal(
        (ref) => currentExam(ref as CurrentExamRef, code),
        from: currentExamProvider,
        name: r'currentExamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentExamHash,
        dependencies: CurrentExamFamily._dependencies,
        allTransitiveDependencies: CurrentExamFamily._allTransitiveDependencies,
        code: code,
      );

  CurrentExamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.code,
  }) : super.internal();

  final String code;

  @override
  Override overrideWith(
    FutureOr<Exam?> Function(CurrentExamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentExamProvider._internal(
        (ref) => create(ref as CurrentExamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        code: code,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Exam?> createElement() {
    return _CurrentExamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentExamProvider && other.code == code;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, code.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentExamRef on AutoDisposeFutureProviderRef<Exam?> {
  /// The parameter `code` of this provider.
  String get code;
}

class _CurrentExamProviderElement
    extends AutoDisposeFutureProviderElement<Exam?>
    with CurrentExamRef {
  _CurrentExamProviderElement(super.provider);

  @override
  String get code => (origin as CurrentExamProvider).code;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
