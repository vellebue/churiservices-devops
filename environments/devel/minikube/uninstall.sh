#DELETE RABBIT MQ
kubectl rabbitmq -n devel delete rabbitmq-cluster
#Delete Rabbit Mq kubernetes operator
helm uninstall --namespace devel rabbit-mq
#DELETE GRAFANA
helm uninstall --namespace devel loki
#DELETE KUBERNETES devel NAMESPACE
kubectl delete namespace devel