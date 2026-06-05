# Khái Niệm

Kubernetes (K8s) là một hệ thống mã nguồn mở dùng để tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng dưới dạng container. Để vận hành hệ thống một cách hiệu quả, ta cần hiểu rõ kiến trúc phân rã thành hai phân vùng chính: Control Plane và Worker Nodes

##  Control Plane

Control Plane đóng vai trò là bộ não của cụm (cluster), chịu trách nhiệm đưa ra các quyết định toàn cục (ví dụ: lên lịch chạy ứng dụng), phát hiện và phản hồi các sự kiện trong cụm.

```text
+-----------------------------------------------------------+
|                      CONTROL PLANE                        |
|                                                           |
|  +------------+     +----------------+     +-----------+  |
|  | Scheduler  |     |   API Server   |     |Controller |  |
|  +-----+------+     +-------+--------+     |  Manager  |  |
|        |                    |              +-----+-----+  |
|        +---------+----------+                    |        |
|                  |                               |        |
|            +-----+-----+                         |        |
|            |   etcd    | <-----------------------+        |
|            +-----------+                                  |
+-----------------------------------------------------------+
```

## 2. Worker Node

Worker Node là các máy ảo hoặc máy vật lý chạy các ứng dụng thực tế dưới dạng container. Mỗi node được Control Plane quản lý và chứa các dịch vụ cần thiết để vận hành Pod.

```text
+-----------------------------------------------------------+
|                       WORKER NODE                         |
|                                                           |
|  +--------------------+             +------------------+  |
|  |      Kubelet       |             |    Kube-proxy    |  |
|  +---------+----------+             +--------+---------+  |
|            |                                 |            |
|            ▼ (CRI)                           ▼            |
|  +--------------------+             +------------------+  |
|  | Container Runtime  |             | iptables / IPVS  |  |
|  | (containerd)       |             | (Traffic routing)|  |
|  +--------------------+             +------------------+  |
+-----------------------------------------------------------+
```

## 3. Luồng khởi tạo tài nguyên Pod trong hệ thống

Để hình dung sự phối hợp nhịp nhàng giữa các thành phần trên, chúng ta cùng xem xét luồng xử lý khi thực thi lệnh khởi tạo một Pod (`kubectl apply -f pod.yaml`):

```text
[Người dùng]
     │ (kubectl apply)
     ▼
[API Server] ──► (1. Xác thực, phân quyền & lưu trạng thái Pending vào etcd)
     │
     ▼ (Watch event)
[Scheduler]  ──► (2. Phát hiện Pod mới, tính toán và chọn Node X phù hợp)
     │
     ▼ (Ghi nhận gán node)
[API Server] ──► (3. Lưu thông tin phân bổ Node X vào etcd)
     │
     ▼ (Watch event)
[Kubelet Node X] ──► (4. Phát hiện Pod được gán cho mình, gọi CRI khởi tạo)
     │
     ▼ (CRI call)
[Container Runtime] ──► (5. Kéo image và chạy container thực tế)
     │
     ▼ (Báo cáo sức khỏe)
[Kubelet Node X] ──► (6. Cập nhật trạng thái Running lên API Server để lưu vào etcd)
```
