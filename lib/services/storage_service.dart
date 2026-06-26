import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadWrittenQuestion(String examId, Uint8List bytes, String ext) async {
    final fileName = '${_uuid.v4()}.$ext';
    final path = '${_supabase.auth.currentUser!.id}/$examId/$fileName';

    await _supabase.storage
        .from('written-questions')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _supabase.storage
        .from('written-questions')
        .getPublicUrl(path);
  }

  Future<String> uploadWrittenAnswer(String submissionId, int page, Uint8List bytes, String ext) async {
    final fileName = 'page_$page.$ext';
    final path = '$submissionId/$fileName';

    await _supabase.storage
        .from('written-answers')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _supabase.storage
        .from('written-answers')
        .getPublicUrl(path);
  }
  Future<String> uploadGradedAnswer(String answerId, Uint8List bytes) async {
    final fileName = 'graded_$answerId.png';
    final path = 'graded/$fileName';

    await _supabase.storage
        .from('written-answers')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _supabase.storage
        .from('written-answers')
        .getPublicUrl(path);
  }

  /// Deletes a file from storage given its full public URL.
  Future<void> deleteFileByUrl(String publicUrl) async {
    // Public URLs have the format: .../storage/v1/object/public/<bucket>/<path>
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;

    // Find 'public' segment, bucket is next, rest is the path
    final publicIndex = segments.indexOf('public');
    if (publicIndex < 0 || publicIndex + 1 >= segments.length) return;

    final bucket = segments[publicIndex + 1];
    final filePath = segments.sublist(publicIndex + 2).join('/');

    if (filePath.isNotEmpty) {
      await _supabase.storage.from(bucket).remove([filePath]);
    }
  }
}

