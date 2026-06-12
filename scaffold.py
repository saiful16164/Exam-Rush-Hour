import os

folders = [
    'lib/models',
    'lib/providers',
    'lib/services',
    'lib/screens/student',
    'lib/screens/teacher',
    'lib/widgets',
]

files = [
    'lib/router.dart',
    'lib/models/exam.dart',
    'lib/models/mcq_question.dart',
    'lib/models/submission.dart',
    'lib/models/written_question.dart',
    'lib/providers/auth_provider.dart',
    'lib/providers/exam_provider.dart',
    'lib/providers/mcq_state_provider.dart',
    'lib/providers/written_state_provider.dart',
    'lib/services/exam_service.dart',
    'lib/services/submission_service.dart',
    'lib/services/storage_service.dart',
    'lib/screens/student/landing_page.dart',
    'lib/screens/student/join_exam_page.dart',
    'lib/screens/student/mcq_exam_screen.dart',
    'lib/screens/student/written_exam_screen.dart',
    'lib/screens/student/submission_complete.dart',
    'lib/screens/teacher/login_page.dart',
    'lib/screens/teacher/register_page.dart',
    'lib/screens/teacher/dashboard_page.dart',
    'lib/screens/teacher/create_exam_page.dart',
    'lib/screens/teacher/results_page.dart',
    'lib/widgets/countdown_timer.dart',
    'lib/widgets/mcq_option_button.dart',
    'lib/widgets/question_navigator_grid.dart',
    'lib/widgets/image_upload_grid.dart',
    'lib/widgets/pdf_viewer_widget.dart',
]

for folder in folders:
    os.makedirs(folder, exist_ok=True)

for file in files:
    if not os.path.exists(file):
        with open(file, 'w') as f:
            # write a basic placeholder
            name = os.path.basename(file).split('.')[0].replace('_', ' ').title().replace(' ', '')
            if file.startswith('lib/screens') or file.startswith('lib/widgets'):
                f.write(f"""import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class {name} extends ConsumerWidget {{
  const {name}({{super.key}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {{
    return const Scaffold(
      body: Center(child: Text('{name}')),
    );
  }}
}}
""")
            else:
                f.write("// Placeholder for " + name + "\n")

print('Scaffolding complete.')
