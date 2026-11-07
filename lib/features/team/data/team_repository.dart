import '../domain/team_models.dart';

abstract interface class TeamRepository {
  Stream<TeamUser?> watchUser(String uid);
  Stream<List<TeamRoom>> watchRooms(String serverId);
  Stream<TeamRoom?> watchRoom(String roomId);
  Stream<List<TeamJoinRequest>> watchRequests(String roomId);
  Stream<TeamJoinRequest?> watchOwnRequest(String roomId, String uid);
  Stream<TeamVote?> watchVote(String roomId);
  Stream<TeamDisband?> watchDisband(String roomId);
  Future<TeamUser?> getUser(String uid);
  Future<List<TeamUser>> getMembers(List<String> uids);
  Future<void> saveProfile(
      String uid, String email, String name, String bio, List<String> skills);
  Future<void> chooseServer(String uid, String serverId);
  Future<String> joinOrRequest(String uid, String roomId,
      {String message = ''});
  Future<void> decideRequest(
      String actorUid, String roomId, String requesterUid, bool approve);
  Future<void> cancelRequest(String uid, String roomId);
  Future<void> expireRequest(String roomId, String requesterUid);
  Future<void> leaveRoom(String uid, String roomId);
  Future<void> renameRoom(String uid, String roomId, String name);
  Future<void> setLocked(String uid, String roomId, bool locked);
  Future<void> startVote(String uid, String roomId);
  Future<void> castVote(String uid, String roomId, String candidateUid);
  Future<void> finalizeVote(String roomId);
  Future<void> proposeDisband(String uid, String roomId);
  Future<void> approveDisband(String uid, String roomId);
}
