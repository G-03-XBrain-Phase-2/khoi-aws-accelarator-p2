\#Cấp credentials

* Tạo credentials dưới dạng \~/credentials với nội dung

```sh

\[default]

aws\_access\_key\_id=<your-key>

aws\_secret\_access\_key=<your-key>

```

\#Tạo terraform

* Đặt một file gọi là main.tf

```sh
provider "aws" {

&#x20; region = "us-west-2"

}
```

* Ta chỉ định ta sử dụng provider tên là aws, và resource của ta sẽ được tạo ở Region là us-west-2. Sau đó ta thêm vào đoạn code tạo EC2 vào main.tf



```sh

provider "aws" {

&#x20; region = "us-west-2"

}



resource "aws\_instance" "hello" {

&#x20; ami           = "ami-09dd2e08d601bff67"

&#x20; instance\_type = "t2.micro"

&#x20; tags = {

&#x20;   Name = "HelloWorld"

&#x20; }

}

```

\#Chạy terraform

* Sau khi hoàn thành hết các bước tạo và cấu hình, mở terminal lên và gõ lệnh 

```sh

terraform init

```

* Sau khi chạy xong thì gõ tiếp câu lệnh apply cho EC2 cho ta.

```sh

terraform apply -auto-approve

```

* Giờ muốn xóa EC2 đi thì xài lệnh destroy.

```sh

terraform destroy -auto-approve

```





