import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/submission.dart';
import '../../services/submission_service.dart';

class StudentResultPage extends StatefulWidget {
  final Submission submission;
  const StudentResultPage({super.key, required this.submission});

  @override
  State<StudentResultPage> createState() => _StudentResultPageState();
}

class _StudentResultPageState extends State<StudentResultPage> {
  int? _mcqScore;
  bool _isLoading = true;
  late Submission _currentSubmission;
  List<Map<String, dynamic>> _mcqDetails = [];

  @override
  void initState() {
    super.initState();
    _currentSubmission = widget.submission;
    _loadScore();
  }

  Future<void> _loadScore() async {
    try {
      final updatedSub = await SubmissionService().getStudentSubmission(_currentSubmission.examId, _currentSubmission.studentId!);
      final score = await SubmissionService().getMcqScore(_currentSubmission.id);
      final mcqDetails = await SubmissionService().getMcqResultDetails(_currentSubmission.id);
      
      if (mounted) {
        setState(() {
          if (updatedSub != null) _currentSubmission = updatedSub;
          _mcqScore = score;
          _mcqDetails = mcqDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _viewGradedAnswers() async {
    final answers = await Supabase.instance.client
        .from('written_answers')
        .select()
        .eq('submission_id', _currentSubmission.id)
        .order('page_number', ascending: true);
        
    if (!mounted) return;

    if (answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No written answers found.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            height: 600,
            width: double.infinity,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Your Graded Answers'),
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
                ),
                Expanded(
                  child: PageView.builder(
                    itemCount: answers.length,
                    itemBuilder: (context, index) {
                      final originalUrl = answers[index]['image_url'];
                      final gradedUrl = answers[index]['graded_image_url'];
                      final url = gradedUrl ?? originalUrl;
                      final isPdf = url.toLowerCase().contains('.pdf?t=') || url.toLowerCase().endsWith('.pdf');
                      
                      if (isPdf) {
                        return SfPdfViewer.network(url);
                      }
                      return InteractiveViewer(
                        child: Image.network(
                          url,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
                          },
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                      );
                    },
                  ),
                ),
              ]
            )
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Result')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.stars, size: 80, color: Color(0xFF1DB954)),
                const SizedBox(height: 24),
                const Text(
                  'Exam Completed!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Great job, ${_currentSubmission.studentName}. Here is your performance summary.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Card(
                    elevation: 4,
                    shadowColor: const Color(0xFF1DB954).withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('MCQ Score:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$_mcqScore',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1DB954)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Written Marks:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _currentSubmission.writtenMarks != null 
                                      ? const Color(0xFF1DB954).withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _currentSubmission.writtenMarks != null ? '${_currentSubmission.writtenMarks}' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold, 
                                    color: _currentSubmission.writtenMarks != null ? const Color(0xFF1DB954) : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_currentSubmission.writtenMarks != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _viewGradedAnswers,
                              icon: const Icon(Icons.visibility),
                              label: const Text('View Graded Answers'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DB954),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                if (!_isLoading && _mcqDetails.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text('MCQ Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._mcqDetails.map((detail) => _buildMcqQuestionCard(detail)),
                ],

                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMcqQuestionCard(Map<String, dynamic> detail) {
    final question = detail['mcq_questions'] as Map<String, dynamic>;
    final selectedOption = detail['selected_option'] as String?;
    final correctOption = question['correct_option'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question_text'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['A', 'B', 'C', 'D'].map((optLetter) {
              final optKey = 'option_${optLetter.toLowerCase()}';
              final optValue = question[optKey] as String;
              final isSelected = selectedOption == optLetter;
              final isCorrect = correctOption == optLetter;
              
              Color bgColor = Colors.transparent;
              Color borderColor = Colors.grey.shade300;
              IconData? icon;
              Color iconColor = Colors.transparent;

              if (isCorrect) {
                bgColor = const Color(0xFF1DB954).withOpacity(0.1);
                borderColor = const Color(0xFF1DB954);
                icon = Icons.check_circle;
                iconColor = const Color(0xFF1DB954);
              } else if (isSelected && !isCorrect) {
                bgColor = Colors.red.withOpacity(0.1);
                borderColor = Colors.red;
                icon = Icons.cancel;
                iconColor = Colors.red;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: isSelected || isCorrect ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        optValue,
                        style: TextStyle(
                          fontWeight: isSelected || isCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: iconColor, size: 20),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
