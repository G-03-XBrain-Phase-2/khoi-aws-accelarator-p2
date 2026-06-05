# W8 Learning Journal & Reflection — Foundation: IaC & K8s

## Nhật ký Học tập Hàng ngày (Daily Journal)

### Thứ Hai, 01/06/2026 — Day A: Terraform Foundations
#### Bản chất IaC: Nắm rõ mô hình **Declarative (Khai báo)** của Terraform so với Imperative (Mệnh lệnh) của Ansible/Script. Việc khai báo trạng thái mong muốn giúp hệ thống tự động xử lý Idempotency, quản lý vòng đời tài nguyên một cách tối ưu.
#### Arguments vs Attributes: Phân biệt rõ Arguments là cấu hình cấu trúc đầu vào viết trong code (ví dụ: `algorithm = "RSA"`), còn Attributes là các thuộc tính đầu ra chỉ được sinh ra sau khi tạo tài nguyên thành công ở runtime (ví dụ: `private_key_pem`).

### Thứ Ba, 02/06/2026 — Day B: Kubernetes Architecture
#### Kiến trúc hệ thống: Nắm rõ vai trò của Control Plane trong việc ra quyết định toàn cục và Worker Node trong việc thực thi container. Hiểu sâu cơ chế tương tác thông qua watch event của API Server
#### Tài nguyên Pod & Service: Hiểu rõ Pod là đơn vị chia sẻ chung network/storage namespace giữa các container.

### Thứ Tư, 03/06/2026 — Day C: State Management
#### Remote State & Locking: Hiểu rõ sự cần thiết của việc đưa tệp State lên lưu trữ tập trung tại AWS S3 để làm việc nhóm đồng bộ và bật Versioning tránh mất mát dữ liệu. Nắm vững cơ chế hoạt động của State Locking thông qua thuộc tính khóa `LockID` ở bảng DynamoDB giúp ngăn chặn hiện tượng Race Condition
####Cấu trúc Modules: Thấu hiểu triệt để nguyên lý DRY (Don't Repeat Yourself) khi đóng gói tài nguyên hạ tầng. Nắm chắc cấu trúc đóng gói biệt lập của Child Module qua 3 tệp tiêu chuẩn (`main.tf`, `variables.tf`, `outputs.tf`) và cách gọi module qua các nguồn cục bộ (Local) hoặc từ xa (Git, Registry).
