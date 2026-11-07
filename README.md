# TeamUp EXE

Đặc tả đã cập nhật theo quyết định **Flutter Android cho cả sinh viên và admin**, các luồng và tiêu chí bàn giao: [docs/TEAMUP_SPEC.md](docs/TEAMUP_SPEC.md).

Ứng dụng Flutter Material 3 cho **Android**. Sinh viên và quản trị viên dùng cùng một APK; sau khi đăng nhập, ứng dụng kiểm tra `admins/{email viết thường}` để mở đúng giao diện. Không dùng bản Windows hoặc Web để chấm bài. Dự án Firebase là `teamup-exe`, gói Android là `com.teamup.teamup_exe`.

## Chuẩn bị Firebase

1. Trong Firebase Console, bật Authentication → Email/Password, Cloud Firestore, Cloud Messaging và Crashlytics.
2. `lib/firebase_options.dart` và `android/app/google-services.json` đã có cấu hình Android. Nếu cần tạo lại trên tài khoản của bạn, chạy **chính xác**:

   ```powershell
   flutterfire configure --project=teamup-exe --platforms=android
   ```

3. Tạo tài liệu `admins/kietntse183979@fpt.edu.vn` (hoặc email quản trị thật, luôn viết thường) bằng Firebase Console. Nội dung tối thiểu: `addedAt` kiểu Timestamp. Tài khoản đó phải xác thực email. Không có nút tự cấp quyền admin trong app.
4. Xem [firestore.rules](firestore.rules) và triển khai thủ công từ Firebase Console hoặc bằng Firebase CLI của bạn. App không tự triển khai rules. Trước khi triển khai, chạy các ca kiểm thử bảo mật trong [docs/SECURITY.md](docs/SECURITY.md).

   ```powershell
   firebase deploy --only firestore:rules --project teamup-exe
   ```
5. Tạo `servers/exe1` và `servers/exe2` trong Firestore nếu muốn có mẫu phòng. Ví dụ `servers/exe1`: `{name: "EXE1", roomTemplate: [{name: "Room 1", capacity: 5}]}`. Quản trị viên cũng có thể sửa mẫu phòng ngay trong app.

## Chạy Android

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <android-device-id>
```

Dùng điện thoại Android thật, bật USB debugging. Bản hiện tại yêu cầu Android API 24 trở lên. NDK `28.2.13676358` đã được cài lại; APK debug đã build thành công bằng `cd android; .\gradlew.bat assembleDebug` và nằm ở `build/app/outputs/flutter-apk/app-debug.apk`. Để chạy trên điện thoại, kết nối USB, chấp nhận quyền gỡ lỗi trên máy và chạy `flutter run -d <android-device-id>` hoặc cài APK debug đã build.

Đăng ký bằng email `@fpt.edu.vn` hoặc `@fe.edu.vn`, mật khẩu ít nhất 8 ký tự, mở email xác thực, rồi thiết lập tên, giới thiệu và kỹ năng. `--dart-define=ALLOW_ANY_EMAIL=true` chỉ dành cho bản debug. Quản trị viên được nhận diện bằng tài liệu `admins/{email viết thường}` và vào giao diện quản trị trên **Android**.

## Chức năng

- **Sinh viên:** chọn EXE1/EXE2, tìm phòng, xem thành viên và kỹ năng, tham gia phòng trống hoặc gửi yêu cầu vào phòng có người; duyệt/từ chối/hủy yêu cầu, bầu trưởng nhóm, khóa phòng, rời hoặc giải tán phòng; xem thông báo và gợi ý kỹ năng.
- **Quản trị viên:** tạo phòng hàng loạt, sửa tên/sức chứa/mẫu phòng, xóa phòng trống; xem trước và xác nhận chuyển học kỳ, tiếp tục lượt chạy lỗi; tạo thông báo, xếp hàng gửi FCM tới phòng/server/người dùng/tất cả, xem trạng thái gửi và nhật ký Crashlytics demo.
- **Crashlytics:** trong Hồ sơ có nút ghi lỗi và nút gây crash. Nút gây crash ghi `crashDemoEvents` trước, sau đó đóng app. Mở lại app và chờ vài phút để xem báo cáo trong Firebase Console. Nhật ký sự kiện hiển thị trong tab quản trị.
- **FCM:** sau khi đăng nhập và xác thực email, app xin quyền thông báo, lưu token trong `users/{uid}/fcmTokens/{token}`, tự cập nhật token và tự theo dõi topic `room_<id>` của phòng hiện tại. Đăng xuất sẽ gỡ token/topic. Màn hình `/debug-firebase` chỉ có trong bản debug để xem/copy token, thử quyền/topic và các thao tác Firebase.

### Gửi push trên gói Spark

Không dùng Cloud Functions. Admin Android tạo một tài liệu `notificationJobs`; tiến trình Node trong [push_worker](push_worker/README.md) chạy bằng Firebase Admin SDK ở máy/server riêng để gửi FCM rồi ghi kết quả. Worker cũng theo dõi các thay đổi Firestore để tạo push theo sự kiện tham gia, bầu, khóa, giải tán và chuyển kỳ. Nếu worker chưa chạy, push thủ công sẽ **Đang chờ**; thay đổi xảy ra trước khi worker bắt đầu lần đầu có thể không tạo push tự động. Khóa service account **không** đưa vào app, repo hoặc lời nhắn.

Gợi ý nội dung trình bày và vị trí mã cho Lab 3 nằm trong [docs/LAB3_NOTES.md](docs/LAB3_NOTES.md); sơ đồ các luồng nằm trong [docs/FLOWS.md](docs/FLOWS.md).

### Gợi ý AI

Mặc định gợi ý kỹ năng dùng logic Dart cục bộ, không cần mạng. Nếu đã bật **Firebase AI Logic → Gemini Developer API** cho dự án trong Firebase Console, có thể chạy `flutter run -d <device> --dart-define=USE_FIREBASE_AI=true` để dùng Gemini. Mọi lỗi gọi AI tự chuyển về gợi ý cục bộ. Có thể đổi model bằng `--dart-define=TEAMUP_GEMINI_MODEL=<model>`; hiện dùng `gemini-3.8-flash`. Không lưu API key thô trong app.

## Mô hình Firestore

`admins/{emailLowercase}`, `users/{uid}`, `users/{uid}/fcmTokens/{token}`, `servers/{exe1|exe2}`, `rooms/{roomId}`, `rooms/{roomId}/joinRequests/{uid}`, `rooms/{roomId}/voteSession/current`, `rooms/{roomId}/voteSession/current/ballots/{uid}`, `rooms/{roomId}/disband/current`, `rollover/current`, `announcements/{id}`, `notificationJobs/{id}`, `crashDemoEvents/{id}`. Route debug dùng `_smoke/{uid}`.

Các truy vấn hiện chỉ lọc hoặc sắp xếp theo **một trường** (`rooms.serverId`, `announcements.createdAt`, `notificationJobs.createdAt`, `crashDemoEvents.timestamp`), nên chưa cần chỉ mục tổng hợp. Nếu Firebase Console báo thiếu index sau khi đổi truy vấn, tạo theo liên kết lỗi mà Console cung cấp.

## Giới hạn cần kiểm tra trước khi chấm

Mã đã qua kiểm thử Dart/widget, nhưng cần chạy trên điện thoại thật để xác nhận Auth, Rules, FCM, Crashlytics và luồng chuyển học kỳ với dữ liệu Firebase thật. Các Firestore Rules chưa được triển khai hoặc kiểm thử bằng emulator trong môi trường này. Upload tệp nhóm chưa triển khai theo trao đổi hiện tại.
