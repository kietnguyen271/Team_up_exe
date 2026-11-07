# Luồng trình bày Lab 3

Các sơ đồ này dùng cùng [đặc tả hiện hành](TEAMUP_SPEC.md). Mỗi mũi tên là một lời gọi hoặc thay đổi dữ liệu cần giải thích khi demo.

## 1. Đăng ký và phân quyền

```mermaid
flowchart LR
  A[Android: đăng ký] --> B[Firebase Auth]
  B --> C[Email xác thực]
  C --> D[App kiểm tra emailVerified]
  D --> E{admins/emailLowercase?}
  E -->|Có| F[Admin Android]
  E -->|Không| G[Hồ sơ và chọn EXE]
  G --> H[Sinh viên Android]
```

Auth xác định tài khoản; tài liệu `admins` xác định vai trò. `firestore.rules` kiểm quyền ở máy chủ cho từng thao tác. Mã: `lib/core/router/app_router.dart`, `lib/features/admin/domain/admin_access_service.dart`, `firestore.rules`.

## 2. Tham gia phòng và yêu cầu

```mermaid
flowchart LR
  A[Sinh viên chọn phòng] --> B{Phòng trống?}
  B -->|Có| C[Transaction đọc user và room]
  C --> D[Cập nhật memberIds và roomId]
  B -->|Không| E[Nhập lời nhắn]
  E --> F[joinRequests/uid pending]
  F --> G[Thành viên duyệt/từ chối]
  G --> H{Còn chỗ, chưa khóa, user chưa vào phòng?}
  H -->|Có| D
  H -->|Không| I[Từ chối hoặc hết hạn]
```

Transaction đọc lại dữ liệu khi ghi để tránh hai người cùng chiếm chỗ cuối. Mã: `lib/features/team/data/firebase_team_repository.dart`, `lib/features/team/domain/team_policy.dart`.

## 3. Bình chọn và giải tán

```mermaid
flowchart LR
  A[Thành viên mở phiên 24 giờ] --> B[Mỗi thành viên bỏ/đổi phiếu]
  B --> C{Quá nửa?}
  C -->|Có| D[Chốt trưởng nhóm]
  C -->|Không| E{Hết hạn?}
  E -->|Có| F[Nhiều phiếu nhất duy nhất?]
  F -->|Có| D
  F -->|Không| G[Chưa có trưởng nhóm]
  H[Đề xuất giải tán] --> I[Tất cả thành viên đồng ý]
  I --> J[Trả room về trống]
```

Phiếu được tính theo thành viên hiện tại. Mã: `lib/features/team/domain/team_policy.dart` và `lib/features/team/data/firebase_team_repository.dart`.

## 4. Token, push và nhận tin

```mermaid
flowchart LR
  A[FCM cấp token cho bản cài] --> B[Android xin quyền và getToken]
  B --> C[users/uid/fcmTokens/token]
  D[Thay đổi Firestore hoặc admin gửi thủ công] --> E[notificationJobs]
  E --> F[Node worker giữ service account]
  F --> G[Firebase Cloud Messaging]
  C --> F
  G --> H[Android banner/notification]
  H --> I[Nhấn: mở roomId nếu có]
```

Token gắn với bản cài, không phải UID. Worker tìm token của người nhận hoặc gửi topic phòng. Không nhúng service account trong APK. Mã: `lib/core/notifications/`, `push_worker/worker.js`, `push_worker/events.js`, `push_worker/message.js`.

## 5. Crashlytics demo

```mermaid
flowchart LR
  A[Android: Gây crash] --> B[Ghi crashDemoEvents]
  B --> C[FirebaseCrashlytics.crash]
  C --> D[Mở lại app]
  D --> E[SDK gửi báo cáo]
  E --> F[Firebase Console: Crashlytics]
  B --> G[Admin Android: Nhật ký demo]
```

`crashDemoEvents` là dấu mốc demo; báo cáo crash thật ở Firebase Console. Mã: `lib/main.dart`, `lib/features/crash_demo/`.

## 6. Chuyển học kỳ

```mermaid
flowchart LR
  A[Admin Android: xem trước] --> B[Nhập HOAN TAT]
  B --> C[rollover/current: runId, step, lease]
  C --> D[EXE2: hoàn thành và xóa phòng]
  D --> E[EXE1: chuyển sang EXE2]
  E --> F[Tạo EXE1 mới từ roomTemplate]
  F --> G[Đánh dấu done]
  C --> H[Nếu gián đoạn: tiếp tục từ step]
```

Mỗi bước có thể chạy lại, phòng tạo mới dùng ID theo `runId` để không bị nhân đôi. Lệnh chạy trong Flutter Android bằng Firestore transaction/batch; worker Node chỉ gửi FCM. Mã: `lib/features/admin/domain/rollover_engine.dart`, `lib/features/admin/data/firebase_admin_repository.dart`.
