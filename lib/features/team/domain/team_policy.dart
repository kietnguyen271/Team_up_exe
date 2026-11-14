import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_user_exception.dart';
import 'team_models.dart';

class TeamPolicyException implements Exception, AppUserException {
  const TeamPolicyException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract final class TeamPolicy {
  static const maxBioLength = 280;
  static const minPasswordLength = 8;
  static const maxPendingRequests = 3;
  static const maxRequestMessageLength = 280;
  static const requestLifetime = Duration(hours: 48);
  static const voteLifetime = Duration(hours: 24);
  static const disbandLifetime = Duration(hours: 24);
  static const rolloverLease = Duration(minutes: 10);
  static const maxBatchWrites = 400;

  static bool validEmail(String email) {
    final value = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return false;
    return value.endsWith('@fpt.edu.vn');
  }

  static void validateRegistration(String email, String password) {
    if (!validEmail(email)) {
      throw const TeamPolicyException(AppStrings.invalidSchoolEmail);
    }
    if (password.length < minPasswordLength) {
      throw const TeamPolicyException(AppStrings.passwordTooShort);
    }
  }

  static void validateProfile(String name, String bio, List<String> skills) {
    if (name.trim().isEmpty) {
      throw const TeamPolicyException(AppStrings.nameRequired);
    }
    if (bio.trim().isEmpty || bio.length > maxBioLength) {
      throw const TeamPolicyException(AppStrings.bioInvalid);
    }
    if (skills.isEmpty || skills.any((skill) => !teamSkills.contains(skill))) {
      throw const TeamPolicyException(AppStrings.skillsInvalid);
    }
  }

  static void checkJoin(TeamUser user, TeamRoom room) {
    if (user.completed) {
      throw const TeamPolicyException(AppStrings.alreadyCompleted);
    }
    if (user.roomId != null) {
      throw const TeamPolicyException(AppStrings.alreadyInRoom);
    }
    if (user.serverId != room.serverId) {
      throw const TeamPolicyException(AppStrings.wrongServer);
    }
    if (room.locked) {
      throw const TeamPolicyException(AppStrings.roomIsLocked);
    }
    if (room.isFull) {
      throw const TeamPolicyException(AppStrings.groupIsFull);
    }
  }

  /// Locked rooms remain accessible to their members so the leader can reopen them.
  static bool canSeeRoom(TeamUser user, TeamRoom room) =>
      !room.locked || room.contains(user.id);

  static void checkRequest(TeamUser user, TeamRoom room) {
    checkJoin(user, room);
    if (room.isEmpty) {
      throw const TeamPolicyException(AppStrings.emptyRoomJoinDirectly);
    }
    if (user.pendingRequestIds.length >= maxPendingRequests) {
      throw const TeamPolicyException(AppStrings.tooManyRequests);
    }
  }

  static bool canResendRequest(TeamJoinRequest request, DateTime now) =>
      request.status == 'cancelled' ||
      request.status == 'rejected' ||
      request.status == 'expired' ||
      !now.isBefore(request.expiresAt);

  static String? voteWinner(
      List<String> currentMembers, Map<String, String> ballots,
      {required bool expired}) {
    final members = currentMembers.toSet();
    final counts = <String, int>{};
    for (final entry in ballots.entries) {
      if (members.contains(entry.key) && members.contains(entry.value)) {
        counts[entry.value] = (counts[entry.value] ?? 0) + 1;
      }
    }
    for (final entry in counts.entries) {
      if (entry.value > members.length / 2) return entry.key;
    }
    if (!expired || counts.isEmpty) return null;
    final highest = counts.values.reduce((a, b) => a > b ? a : b);
    final leaders = counts.entries.where((entry) => entry.value == highest);
    return leaders.length == 1 ? leaders.first.key : null;
  }

  static bool disbandApproved(List<String> members, List<String> approvedBy) =>
      members.isNotEmpty && members.every(approvedBy.toSet().contains);

  static String normalize(String value) {
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const target =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final index = source.indexOf(character);
      buffer.write(index >= 0 ? target[index] : character);
    }
    return buffer.toString().trim();
  }

  static List<String> missingSkills(Iterable<List<String>> memberSkills) {
    final covered = memberSkills.expand((skills) => skills).toSet();
    return teamSkills.where((skill) => !covered.contains(skill)).toList();
  }
}
