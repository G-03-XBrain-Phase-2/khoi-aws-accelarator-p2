# Cách để install K8s

## 1. Requirement

Để chạy cụm Kubernetes cục bộ ổn định, hệ thống cần đáp ứng các điều kiện tối thiểu:
- Windows 10/11 phiên bản Pro, Enterprise hoặc Home
- Đã bật ảo hóa phần cứng trong BIOS 
- Cấu hình đề xuất: Tối thiểu 8GB RAM 
---

## 2. Quy trình cài đặt các công cụ thông qua CLI

Mở PowerShell với quyền Administrator và thực thi lần lượt các lệnh sau:

### Cài đặt Docker Desktop
```powershell
winget install Docker.DockerDesktop
```

### Cài đặt minikube
```powershell
winget install Kubernetes.minikube
```

### Cài đặt kubectl (Kubernetes CLI)
```powershell
winget install Kubernetes.kubectl
```

---

## 3. Xác minh cài đặt ban đầu

Sau khi cài đặt xong các công cụ và khởi động lại máy, mở lại terminal thông thường và kiểm tra phiên bản hoạt động để đảm bảo các tiến trình CLI đã được gán vào đường dẫn biến môi trường (PATH):

```bash
# Kiểm tra Docker CLI
docker --version

# Kiểm tra minikube CLI
minikube version

# Kiểm tra kubectl client
kubectl version --client
```

---

## 4. Khởi chạy và kiểm thử cụm minikube

### Khởi động cụm
Khởi động cụm minikube sử dụng Docker làm driver thực thi chính (đảm bảo ứng dụng Docker Desktop đã được mở trước đó):

```bash
minikube start --driver=docker
```

### Kiểm tra trạng thái cụm
```bash
# Kiểm tra tổng quan sức khỏe của minikube
minikube status

# Xem danh sách các node hiện có trong cụm cục bộ
kubectl get nodes
```

### Chạy thử nghiệm Workload để xác nhận khả năng kết nối mạng

Để kiểm tra xem cụm đã hoạt động hoàn toàn ổn định chưa, chúng ta thực hiện triển khai thử nghiệm một ứng dụng nginx đơn giản và truy cập thử qua Service:

1. **Khởi tạo Deployment nginx**:
   ```bash
   kubectl create deployment test-nginx --image=nginx:alpine
   ```

2. **Theo dõi trạng thái Pod cho đến khi chuyển sang Running**:
   ```bash
   kubectl get pods
   ```

3. **Expose ứng dụng ra cổng ngoài thông qua Service NodePort**:
   ```bash
   kubectl expose deployment test-nginx --port=80 --type=NodePort
   ```

4. **Lấy địa chỉ truy cập trực tiếp từ máy host**:
   ```bash
   minikube service test-nginx --url
   ```
   *Kết quả*: Lệnh trên sẽ trả về một địa chỉ IP nội bộ kèm cổng (ví dụ: `http://127.0.0.1:56789`). Chúng ta có thể mở trình duyệt trên máy host truy cập vào đường dẫn này để xác nhận trang chào mừng của nginx hiển thị thành công.

5. **Dọn dẹp tài nguyên sau khi kiểm thử**:
   ```bash
   kubectl delete service test-nginx
   kubectl delete deployment test-nginx
   ```

6. **Tắt cụm minikube khi không sử dụng để tiết kiệm RAM**:
   ```bash
   minikube stop
   ```
