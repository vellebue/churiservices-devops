# Tutorial to install churiservices base on minikube

In this document it is described how to install base components to run churiservices on a minikube installation. Provided that this is a devel environment this install will be made under a namespace called "devel". It is supposed that minikube is running and kubectl points to this minikube installation.

## Prerrequisites

To install churiservices on minikube you must fullfill these prerrequisites (for a linux environment):

- You should install minikube, see Minikube web site at https://minikube.sigs.k8s.io/docs/ see your working version typing:

```
minikube version
```

- You should have installed kubernetes **kubectl** command line tool. Your favorite linux distribution may have a package to install kubectl. To see your working version for kubectl type:

```
kubectl version
```

- You should install krew extension (kubectl plugin manager) for kubectl. This is required for RabbitMq to manage RabbitMq clusters. See instructions on https://krew.sigs.k8s.io/docs/user-guide/setup/install/ Once installed you can verify krew installation by typing:

```
kubectl krew
```

- To install Rabbit Mq operator it is required to patch yaml default configuration for kubernetes operator. This is shown later in Rabbit Mq section, but you must install a yaml patch tool like Carvel ytt. Instructions to install **ytt** are described here https://carvel.dev/ytt/docs/v0.51.0/install/

## Files in this folder

The main files in this folder are:

1. This **README.sh**

1. **install.sh**: Main script to install project base systems from the scratch.

1. **update.sh**: Main script to perform an update operation once an aux. file has been changed and you need to update any of the helm charts.

2. **uninstall.sh**: This performs uninstall process, deletes all installed helm charts and deletes devel namespace.

Any other files are considered aux files and they are referenced from install and update files. Further explanation is given aftewards.

## Steps to perform installation

In this section it is described the steps and base systems to be installed.


### Create namespace devel

To create namespace devel this command is used.

    kubectl create namespace devel



### Install grafana loki

Grafana loki is installed through a helm chart.To perform a minimun installation of grafana loki first enable access to grafana helm repo this way. First add grafana repo, then update helm repos.

    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

There are many helm "flavours" to install grafana loki. In this case it has been choosen to install "loki-stack" due that it is a simple loki server with full persistence and a grafana web server preconfigured to access loki server. Configuration for this grafana loki installation is defined in file **grafana-loki-values.yaml**. Notice that there are two many differences with default loki-stack configuration:

1. Promtail is disabled. In this project logs are given directly through java slf4j configuration, so promptail is not required. See that propmtail section is disabled.

1. Grafana is enabled to ensure you can query logs through Grafana console.

So this is the command to install loki-stack with its helm chart

    helm install --namespace devel --values grafana-loki-values.yaml loki grafana/loki-stack

1. The namespace for this installation is **devel**.

1. Values reference config file is **grafana-loki-values.yaml**.

1. The name of the chart installation is **loki**. It is useful if you need to uninstall.

1. The name of the installed chart is **grafana/loki-stack**.

To test access to grafana web console, until there is a working Ingress, you should perform a port foward like this. There is a Kubernetes service named loki-grafana listening on port 80 deployed. It is mapped locally on port 3000.

    kubectl port-forward service/loki-grafana -n devel 3000:80

Notice you can now see grafana console performing in your favorite web browser:

    http://localhost:3000

Now it is time to figure out the username and password to access to this grafana console. Notice that there is a secret registered to store username and password for grafana whose name is loki-grafana. You can describe it using:

    kubectl describe secret/loki-grafana -n devel

So you can see that the name of the user is stored on **admin-user** property and the password is stored on property **admin-password**. To extract both of then you can perform:

    kubectl get secret/loki-grafana -n devel -o jsonpath='{.data.admin-user}' | base64 -d
    kubectl get secret/loki-grafana -n devel -o jsonpath='{.data.admin-password}' | base64 -d

## Install RabbitMQ Infrastructure

To install a fully functional RabbitMQ queue server on kubernetes you must install RabbitMQ kubernetes operator. Then you must require the operator to install a RabbitMQ clustered server under certain persistence configuration. You can see more details at https://www.rabbitmq.com/kubernetes/operator/install-operator

### Installing RabbitMQ kubernetes operator

Notice that RabbitMQ kubernetes operator requires some specific configuration for this environment, specifically you need to point the target namespace for RabbitMQ operator to work (devel namespace). You must take the default values.yaml file for RabbitMQ and it must be patched with the content shown below in file **rabbitmq-values-patch.yaml**

```yaml
#@ load("@ytt:overlay", "overlay")
#@ deployment = overlay.subset({"kind": "Deployment"})
#@ cluster_operator = overlay.subset({"metadata": {"name": "rabbitmq-cluster-operator"}})
#@overlay/match by=overlay.and_op(deployment, cluster_operator),expects="1+"
---
spec:
  template:
    spec:
      containers:
      #@overlay/match by=overlay.subset({"name": "operator"}),expects="1+"
      -
        #@overlay/match missing_ok=True
        env:
        - name: OPERATOR_SCOPE_NAMESPACE
          value: devel
```
Given that **rabbitmq-values-original.yaml** represents default configuration for RabbitMQ cluster (you can download it from https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml) and rabbitmq-values-patch.yaml represents the patch file you can perform patch operation as shown below:

    ytt -f rabbitmq-values-original.yaml -f rabbitmq-values-patch.yaml > rabbitmq-values.yaml



To install RabbitMQ operator it is required to add bitnami report reference. Then you must install kubernetes operator, in this case under kubernetes devel namespace.

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install --namespace devel --values rabbitmq-values.yaml rabbit-mq bitnami/rabbitmq-cluster-operator





### Installing Rabbit Mq cluster

Notice that you need to have installed krew kubectl extension (see Prerrequisites section on top on this document). First of all you need to install rabbitmq extension to manage RabbitMq clusters by typing:

    kubectl krew install rabbitmq

Once RabbitMq kubernetes operator is installed you can install a RabbitMq cluster by typing:

    kubectl rabbitmq -n devel create rabbitmq-cluster

where **rabbitmq-cluster** is the name of the Rabbit Mq cluster that has been installed. Be sure that the cluster is created under namespace devel by specifying -n devel flag.