import '../../team/domain/team_models.dart';

abstract interface class RolloverStore {
  Future<List<String>> roomIds(String serverId);
  Future<void> completeExe2Room(String roomId);
  Future<void> moveExe1Room(String roomId);
  Future<List<RoomTemplate>> exe1Template();
  Future<void> ensureRenewedRoom(String runId, int index, RoomTemplate room);
  Future<void> heartbeat();
  Future<void> setStep(String step);
  Future<void> setDone();
}

class RolloverEngine {
  const RolloverEngine(this.store);
  final RolloverStore store;

  Future<void> run(String initialStep, String runId) async {
    var step = initialStep;
    if (step == 'completeExe2') {
      for (final roomId in await store.roomIds('exe2')) {
        await store.completeExe2Room(roomId);
        await store.heartbeat();
      }
      step = 'moveExe1';
      await store.setStep(step);
    }
    if (step == 'moveExe1') {
      for (final roomId in await store.roomIds('exe1')) {
        await store.moveExe1Room(roomId);
        await store.heartbeat();
      }
      step = 'recreateExe1';
      await store.setStep(step);
    }
    if (step == 'recreateExe1') {
      final template = await store.exe1Template();
      for (var index = 0; index < template.length; index++) {
        await store.ensureRenewedRoom(runId, index, template[index]);
        await store.heartbeat();
      }
      await store.setDone();
    }
  }
}
