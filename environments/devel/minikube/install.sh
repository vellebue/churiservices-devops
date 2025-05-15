#CREATE DEVEL NAMESPACE
kubectl create namespace devel
#INSTALL GRAFANA
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install --namespace devel --values grafana-loki-values.yaml loki grafana/loki-stack
#INSTALL RABBITMQ
#Install Rabbit Mq kubernetes operator
ytt -f rabbitmq-values-original.yaml -f rabbitmq-values-patch.yaml > rabbitmq-values.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --namespace devel --values rabbitmq-values.yaml rabbit-mq bitnami/rabbitmq-cluster-operator
#Install Rabbit Mq kubernetes cluster
kubectl rabbitmq -n devel create rabbitmq-cluster