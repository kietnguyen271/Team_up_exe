abstract final class AppStrings {
  static const appName = 'TeamUp EXE';
  static const appVersion = '0.1.0+1';
  static const rooms = 'Phòng';
  static const profile = 'Hồ sơ';
  static const notifications = 'Thông báo';
  static const semester = 'Học kỳ';
  static const demoLog = 'Nhật ký demo';
  static const webAdminOnly = 'Trang web chỉ dành cho quản trị viên';
  static const adminIntro = 'Đăng nhập bằng tài khoản quản trị viên.';
  static const adminHome = 'Bảng điều khiển quản trị';
  static const adminPlaceholder =
      'Nội dung quản trị sẽ được xây dựng ở giai đoạn sau.';
  static const studentPlaceholder =
      'Nội dung sẽ được xây dựng ở giai đoạn sau.';
  static const roomDestination = 'Phòng được mở từ thông báo';
  static const firebaseSetupRequired = 'Cần cấu hình Firebase cho Android.';
  static const firebaseSetupCommand =
      'Chạy flutterfire configure --project=teamup-exe --platforms=android';
  static const crashDemo = 'Demo Crashlytics';
  static const causeCrash = 'Gây crash';
  static const recordNonFatal = 'Ghi lỗi không gây crash';
  static const crashExplanation =
      'Báo cáo crash xuất hiện trong Firebase Console sau khi mở lại ứng dụng và chờ vài phút.';
  static const crashTestException = 'Lỗi thử nghiệm Crashlytics';
  static const crashSaved = 'Đã ghi sự kiện demo; ứng dụng sẽ đóng ngay.';
  static const nonFatalSaved = 'Đã gửi lỗi không gây crash.';
  static const fcmToken = 'FCM token';
  static const copy = 'Sao chép';
  static const copied = 'Đã sao chép token.';
  static const requestNotificationPermission = 'Xin quyền thông báo';
  static const showFcmToken = 'Hiện FCM token';
  static const noFcmToken = 'Chưa có FCM token.';
  static const roomId = 'Mã phòng';
  static const subscribeTopic = 'Theo dõi chủ đề phòng';
  static const unsubscribeTopic = 'Ngừng theo dõi chủ đề phòng';
  static const invalidRoomId = 'Mã phòng không hợp lệ.';
  static const androidOnly = 'Ứng dụng chỉ chạy trên Android.';
  static const notificationPermissionDenied = 'Quyền thông báo chưa được cấp.';
  static const notificationPermissionGranted = 'Quyền thông báo đã được cấp.';
  static const newNotification = 'Thông báo mới';
  static const close = 'Đóng';
  static const firebaseNotReady = 'Firebase chưa sẵn sàng.';
  static const firebaseSignInFailed = 'Không thể đăng nhập.';
  static const firebaseMissingEmail =
      'Firebase không trả về tài khoản có email.';
  static const firebaseSignOutFailed = 'Không thể đăng xuất.';
  static const crashNeedsSignIn = 'Hãy đăng nhập trước khi gửi demo crash.';
  static const topicDone = 'Đã cập nhật chủ đề thông báo.';
  static const tokenSaved = 'Đã lưu FCM token.';
  static const login = 'Đăng nhập';
  static const verifyEmail = 'Xác thực email';
  static const verifyEmailIntro =
      'Hãy mở email xác thực, sau đó quay lại ứng dụng.';
  static const iVerified = 'Tôi đã xác thực';
  static const resendVerification = 'Gửi lại email';
  static const emailStillUnverified = 'Email chưa được xác thực.';
  static const verificationSent = 'Đã gửi email xác thực.';
  static const completed = 'Đã hoàn thành kỳ học';
  static const completedIntro =
      'Bạn đã hoàn thành kỳ học. Hãy đăng xuất để kết thúc.';
  static const signOut = 'Đăng xuất';
  static const register = 'Đăng ký';
  static const profileSetup = 'Thiết lập hồ sơ';
  static const chooseServer = 'Chọn server';
  static const home = 'Trang chủ';
  static const email = 'Email';
  static const name = 'Họ và tên';
  static const bio = 'Giới thiệu bản thân';
  static const skills = 'Kỹ năng';
  static const save = 'Lưu';
  static const password = 'Mật khẩu';
  static const retry = 'Thử lại';
  static const loading = 'Đang tải…';
  static const genericError = 'Đã xảy ra lỗi.';
  static const comingSoon =
      'Tính năng này sẽ được hoàn thiện ở bước tiếp theo.';
  static const loginIntro = 'Đăng nhập để tiếp tục với TeamUp EXE.';
  static const registerIntro = 'Tạo tài khoản để tham gia TeamUp EXE.';
  static const profileIntro =
      'Giới thiệu bản thân và chọn kỹ năng để nhóm hiểu bạn hơn.';
  static const serverIntro = 'Chọn EXE1 hoặc EXE2 trước khi xem phòng.';
  static const exe1 = 'EXE1';
  static const exe2 = 'EXE2';
  static const select = 'Chọn';
  static const sampleRooms = 'Danh sách phòng';
  static const searchRooms = 'Tìm phòng';
  static const noRooms = 'Chưa có phòng phù hợp.';
  static const roomEmpty = 'Trống';
  static const roomOpen = 'Đang mở';
  static const roomLocked = 'Đã khóa';
  static const roomFull = 'Đã đủ';
  static const yourRoom = 'Phòng của bạn';
  static String roomOccupancy(int members, int capacity) =>
      '$members/$capacity thành viên';
  static String roomCardSummary(
          String name, int members, int capacity, String status,
          {bool isMine = false}) =>
      '$name, ${roomOccupancy(members, capacity)}, $status${isMine ? ', $yourRoom' : ''}';
  static const roomMissing = 'Không tìm thấy phòng.';
  static const profileMissing = 'Chưa có hồ sơ.';
  static const roomName = 'Tên phòng';
  static const renameRoom = 'Đổi tên phòng';
  static const cancel = 'Hủy';
  static const joinRoom = 'Tham gia phòng';
  static const requestJoin = 'Gửi yêu cầu tham gia';
  static const requestMessage = 'Lời nhắn (không bắt buộc)';
  static const requestMessageTooLong = 'Lời nhắn tối đa 280 ký tự.';
  static const cancelRequest = 'Hủy yêu cầu đang chờ';
  static const leaveRoom = 'Rời phòng';
  static const lockRoom = 'Khóa phòng';
  static const unlockRoom = 'Mở khóa phòng';
  static const members = 'Thành viên';
  static const noMembers = 'Chưa có thành viên.';
  static const aiSuggestion = 'Gợi ý của AI';
  static const allSkillsCovered =
      'Nhóm đã bao phủ tất cả kỹ năng trong danh sách.';
  static String missingSkillsSummary(String skills) =>
      'Nhóm còn thiếu: $skills. Hãy tìm thành viên có các kỹ năng này.';
  static const leaderVote = 'Bầu trưởng nhóm';
  static const leader = 'Trưởng nhóm';
  static const voteActive = 'Đợt bầu đang diễn ra.';
  static String voteCount(String name, int count) => '$name: $count phiếu';
  static const castVote = 'Bỏ phiếu';
  static const startVote = 'Bắt đầu bầu';
  static const chooseLeader = 'Chọn ứng viên';
  static const disbandRoom = 'Giải tán phòng';
  static const proposeDisband = 'Đề xuất giải tán';
  static const approveDisband = 'Đồng ý giải tán';
  static const approvedDisband = 'người đã đồng ý';
  static const joinRequests = 'Yêu cầu tham gia';
  static const noJoinRequests = 'Không có yêu cầu đang chờ.';
  static const createRooms = 'Tạo phòng hàng loạt';
  static const roomCount = 'Số phòng';
  static const capacity = 'Sức chứa';
  static const editTemplate = 'Sửa mẫu phòng';
  static const templateFormat = 'Mỗi dòng: Tên phòng:Sức chứa';
  static const editCapacity = 'Sửa sức chứa';
  static const deleteRoom = 'Xóa phòng trống';
  static const roomActions = 'Thao tác phòng';
  static const previewRollover = 'Xem trước chuyển học kỳ';
  static const finishSemester = 'Hoàn tất học kỳ';
  static const typeHoanTat = 'Nhập HOAN TAT để xác nhận';
  static const rolloverConfirmation = 'HOAN TAT';
  static const wrongConfirmation = 'Chưa nhập đúng HOAN TAT.';
  static const prepareNextSemester = 'Chuẩn bị kỳ tiếp theo';
  static String rolloverStatus(String state, String step) {
    final stateLabel = switch (state) {
      'idle' => 'Sẵn sàng',
      'running' => 'Đang chạy',
      'done' => 'Đã xong',
      'failed' => 'Thất bại, có thể chạy lại',
      _ => 'Chưa bắt đầu',
    };
    final stepLabel = switch (step) {
      'completeExe2' => 'hoàn tất EXE2',
      'moveExe1' => 'chuyển EXE1 lên EXE2',
      'recreateExe1' => 'tạo lại EXE1',
      _ => '',
    };
    return 'Chuyển học kỳ: $stateLabel${stepLabel.isEmpty ? '' : ' · $stepLabel'}';
  }

  static const typeKyMoi = 'Nhập KY MOI để xác nhận';
  static const nextSemesterConfirmation = 'KY MOI';
  static const wrongNextSemesterConfirmation = 'Chưa nhập đúng KY MOI.';
  static const newAnnouncement = 'Tạo thông báo';
  static const sendRoomPush = 'Gửi push tới phòng';
  static const sendPush = 'Gửi push';
  static const pushRoom = 'Phòng';
  static const pushServer = 'Server';
  static const pushUser = 'Người dùng';
  static const pushAll = 'Tất cả';
  static const serverId = 'Mã server (exe1 hoặc exe2)';
  static const userId = 'UID người nhận';
  static const pushJobs = 'Trạng thái gửi push';
  static String pushStatus(String status) => switch (status) {
        'pending' => 'Đang chờ',
        'sending' => 'Đang gửi',
        'sent' => 'Đã gửi',
        'failed' => 'Gửi thất bại',
        _ => 'Không rõ',
      };
  static String pushJobDetails(String status, String? error) =>
      error == null || error.isEmpty
          ? pushStatus(status)
          : '${pushStatus(status)} · $error';
  static const announcementTitle = 'Tiêu đề';
  static const announcementBody = 'Nội dung';
  static const noAnnouncements = 'Chưa có thông báo.';
  static const allServers = 'Tất cả server';
  static const noDemoEvents = 'Chưa có sự kiện demo.';
  static const requestPending = 'Chờ duyệt';
  static const requestExpired =
      'Yêu cầu đã hết hạn hoặc phòng không còn nhận thành viên.';
  static const invalidSchoolEmail = 'Chỉ chấp nhận email FPT hoặc FE.';
  static const passwordTooShort = 'Mật khẩu cần ít nhất 8 ký tự.';
  static const nameRequired = 'Hãy nhập tên của bạn.';
  static const bioInvalid = 'Giới thiệu cần từ 1 đến 280 ký tự.';
  static const skillsInvalid = 'Hãy chọn ít nhất một kỹ năng hợp lệ.';
  static const alreadyCompleted = 'Bạn đã hoàn thành kỳ học.';
  static const alreadyInRoom = 'Bạn đã ở trong một phòng.';
  static const wrongServer = 'Phòng thuộc server khác.';
  static const roomIsLocked = 'Phòng đã khóa.';
  static const groupIsFull = 'Nhóm đã đủ thành viên.';
  static const emptyRoomJoinDirectly = 'Phòng trống: hãy tham gia trực tiếp.';
  static const tooManyRequests = 'Bạn chỉ được có tối đa 3 yêu cầu chờ.';
  static const verifyEmailFirst = 'Hãy xác thực email trước.';
  static const invalidServer = 'Server không hợp lệ.';
  static const setupProfileFirst = 'Hãy thiết lập hồ sơ trước.';
  static const cannotChangeServer = 'Không thể đổi server lúc này.';
  static const userOrRoomMissing = 'Không tìm thấy hồ sơ hoặc phòng.';
  static const requestAlreadyPending = 'Yêu cầu đang chờ duyệt.';
  static const requestMissing = 'Yêu cầu không tồn tại.';
  static const membersApproveOnly = 'Chỉ thành viên được duyệt yêu cầu.';
  static const requestHandled = 'Yêu cầu đã được xử lý.';
  static const roomOrAccountMissing = 'Không tìm thấy phòng hoặc tài khoản.';
  static const notInRoom = 'Bạn không ở trong phòng này.';
  static const roomNameRequired = 'Tên phòng không được để trống.';
  static const membersRenameOnly = 'Chỉ thành viên được đổi tên phòng.';
  static const leaderLocksOnly = 'Chỉ trưởng nhóm được khóa phòng.';
  static const membersStartVoteOnly = 'Chỉ thành viên được bắt đầu bầu.';
  static const leaderExists = 'Phòng đã có trưởng nhóm.';
  static const voteActiveAlready = 'Đợt bầu vẫn đang diễn ra.';
  static const noActiveVote = 'Không có đợt bầu đang diễn ra.';
  static const voteExpired = 'Đợt bầu đã hết hạn.';
  static const voteCurrentMemberOnly = 'Chỉ được bầu thành viên hiện tại.';
  static const membersProposeDisbandOnly =
      'Chỉ thành viên được đề xuất giải tán.';
  static const disbandAlreadyProposed = 'Đã có đề xuất đang chờ.';
  static const disbandMissing = 'Không có đề xuất giải tán.';
  static const membersVoteOnly = 'Chỉ thành viên được biểu quyết.';
  static const disbandFinished = 'Đề xuất đã kết thúc.';
  static const adminVerifiedRequired = 'Cần tài khoản admin đã xác thực.';
  static const adminAccessDenied = 'Tài khoản không có quyền admin.';
  static const announcementFieldsRequired = 'Hãy nhập tiêu đề và nội dung.';
  static const pushFieldsInvalid = 'Thông tin gửi push không hợp lệ.';
  static const roomNotFound = 'Không tìm thấy phòng.';
  static const roomCountOrCapacityInvalid =
      'Số phòng hoặc sức chứa không hợp lệ.';
  static const capacityBelowMembers = 'Sức chứa thấp hơn số thành viên.';
  static const deleteEmptyRoomOnly = 'Chỉ xóa được phòng trống.';
  static const templateInvalid = 'Mẫu phòng không hợp lệ.';
  static const rolloverIdMissing = 'Thiếu mã chạy chuyển học kỳ.';
  static const rolloverNotDone = 'Chuyển học kỳ hiện tại chưa hoàn tất.';
  static const rolloverInProgress =
      'Một lượt chuyển học kỳ đang chạy. Hãy chờ hoặc thử lại sau 10 phút.';
  static const approve = 'Chấp nhận';
  static const reject = 'Từ chối';
  static const sampleDetail = 'Chi tiết phòng';
  static const sampleRoom = 'Phòng mẫu';
  static const sampleDetailHint = 'Chọn một phòng để xem chi tiết.';
  static const emailRequired = 'Vui lòng nhập email.';
  static const passwordRequired = 'Vui lòng nhập mật khẩu.';
  static const formPending = 'Kết nối tài khoản sẽ có ở bước tiếp theo.';
  static const goToRegister = 'Chưa có tài khoản? Đăng ký';
  static const goToLogin = 'Đã có tài khoản? Đăng nhập';
  static const openProfile = 'Mở hồ sơ';
  static const openRooms = 'Mở phòng';
  static const start = 'Bắt đầu';
  static const firebaseDebug = 'Kiểm tra Firebase';
  static const firebaseBackToLogin = 'Về đăng nhập';
  static const firebaseDebugIntro =
      'Chạy từng thao tác và xem kết quả hoặc lỗi nguyên văn bên dưới.';
  static const firebaseInitialize = 'Khởi tạo Firebase';
  static const firebaseRegister = 'Tạo tài khoản';
  static const firebaseSendVerification = 'Gửi email xác thực';
  static const firebaseReloadVerification = 'Tải lại trạng thái xác thực';
  static const firebaseSignIn = 'Đăng nhập Firebase';
  static const firebaseSignOut = 'Đăng xuất Firebase';
  static const firebaseWrite = 'Ghi tài liệu';
  static const firebaseRead = 'Đọc tài liệu';
  static const firebaseUpdate = 'Cập nhật tài liệu';
  static const firebaseDelete = 'Xóa tài liệu';
  static const firebaseListen = 'Nghe thay đổi trực tiếp';
  static const firebaseStopListen = 'Dừng nghe thay đổi';
  static const firebaseTransaction = 'Chạy giao dịch';
  static const firebaseBatch = 'Ghi lô ba tài liệu';
  static const firebaseQuery = 'Truy vấn quản trị viên';
  static const firebaseAuthSection = 'Tài khoản và xác thực';
  static const firebaseDataSection = 'Cloud Firestore';
  static const firebaseLog = 'Nhật ký';
  static const firebaseResults = 'Bảng kết quả';
  static const firebaseActionColumn = 'Thao tác';
  static const firebaseResultColumn = 'Kết quả';
  static const firebaseErrorColumn = 'Lỗi';
  static const firebaseNoLog = 'Chưa có nhật ký.';
  static const firebaseNoResults = 'Chưa có kết quả.';
  static const firebaseNotInitialized = 'Hãy khởi tạo Firebase trước.';
  static const firebaseNotSignedIn = 'Hãy đăng nhập trước.';
  static const firebaseEmailRequired = 'Hãy nhập email để kiểm tra.';
  static const firebasePasswordRequired = 'Hãy nhập mật khẩu để kiểm tra.';
  static const firebaseStatusOk = 'OK';
  static const firebaseStatusFailed = 'FAILED';
  static const firebaseNoError = '—';
  static const firebaseDocumentMissing = 'Tài liệu không tồn tại.';
  static const firebaseListening = 'Đang nghe thay đổi.';
  static const firebaseListeningStopped = 'Đã dừng nghe thay đổi.';
  static const firebaseDocumentExists = 'Tài liệu hiện có';
  static const firebaseDocumentAbsent = 'Tài liệu đã bị xóa';
  static String firebaseProject(String projectId) => 'Dự án: $projectId';
  static String firebaseUser(String uid) => 'UID: $uid';
  static String firebaseVerified(bool value) => 'Đã xác thực email: $value';
  static String firebaseCount(int value) => 'Số lượng: $value';
  static String firebaseCounter(int value) => 'Bộ đếm: $value';
  static String rolloverPreview(int completedStudents, int movedRooms,
          int movedStudents, int newRooms) =>
      'EXE2 hoàn thành: $completedStudents sinh viên. EXE1 chuyển lên EXE2: $movedRooms phòng, $movedStudents sinh viên. Tạo mới EXE1: $newRooms phòng.';
}
