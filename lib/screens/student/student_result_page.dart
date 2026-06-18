import 'package:flutter/material.dart';
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
      
      if (mounted) {
        setState(() {
          if (updatedSub != null) _currentSubmission = updatedSub;
          _mcqScore = score;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                        ],
                      ),
                    ),
                  ),
                
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
}
