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
}
