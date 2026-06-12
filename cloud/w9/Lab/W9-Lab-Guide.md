**W9 --- EVIDENCE PACK**

# PHẦN 1: GitOps & CI/CD

## Lab 0 --- Dựng cụm + Tạo repo GitHub

**Bước 1: Khởi động cụm minikube**

![](./media/image1.png){width="6.5in" height="3.2930555555555556in"}

**Bước 2: Tạo cấu trúc thư mục local**

![](./media/image2.png){width="6.5in" height="4.763888888888889in"}

**Bước 3: Viết file k8s/web.yaml**

![](./media/image3.png){width="6.5in" height="3.5395833333333333in"}

**Bước 4: Đẩy lên GitHub**

![](./media/image4.png){width="6.5in" height="3.259027777777778in"}

## Lab 1 --- Cài ArgoCD vào cụm

**Bước 1: Tạo namespace + cài ArgoCD**

![](./media/image5.png){width="6.5in" height="2.96875in"}

**Bước 2: Chờ ArgoCD sẵn sàng**

![](./media/image6.png){width="6.5in" height="3.4409722222222223in"}

## Lab 2 --- Tạo Application → ArgoCD tự sync

**Bước 1: Tạo thư mục argocd/apps và viết Application**

![](./media/image7.png){width="6.5in" height="4.719444444444444in"}

![](./media/image8.png){width="5.772494531933508in"
height="3.584990157480315in"}

**Bước 2: Apply Application bằng tay (lần này phải tay, Lab 5 mới dùng
root)**

![](./media/image9.png){width="6.5in" height="5.259722222222222in"}

## Lab 3 --- Sync & Self-heal

![](./media/image10.png){width="6.5in" height="5.653472222222222in"}

## Lab 4 --- Rollback bằng git revert

![](./media/image11.png){width="6.5in" height="3.7069444444444444in"}

## Lab 5 --- app-of-apps (1 root quản nhiều app)

**Bước 1: Tạo file root.yaml**

![](./media/image12.png){width="6.5in" height="3.682638888888889in"}

**Bước 2: Push và apply root 1 lần duy nhất**

![](./media/image13.png){width="6.5in" height="4.756944444444445in"}

## Lab 6 --- Sync waves (Ép thứ tự apply)

**Bước 1: Tạo k8s/namespace.yaml với wave -1**

![](./media/image14.png){width="6.5in" height="2.102777777777778in"}

**Bước 2: Cập nhật k8s/web.yaml --- thêm ConfigMap + 3 sync-wave**

![](./media/image15.png){width="5.760239501312336in"
height="5.788547681539807in"}

**Bước 3: Push và quan sát**

![](./media/image16.png){width="6.5in" height="3.497916666666667in"}

## Lab 7 --- CI: Validate YAML + Branch Protection

![](./media/image17.png){width="6.5in" height="3.0277777777777777in"}

# PHẦN 2 --- Observability + Canary

## Lab 1 --- Cài Prometheus + Argo Rollouts (qua GitOps)

**Bước 1: Tạo file Application cho kube-prometheus-stack**

![](./media/image18.png){width="4.969261811023622in"
height="3.557587489063867in"}

**Bước 2: Tạo file Application cho argo-rollouts**

![](./media/image19.png){width="4.741175634295713in"
height="3.3791010498687664in"}

**Bước 3: Push → root tự deploy**

![](./media/image20.png){width="4.807022090988626in"
height="2.4168635170603676in"}

![](./media/image21.png){width="6.5in" height="1.5881944444444445in"}

## Lab 2 --- Viết app Flask có /metrics + build image

**Bước 1: Tạo file app/app.py**

![](./media/image22.png){width="4.784675196850394in"
height="3.09623687664042in"}

**Bước 2: Tạo file app/Dockerfile**

![](./media/image23.png){width="6.5in" height="2.1243055555555554in"}

**Bước 3: Build image + nạp vào minikube**

![](./media/image24.png){width="6.5in" height="1.6444444444444444in"}

## Lab 3 --- Viết manifest Rollout + xem metric trên Prometheus

**Bước 1: Tạo k8s-api/api.yaml (Rollout + Service)**

![](./media/image25.png){width="4.771396544181977in"
height="4.507338145231846in"}

**Bước 2: Tạo k8s-api/servicemonitor.yaml**

![](./media/image26.png){width="5.475036089238845in"
height="2.8170702099737532in"}

**Bước 3: Tạo Application cho api**

![](./media/image27.png){width="5.1972178477690285in"
height="3.5886351706036748in"}

**Bước 4: Ket Qua**

![](./media/image28.png){width="6.5in" height="2.2319444444444443in"}
