import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/features/team/domain/team_models.dart';
import 'package:teamup_exe/features/team/domain/team_policy.dart';
import 'package:teamup_exe/features/team/domain/skill_summary_service.dart';

class _FailingSummary implements SkillSummaryService {
  @override
  Future<String> summarize(List<TeamUser> members) =>
      Future<String>.error(StateError('AI offline'));
}

void main() {
  const student = TeamUser(
    id: 'u1',
    name: 'A',
    email: 'a@fpt.edu.vn',
    bio: 'Xin chào',
    skills: ['Backend'],
    serverId: 'exe1',
  );

  test('registration accepts only FPT email and validates password', () {
    expect(TeamPolicy.validEmail(' Student@FPT.EDU.VN '), isTrue);
    expect(TeamPolicy.validEmail('teacher@fe.edu.vn'), isFalse);
    expect(TeamPolicy.validEmail('student@gmail.com'), isFalse);
    expect(TeamPolicy.validEmail('student@fakefpt.edu.vn'), isFalse);
    expect(
      () => TeamPolicy.validateRegistration('student@fe.edu.vn', 'password123'),
      throwsA(isA<TeamPolicyException>()),
    );
    expect(
      () => TeamPolicy.validateRegistration('student@fpt.edu.vn', 'short'),
      throwsA(isA<TeamPolicyException>()),
    );
  });

  test('profile requires bio and skill', () {
    expect(
      () => TeamPolicy.validateProfile('An', '', ['Backend']),
      throwsA(isA<TeamPolicyException>()),
    );
    expect(
      () => TeamPolicy.validateProfile('An', 'Xin chào', []),
      throwsA(isA<TeamPolicyException>()),
    );
    TeamPolicy.validateProfile('An', 'Xin chào', ['Backend']);
  });

  test('join checks room, server and one-room limit', () {
    const empty = TeamRoom(
      id: 'r1',
      serverId: 'exe1',
      name: 'Phòng 1',
      capacity: 2,
      memberIds: [],
    );
    TeamPolicy.checkJoin(student, empty);
    expect(
      () => TeamPolicy.checkJoin(
        student,
        const TeamRoom(
          id: 'r2',
          serverId: 'exe2',
          name: 'Phòng 2',
          capacity: 2,
          memberIds: [],
        ),
      ),
      throwsA(isA<TeamPolicyException>()),
    );
    expect(
      () => TeamPolicy.checkJoin(
        const TeamUser(
          id: 'u1',
          name: 'A',
          email: 'a@fpt.edu.vn',
          bio: 'Xin chào',
          skills: ['Backend'],
          serverId: 'exe1',
          roomId: 'other',
        ),
        empty,
      ),
      throwsA(isA<TeamPolicyException>()),
    );
  });

  test('students see rooms until locked, while members retain access', () {
    const open = TeamRoom(
      id: 'open',
      serverId: 'exe1',
      name: 'Phòng mở',
      capacity: 2,
      memberIds: ['other'],
    );
    const full = TeamRoom(
      id: 'full',
      serverId: 'exe1',
      name: 'Phòng đủ người',
      capacity: 1,
      memberIds: ['other'],
    );
    const locked = TeamRoom(
      id: 'locked',
      serverId: 'exe1',
      name: 'Phòng khóa',
      capacity: 2,
      memberIds: ['leader'],
      leaderId: 'leader',
      locked: true,
    );
    const leader = TeamUser(
      id: 'leader',
      name: 'Trưởng nhóm',
      email: 'leader@fpt.edu.vn',
      bio: 'Bio',
      skills: ['Backend'],
      serverId: 'exe1',
      roomId: 'locked',
    );

    expect(TeamPolicy.canSeeRoom(student, open), isTrue);
    expect(TeamPolicy.canSeeRoom(student, full), isTrue);
    expect(TeamPolicy.canSeeRoom(student, locked), isFalse);
    expect(TeamPolicy.canSeeRoom(leader, locked), isTrue);
  });

  test('vote majority, expiry, tie and departed voters', () {
    final members = ['a', 'b', 'c'];
    expect(TeamPolicy.voteWinner(members, {'a': 'a', 'b': 'a'}, expired: false),
        'a');
    expect(TeamPolicy.voteWinner(members, {'a': 'a'}, expired: false), isNull);
    expect(TeamPolicy.voteWinner(members, {'a': 'a'}, expired: true), 'a');
    expect(TeamPolicy.voteWinner(members, {'a': 'a', 'b': 'b'}, expired: true),
        isNull);
    expect(TeamPolicy.voteWinner(members, {'departed': 'a'}, expired: true),
        isNull);
    expect(
        TeamPolicy.voteWinner(['a', 'b'], {'a': 'a', 'b': 'a'}, expired: false),
        'a');
  });

  test('disband needs every current member', () {
    expect(TeamPolicy.disbandApproved(['a', 'b'], ['a']), isFalse);
    expect(TeamPolicy.disbandApproved(['a', 'b'], ['a', 'b']), isTrue);
  });

  test('search folds Vietnamese accents', () {
    expect(TeamPolicy.normalize('Đội Kỹ Thuật'), 'doi ky thuat');
  });

  test('request expiration is based on the deadline', () {
    final deadline = DateTime.utc(2026, 11, 6, 12);
    final request = TeamJoinRequest(
      uid: 'u1',
      roomId: 'r1',
      createdAt: deadline.subtract(TeamPolicy.requestLifetime),
      expiresAt: deadline,
      status: 'pending',
    );
    expect(request.isPendingAt(deadline.subtract(const Duration(seconds: 1))),
        isTrue);
    expect(request.isPendingAt(deadline), isFalse);
    expect(TeamPolicy.canResendRequest(request, deadline), isTrue);
    expect(
        TeamPolicy.canResendRequest(
            request, deadline.subtract(const Duration(seconds: 1))),
        isFalse);
  });

  test('AI failure falls back to local missing-skill summary', () async {
    final summary = await FallbackSkillSummaryService(
      _FailingSummary(),
      const LocalSkillSummaryService(),
    ).summarize([student]);
    expect(summary, contains('Frontend'));
    expect(summary, isNot(contains('Backend')));
  });
}
