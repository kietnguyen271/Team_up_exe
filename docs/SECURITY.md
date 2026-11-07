# Kiểm tra Firestore Rules trước khi triển khai

Rules trong `firestore.rules` yêu cầu tài khoản đã xác thực email. Tài liệu admin do người quản lý tạo bằng Firebase Console; client không được tự tạo hoặc sửa quyền admin.

## Checklist thủ công

Sử dụng ít nhất hai tài khoản sinh viên đã xác thực, một tài khoản chưa xác thực và một tài khoản admin. Chạy trên Firebase Emulator Suite hoặc dự án thử nghiệm trước khi triển khai lên dữ liệu thật.

1. Chưa đăng nhập/chưa xác thực: không đọc được `users`, `rooms`, `servers`, `announcements`.
2. Sinh viên A chỉ sửa được tên, giới thiệu, kỹ năng của A; không đổi `status` hoặc `serverId`/`roomId` tùy ý và không sửa hồ sơ B.
3. Sinh viên không thể tạo/xóa phòng, đổi sức chứa/mẫu phòng, tạo thông báo hoặc ghi `rollover/current`.
4. Sinh viên chỉ tạo yêu cầu tham gia dưới UID của mình; thành viên phòng mới có thể duyệt/từ chối. Kiểm tra phòng đã khóa/đủ chỗ, quá hạn 48 giờ và tối đa ba yêu cầu.
5. Tham gia/rời phòng cập nhật đồng thời `rooms.memberIds` và `users/{uid}.roomId`; giả lập chỉ ghi một phía phải bị từ chối.
6. Chỉ trưởng nhóm khóa/mở khóa; chỉ thành viên đổi tên; sinh viên ngoài phòng không bỏ phiếu hoặc duyệt giải tán.
7. Sinh viên chỉ ghi ballot mang UID của mình và ứng viên hiện là thành viên.
8. Admin có thể quản lý phòng, máy chủ, thông báo và chuyển học kỳ; sinh viên không thể đọc `crashDemoEvents` của người khác hoặc `notificationJobs`.
9. Khi đăng xuất, kiểm tra token đã bị xóa ở `users/{uid}/fcmTokens` và topic phòng đã được bỏ theo dõi.
10. Thử chuyển học kỳ với EXE2 và EXE1 có số phòng khác nhau, phòng khóa, phiếu bầu/yêu cầu chờ, lỗi giữa chừng và chạy lại. Xác nhận không mất dữ liệu EXE1 và không tạo phòng lặp.

## Giới hạn của rules

- Rules không thể tự kiểm đếm chính xác toàn bộ phiếu, số yêu cầu đang chờ ở các phòng khác nhau, hoặc xác minh nội dung gợi ý AI; logic client dùng transaction và dữ liệu tổng hợp. `pendingRequestIds` là bộ đếm trên hồ sơ mà client có thể sửa, nên giới hạn ba yêu cầu chưa chống gian lận từ client bị sửa đổi. Client bị sửa đổi cũng có thể thử giả mạo kết quả bầu; để chống gian lận mạnh cần backend đáng tin cậy hoặc mô hình dữ liệu/rules chặt hơn.
- Những transaction lớn có thể chạm giới hạn số lần `get()`/`getAfter()` của Rules dù batch dưới 400 ghi. Thử với số thành viên thực tế trước khi chạy chuyển học kỳ hoặc giải tán phòng lớn.
- `notificationJobs` chỉ admin tạo; Firebase Admin SDK của worker bỏ qua Rules và phải giữ service account an toàn. Topic FCM không phải cơ chế phân quyền dữ liệu nhạy cảm; không gửi thông tin bí mật trong push.
- Các thao tác dọn subcollection chạy sau transaction thay đổi phòng; nếu mạng ngắt giữa chừng, dữ liệu phụ có thể còn lại và cần kiểm tra/tiếp tục dọn thủ công. Quy tắc cốt lõi về thành viên nằm trên `rooms` và `users`.
