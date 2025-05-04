#UPDATE GRAFANA
helm upgrade --namespace devel --values grafana-loki-values.yaml loki grafana/loki-stack
#UPDATE RABBIT MQ
#Update Rabbit Mq kubernetes operator
helm install --namespace devel --values rabbitmq-values.yaml rabbit-mq bitnami/rabbitmq-cluster-operator