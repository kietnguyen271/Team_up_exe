import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/features/admin/domain/rollover_engine.dart';
import 'package:teamup_exe/features/team/domain/team_models.dart';

class _FakeStore implements RolloverStore {
  _FakeStore({
    Map<String, String>? rooms,
    this.template = const [],
    this.failOnRoom,
  }) : rooms = rooms ?? {};

  final Map<String, String> rooms;
  final List<RoomTemplate> template;
  String? failOnRoom;
  final Set<String> completed = {};
  final Set<String> renewed = {};
  String step = 'completeExe2';
  bool done = false;

  @override
  Future<List<String>> roomIds(String serverId) async => rooms.entries
      .where((entry) => entry.value == serverId)
      .map((entry) => entry.key)
      .toList();

  @override
  Future<void> completeExe2Room(String roomId) async {
    if (failOnRoom == roomId) {
      failOnRoom = null;
      throw StateError('simulated failure');
    }
    completed.add(roomId);
    rooms.remove(roomId);
  }

  @override
  Future<void> moveExe1Room(String roomId) async {
    if (rooms[roomId] == 'exe1') rooms[roomId] = 'exe2';
  }

  @override
  Future<List<RoomTemplate>> exe1Template() async => template;

  @override
  Future<void> ensureRenewedRoom(
      String runId, int index, RoomTemplate room) async {
    renewed.add('exe1_${runId}_$index');
  }

  @override
  Future<void> setStep(String value) async => step = value;

  @override
  Future<void> heartbeat() async {}

  @override
  Future<void> setDone() async {
    step = 'done';
    done = true;
  }
}

void main() {
  test('empty servers complete without creating rooms', () async {
    final store = _FakeStore();
    await RolloverEngine(store).run(store.step, 'term1');
    expect(store.done, isTrue);
    expect(store.renewed, isEmpty);
  });

  test('EXE2 completes first; EXE1 moves and renews uneven template', () async {
    final store = _FakeStore(
      rooms: {'old1': 'exe2', 'old2': 'exe2', 'up1': 'exe1'},
      template: const [RoomTemplate('Room 1', 4), RoomTemplate('Room 2', 5)],
    );
    await RolloverEngine(store).run(store.step, 'term1');
    expect(store.completed, {'old1', 'old2'});
    expect(store.rooms, {'up1': 'exe2'});
    expect(store.renewed, {'exe1_term1_0', 'exe1_term1_1'});
  });

  test('failure halfway resumes and a repeated renewal is idempotent',
      () async {
    final store = _FakeStore(
      rooms: {'old1': 'exe2', 'old2': 'exe2', 'up1': 'exe1'},
      template: const [RoomTemplate('Room 1', 4)],
      failOnRoom: 'old2',
    );
    await expectLater(
      RolloverEngine(store).run(store.step, 'term1'),
      throwsStateError,
    );
    expect(store.completed, {'old1'});
    await RolloverEngine(store).run(store.step, 'term1');
    expect(store.completed, {'old1', 'old2'});
    expect(store.rooms['up1'], 'exe2');
    await RolloverEngine(store).run('recreateExe1', 'term1');
    expect(store.renewed, {'exe1_term1_0'});
  });
}
