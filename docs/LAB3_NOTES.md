# Ghi chú demo Lab 3

## Sơ đồ giải thích trên slide

`Flutter Android (sinh viên/admin) → Firebase Auth → Firestore` cho dữ liệu phòng. Quản trị viên ghi `notificationJobs`, hoặc worker quan sát thay đổi Firestore và tạo job tự động → worker Node dùng Firebase Admin SDK → FCM topic `room_<id>` hoặc danh sách token → Flutter Android nhận thông báo. Flutter Android gửi lỗi → Crashlytics → quản trị viên xem Firebase Console; sự kiện demo tương ứng nằm trong tab **Nhật ký demo**. Xem [đặc tả hiện hành](TEAMUP_SPEC.md).

## Câu hỏi thường gặp

**FCM token là gì và ai cấp?** Firebase Cloud Messaging cấp token cho một bản cài đặt ứng dụng. Nó không phải UID hay mật khẩu. `NotificationService.startForUser` xin quyền, gọi `getToken` và `FirestoreFcmTokenStore.save` lưu token tại `users/{uid}/fcmTokens/{token}`. Luồng `onTokenRefresh` thay token cũ; đăng xuất xóa token khỏi Firestore và thiết bị.

**Gửi message ở đâu?** Admin Android tạo `notificationJobs` trong `FirebaseAdminRepository.queueBroadcastPush`. Worker ngoài app ở `push_worker/worker.js` dùng service account và `firebase-admin/messaging` để gửi tới topic hoặc token. Worker cũng quan sát tài liệu phòng/yêu cầu/bầu/giải tán và sinh job sự kiện. Mã khóa service account không nằm trên client. Trong Flutter, `NotificationRuntime` hiện banner khi app ở foreground, xử lý nhấn thông báo và mở `/rooms/:roomId`; `fcm_background_handler.dart` đăng ký handler nền.

**Vì sao cần Firestore transaction?** Khi hai người cùng bấm tham gia hoặc duyệt, transaction đọc lại phòng và hồ sơ, kiểm tra chỗ trống/trạng thái rồi ghi cả hai phía. Nếu tài liệu đọc bị đổi, Firestore thử lại transaction. Các thao tác nhiều tài liệu như chuyển học kỳ dùng batch tối đa 400 ghi, ghi tiến độ tại `rollover/current` và có thể tiếp tục sau lỗi.

**Crashlytics demo thế nào?** Nút **Gây crash** ghi `crashDemoEvents` trước rồi gọi `FirebaseCrashlytics.instance.crash()`. Mở lại app sau crash để SDK gửi báo cáo; quản trị viên xem báo cáo thật trong Firebase Console. Tab **Nhật ký demo** của app chỉ đọc tài liệu sự kiện đã ghi, không thay thế giao diện Crashlytics của Console.

**AI chạy thế nào?** Card kỹ năng luôn có `LocalSkillSummaryService`. Khi bật `USE_FIREBASE_AI=true`, `GeminiSkillSummaryService` gọi Firebase AI Logic từ Android; `FallbackSkillSummaryService` chuyển sang logic cục bộ nếu API lỗi. Không đặt API key bí mật trong ứng dụng.

## Thứ tự demo trên điện thoại thật

1. Đăng ký sinh viên, xác thực email, tạo hồ sơ và chọn EXE1.
2. Vào phòng trống, dùng tài khoản thứ hai gửi yêu cầu và duyệt; bầu trưởng nhóm, khóa/mở khóa.
3. Admin Android tạo thông báo và push tới phòng/server/UID/tất cả; cho xem token/topic, trạng thái worker và tin nhắn đến thiết bị. Thử thêm yêu cầu vào phòng để thấy push tự động.
4. Chạy lỗi không gây crash, rồi nút gây crash; mở lại app, kiểm tra Firebase Console và nhật ký admin.
5. Admin xem trước chuyển học kỳ, nhập `HOAN TAT`, kiểm tra EXE2 hoàn thành và EXE1 được tạo lại.

Chuẩn bị dữ liệu trên một dự án Firebase thử nghiệm; không chạy chuyển học kỳ trên dữ liệu thật khi chưa kiểm tra Rules và dự phòng dữ liệu.
