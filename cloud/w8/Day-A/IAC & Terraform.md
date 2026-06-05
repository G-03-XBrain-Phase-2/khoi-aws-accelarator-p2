\#Khái niệm về Infrastructure as Code

* Cơ sở hạ tầng dưới dạng code hay còn được gọi là Infrastructure as Code là một khái niệm tối giản việc thiết lập/quản lý những stack trước kia của hệ thống thông qua việc định nghĩa chúng trong 1 file script chẳng hạn thay vì tốn thời gian và công sức setup manual từng thứ. Việc này dễ dàng quản lý nền tang hệ thống cơ sở hạ tầng.

\#Terraform là gì

* Terraform là công nghệ IaC được phát triển bơi HashiCorp, chuyên dùng để cung cấp Infrastructure, ta chỉ việc viết code, rồi gõ một vài câu lệnh đơn giản, nó sẽ tạo ra Infrastructure cho ta.
* Terraform sẽ hoạt động bằng cách đọc code của chúng ta, ta gõ câu lệnh, đợi Terraform cấp Infra, sau khi Terraform tạo xong sẽ chuyển sang dạng Terraform State để lưu lại cấu trúc hiện tại.

\#Tại sao nên xài Terraform?

* Dễ xài
* Mã nguồn mở và miễn phí
* Declarative programing: chỉ diễn tả những thứ bạn cần và Terraform làm cho bạn
* Có thể cung cấp hạ tầng cho nhiều Cloud khác nhau như AWS, GCP, Azure trong cùng một tệp tin cấu hình (Cloud-Agnostic)

