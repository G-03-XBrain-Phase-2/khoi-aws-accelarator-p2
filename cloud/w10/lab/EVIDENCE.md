# EVIDENCE - PHÁT HIỆN DỮ LIỆU NHẠY CẢM TRONG S3 BẰNG AMAZON MACIE

## Người thực hiện

- Họ tên: Nguyễn Đăng Khôi
- Xbrain ID: XB-DN26-058
## 1. Mục tiêu

Thiết lập Amazon Macie để phát hiện dữ liệu nhạy cảm trong Amazon S3 bucket và gửi email cảnh báo thông qua Amazon EventBridge và Amazon SNS.

Luồng hoạt động:

```text
Sample files
     ↓
Amazon S3 Bucket
     ↓
Amazon Macie Job
     ↓
Macie Finding
     ↓
Amazon EventBridge Rule
     ↓
SNS Topic
     ↓
Email Notification
```

---

## 2. Các bước thực hiện

### Bước 1: Tạo S3 Bucket và Upload sample files

* Screenshot S3 Bucket
![S3 Bucket](images/s3-bucket.png)

* Screenshot file sample
![S3 Uploaded Sample File](images/s3-uploaded-sample-file.png)

---

### Bước 2: Tạo SNS Topic và Email Subcription

* Screenshot SNS Topic.
![SNS Topic](images/sns-topic.png)

* Screenshot SNS Email Subscription
![SNS Subscription Confirmed](images/sns-subscription-confirmed.png)

---

### Bước 3: Tạo EventBridge Rule kết nối với Macie Finding


* Screenshot EventBridge Rule Pattern
![EventBridge Rule Pattern](images/eventbridge-rule-pattern.png)

* Screenshot EventBridge Rule & SNS Topic
![EventBridge Rule Target](images/eventbridge-rule-target.png)

---

### Bước 4: Bật Amazon Macie

Đã bật Amazon Macie tại Region:

* Screenshot Amazon Macie
![Macie Enabled](images/macie-enabled.png)

---

### Bước 5: Tạo Macie Sensitive Data Discovery Job

* Screenshot config Macie Job.
![Macie Job Config](images/macie-job-config.png)

* Screenshot Macie Job completed.
![Macie Job Complete](images/macie-job-complete.png)

---

### Bước 6: Xác nhận Macie Findings và email cảnh báo

* Screenshot Macie Findings.
![Macie Findings](images/macie-findings.png)

* Screenshot Finding details.
![Macie Finding Detail](images/macie-finding-detail.png)

* Screenshot email cảnh báo Macie Finding nhận được từ AWS SNS.
![Macie Email Notification](images/macie-email-notification.png)

