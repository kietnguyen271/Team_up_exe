import '../../../core/constants/app_strings.dart';
import 'team_models.dart';
import 'team_policy.dart';

abstract interface class SkillSummaryService {
  Future<String> summarize(List<TeamUser> members);
}

class LocalSkillSummaryService implements SkillSummaryService {
  const LocalSkillSummaryService();

  @override
  Future<String> summarize(List<TeamUser> members) async {
    final missing =
        TeamPolicy.missingSkills(members.map((member) => member.skills));
    if (missing.isEmpty) {
      return AppStrings.allSkillsCovered;
    }
    return AppStrings.missingSkillsSummary(missing.join(', '));
  }
}

class FallbackSkillSummaryService implements SkillSummaryService {
  const FallbackSkillSummaryService(this.primary, this.fallback);
  final SkillSummaryService primary;
  final SkillSummaryService fallback;

  @override
  Future<String> summarize(List<TeamUser> members) async {
    try {
      final result = await primary.summarize(members);
      if (result.trim().isNotEmpty) return result;
    } catch (_) {
      // The local implementation keeps the card usable offline.
    }
    return fallback.summarize(members);
  }
}
