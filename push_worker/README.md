# FCM push worker

Admin Android ghi lệnh vào `notificationJobs`; worker đọc các lệnh đang chờ, gửi tới phòng/server/UID/tất cả bằng Firebase Admin SDK, rồi ghi `sent` hoặc `failed`. Worker cũng theo dõi `rooms`, `joinRequests`, `voteSession`, `disband` để tạo push theo sự kiện. Cloud Functions không được dùng. Worker phải chạy trên máy/server có mạng trong lúc demo.

```powershell
cd push_worker
npm ci
$env:GOOGLE_APPLICATION_CREDENTIALS='C:\duong-dan-rieng\service-account.json'
$env:FIREBASE_PROJECT_ID='teamup-exe'
node worker.js
```

Tải service account từ Firebase Console → Project settings → Service accounts và giữ tệp **ngoài** thư mục dự án. Không đưa khóa vào Flutter, Git hoặc chat. Worker dùng Application Default Credentials; sau khi khởi động, trong app admin chọn **Thông báo → Gửi push** và xem trạng thái trong danh sách bên dưới.

FCM token do Firebase cấp riêng cho mỗi bản cài đặt ứng dụng. Client xin quyền thông báo, lấy token, lưu vào `users/{uid}/fcmTokens/{token}`, cập nhật khi token đổi và xóa khi đăng xuất. Client đăng ký topic của phòng đang tham gia; worker dùng topic đó cho push thủ công theo phòng. Push theo sự kiện và theo server/UID/tất cả dùng danh sách token. Client nhận foreground trong banner, nhận background theo handler và mở phòng từ `data.roomId` khi người dùng nhấn thông báo. Topic không phải cơ chế bảo mật; nội dung push không nên chứa dữ liệu riêng tư.

Chạy kiểm thử payload và sự kiện bằng `npm test`. Worker có cơ chế thử lại lệnh kẹt ở trạng thái `sending`, nhưng FCM không bảo đảm chính xác một lần gửi khi tiến trình chết ngay sau khi FCM nhận message. Checkpoint `_workerState` giúp phát hiện thay đổi tài liệu khi worker khởi động lại; lần đầu worker thấy dữ liệu sẵn có sẽ lấy làm mốc, không gửi lại toàn bộ sự kiện cũ. Khi chấm demo, khởi động worker trước rồi tạo sự kiện mới và xác nhận bản ghi `sent`.
