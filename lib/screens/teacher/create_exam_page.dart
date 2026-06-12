import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/mcq_question.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../providers/exam_provider.dart';
import '../../services/exam_service.dart';

import '../../models/exam.dart';

class CreateExamPage extends ConsumerStatefulWidget {
  final Exam? existingExam;
  const CreateExamPage({super.key, this.existingExam});

  @override
  ConsumerState<CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends ConsumerState<CreateExamPage> {
  int _currentStep = 0;
  
  // Tab 1: Basic Info
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _examCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mcqTimeController = TextEditingController(text: '30');
  final _writtenTimeController = TextEditingController(text: '60');
  bool _hasMcq = true;
  bool _hasWritten = false;
  
  // Tab 2: MCQ Questions
  List<McqQuestion> _questions = [];
  
  // Tab 3: Written File
  Uint8List? _writtenFileBytes;
  String? _writtenFileName;
  String _fileType = '';
  String? _writtenFileUrl;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingExam != null) {
      _titleController.text = widget.existingExam!.title;
      _descController.text = widget.existingExam!.description ?? '';
      _examCodeController.text = widget.existingExam!.examCode;
      _passwordController.text = widget.existingExam!.password;
      _mcqTimeController.text = widget.existingExam!.mcqTimeMinutes.toString();
      _writtenTimeController.text = widget.existingExam!.writtenTimeMinutes.toString();
      _hasMcq = widget.existingExam!.hasMcq;
      _hasWritten = widget.existingExam!.hasWritten;
      _loadExistingExamData();
    } else {
      _examCodeController.text = _generateExamCode();
    }
  }

  Future<void> _loadExistingExamData() async {
    final service = ExamService();
    if (_hasMcq) {
      final qs = await service.getMcqQuestions(widget.existingExam!.id);
      setState(() => _questions = qs);
    }
    if (_hasWritten) {
      final wq = await service.getWrittenQuestion(widget.existingExam!.id);
      if (wq != null) {
        setState(() {
          _writtenFileName = 'Existing file (${wq.fileType})';
          _fileType = wq.fileType;
          _writtenFileUrl = wq.fileUrl;
        });
      }
    }
  }

  String _generateExamCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _addQuestion(McqQuestion q) {
    setState(() {
      _questions.add(q);
    });
  }

  void _showAddQuestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AddQuestionForm(onAdd: (q) {
            _addQuestion(q);
            Navigator.pop(ctx);
          }),
        );
      }
    );
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _writtenFileBytes = result.files.single.bytes;
        _writtenFileName = result.files.single.name;
        _fileType = 'pdf';
        _writtenFileUrl = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _writtenFileBytes = bytes;
        _writtenFileName = image.name;
        _fileType = 'image';
        _writtenFileUrl = null;
      });
    }
  }

  Future<void> _showFilePreview() async {
    if (_writtenFileUrl != null) {
      try {
        final uri = Uri.parse(_writtenFileUrl!);
        await launchUrl(uri, webOnlyWindowName: '_blank');
        return;
      } catch (e) {
        // Fall back to showing an error in the dialog if launch fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $e')),
          );
        }
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        Widget content;
        if (_fileType == 'pdf') {
          if (_writtenFileBytes != null) {
            content = SfPdfViewer.memory(_writtenFileBytes!);
          } else {
            content = const Text('No PDF to preview');
          }
        } else {
          if (_writtenFileBytes != null) {
            content = InteractiveViewer(
              child: Image.memory(
                _writtenFileBytes!,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, size: 48, color: Colors.red)),
              ),
            );
          } else {
            content = const Text('No Image to preview');
          }
        }
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('File Preview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(child: content),
              ],
            ),
          ),
        );
      }
    );
  }

  Future<void> _saveExam() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final teacherId = ref.read(authProvider)?.id;
      
      if (teacherId == null) throw Exception('Not logged in');

      final examData = {
        'teacher_id': teacherId,
        'title': _titleController.text,
        'description': _descController.text,
        'exam_code': _examCodeController.text,
        'password': _passwordController.text,
        'mcq_time_minutes': int.tryParse(_mcqTimeController.text) ?? 30,
        'written_time_minutes': int.tryParse(_writtenTimeController.text) ?? 60,
        'has_mcq': _hasMcq,
        'has_written': _hasWritten,
        'is_active': true,
      };

      String examId;
      if (widget.existingExam == null) {
        final examRes = await supabase.from('exams').insert(examData).select().single();
        examId = examRes['id'];
      } else {
        examId = widget.existingExam!.id;
        await supabase.from('exams').update(examData).eq('id', examId);
      }

      // Update MCQs: delete existing and insert new
      if (widget.existingExam != null) {
        await supabase.from('mcq_questions').delete().eq('exam_id', examId);
      }
      if (_hasMcq && _questions.isNotEmpty) {
        final mcqPayload = _questions.asMap().entries.map((e) => {
          'exam_id': examId,
          'question_text': e.value.questionText,
          'option_a': e.value.optionA,
          'option_b': e.value.optionB,
          'option_c': e.value.optionC,
          'option_d': e.value.optionD,
          'correct_option': e.value.correctOption,
          'marks': e.value.marks,
          'order_index': e.key,
        }).toList();
        await supabase.from('mcq_questions').insert(mcqPayload);
      }

      if (widget.existingExam != null && (!_hasWritten || _writtenFileName == null)) {
        await supabase.from('written_questions').delete().eq('exam_id', examId);
      }

      // Save Written File only if a new one is selected
      if (_hasWritten && _writtenFileBytes != null && _writtenFileName != null && !_writtenFileName!.startsWith('Existing')) {
        if (widget.existingExam != null) {
          await supabase.from('written_questions').delete().eq('exam_id', examId);
        }
        final storageService = StorageService();
        final ext = _writtenFileName!.split('.').last;
        final url = await storageService.uploadWrittenQuestion(examId, _writtenFileBytes!, ext);
        await supabase.from('written_questions').insert({
          'exam_id': examId,
          'file_url': url,
          'file_type': _fileType,
        });
      }
      
      ref.invalidate(teacherExamsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exam: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text('Are you sure you want to delete this exam? All submissions and questions will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final examId = widget.existingExam!.id;
      await supabase.from('mcq_questions').delete().eq('exam_id', examId);
      await supabase.from('written_questions').delete().eq('exam_id', examId);
      await supabase.from('submissions').delete().eq('exam_id', examId);
      await supabase.from('exams').delete().eq('id', examId);
      ref.invalidate(teacherExamsProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting exam: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExam == null ? 'Create Exam' : 'Edit Exam'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: widget.existingExam != null ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Exam',
            onPressed: _deleteExam,
          )
        ] : null,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF1DB954).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.info, color: Color(0xFF1DB954)),
                          ),
                          const SizedBox(width: 16),
                          const Text('1. Basic Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Exam Title')),
                      const SizedBox(height: 16),
                      TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _examCodeController, decoration: const InputDecoration(labelText: 'Exam Code', prefixIcon: Icon(Icons.code)))),
                          const SizedBox(width: 16),
                          Expanded(child: TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Include MCQ Section', style: TextStyle(fontWeight: FontWeight.bold)),
                        activeColor: const Color(0xFF1DB954),
                        value: _hasMcq,
                        onChanged: (v) => setState(() => _hasMcq = v),
                      ),
                      if (_hasMcq) 
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(controller: _mcqTimeController, decoration: const InputDecoration(labelText: 'MCQ Time (mins)', prefixIcon: Icon(Icons.timer)), keyboardType: TextInputType.number),
                        ),
                      SwitchListTile(
                        title: const Text('Include Written Section', style: TextStyle(fontWeight: FontWeight.bold)),
                        activeColor: const Color(0xFF1DB954),
                        value: _hasWritten,
                        onChanged: (v) => setState(() => _hasWritten = v),
                      ),
                      if (_hasWritten) 
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(controller: _writtenTimeController, decoration: const InputDecoration(labelText: 'Written Time (mins)', prefixIcon: Icon(Icons.timer)), keyboardType: TextInputType.number),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.list_alt, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          const Text('2. MCQ Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _hasMcq ? Column(
                        children: [
                          if (_questions.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                              child: Text('No questions added yet.', style: TextStyle(color: Colors.grey[500])),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _questions.length,
                              itemBuilder: (ctx, idx) {
                                final q = _questions[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text('Q${idx+1}: ${q.questionText}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('Ans: ${q.correctOption} | Marks: ${q.marks}', style: TextStyle(color: Colors.grey[600])),
                                    ),
                                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _questions.removeAt(idx))),
                                  ),
                                );
                              }
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showAddQuestionSheet, 
                              icon: const Icon(Icons.add), 
                              label: const Text('Add Question'),
                            ),
                          ),
                        ]
                      ) : Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                          child: Text('MCQ Section is disabled.', style: TextStyle(color: Colors.grey[500])),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.edit_document, color: Colors.orange),
                          ),
                          const SizedBox(width: 16),
                          const Text('3. Written File', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _hasWritten ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickPdf, 
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red), 
                                  label: const Text('Upload PDF'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage, 
                                  icon: const Icon(Icons.image, color: Colors.blue), 
                                  label: const Text('Upload Image'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_writtenFileName != null)
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(color: const Color(0xFF1DB954).withOpacity(0.05), border: Border.all(color: const Color(0xFF1DB954)), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF1DB954)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('Selected: $_writtenFileName', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue),
                                    tooltip: 'Preview File',
                                    onPressed: _showFilePreview,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Remove File',
                                    onPressed: () => setState(() {
                                      _writtenFileName = null;
                                      _writtenFileBytes = null;
                                      _writtenFileUrl = null;
                                      _fileType = '';
                                    }),
                                  ),
                                ],
                              ),
                            ),
                        ]
                      ) : Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                          child: Text('Written Section is disabled.', style: TextStyle(color: Colors.grey[500])),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                  onPressed: _saveExam,
                  child: Text(widget.existingExam == null ? 'CREATE EXAM' : 'SAVE UPDATES', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
    );
  }
}

class AddQuestionForm extends StatefulWidget {
  final Function(McqQuestion) onAdd;
  const AddQuestionForm({super.key, required this.onAdd});

  @override
  State<AddQuestionForm> createState() => _AddQuestionFormState();
}

class _AddQuestionFormState extends State<AddQuestionForm> {
  final _qController = TextEditingController();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();
  final _dController = TextEditingController();
  final _marksController = TextEditingController(text: '1');
  String _correct = 'A';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _qController, decoration: const InputDecoration(labelText: 'Question Text'), maxLines: 3),
          TextField(controller: _aController, decoration: const InputDecoration(labelText: 'Option A')),
          TextField(controller: _bController, decoration: const InputDecoration(labelText: 'Option B')),
          TextField(controller: _cController, decoration: const InputDecoration(labelText: 'Option C')),
          TextField(controller: _dController, decoration: const InputDecoration(labelText: 'Option D')),
          DropdownButtonFormField<String>(
            value: _correct,
            items: ['A', 'B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text('Correct: $e'))).toList(),
            onChanged: (v) => setState(() => _correct = v!),
          ),
          TextField(controller: _marksController, decoration: const InputDecoration(labelText: 'Marks'), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final q = McqQuestion(
                id: '', // Generated later or by DB
                examId: '',
                questionText: _qController.text,
                optionA: _aController.text,
                optionB: _bController.text,
                optionC: _cController.text,
                optionD: _dController.text,
                correctOption: _correct,
                marks: int.tryParse(_marksController.text) ?? 1,
                orderIndex: 0,
              );
              widget.onAdd(q);
            },
            child: const Text('Save Question'),
          )
        ],
      ),
    );
  }
}
