abstract interface class SoundService {
  Future<void> playConfirm();
  Future<void> playSuccess();
}

class NoOpSoundService implements SoundService {
  const NoOpSoundService();

  @override
  Future<void> playConfirm() async {}

  @override
  Future<void> playSuccess() async {}
}
