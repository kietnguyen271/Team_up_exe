import 'package:firebase_ai/firebase_ai.dart';

import '../domain/skill_summary_service.dart';
import '../domain/team_models.dart';

class GeminiSkillSummaryService implements SkillSummaryService {
  const GeminiSkillSummaryService();

  static const modelName = String.fromEnvironment(
    'TEAMUP_GEMINI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );

  @override
  Future<String> summarize(List<TeamUser> members) async {
    final model = FirebaseAI.googleAI().generativeModel(model: modelName);
    final skills = members
        .map((member) => '${member.name}: ${member.skills.join(', ')}')
        .join('\n');
    final response = await model.generateContent([
      Content.text(
        'Tóm tắt bằng tiếng Việt, tối đa 60 từ, các kỹ năng nhóm còn thiếu '
        'so với danh sách ${teamSkills.join(', ')}. Không bịa thêm thành viên. '
        'Kỹ năng hiện tại:\n$skills',
      ),
    ]);
    return response.text ?? '';
  }
}
