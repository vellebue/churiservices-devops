#DELETE RABBIT MQ
#Delete Rabbit Mq kubernetes operator
helm uninstall --namespace devel rabbit-mq
#DELETE GRAFANA
helm uninstall --namespace devel loki
#DELETE KUBERNETES devel NAMESPACE
kubectl delete namespace devel