# Lab Assignment (Fall 2025)

This lab is about the deployment of a micro-service application in a Kubernetes cluster, the management of this application and of the cluster. It includes a set of mandatory steps as well as additional steps that will allow you to extend the work in different directions.

## Authors

- Laura Keidann Rodrigues Da Silva - laura.keidann@grenoble-inp.org
- Vinícius Bergonzi Lazzari - vinicius.bergonzi-lazzari@grenoble-inp.org

## Base steps [Mandatory]

### GKE configuration

Starting the necessary services.
```
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

Configuring the default compute and zone of the project.
```
gcloud config set compute/zone europe-west6-a
```

Create a new cluster called `microservices-demo`.
```
gcloud container clusters create microservices-demo

    NAME: microservices-demo
    LOCATION: europe-west6-a
    MASTER_VERSION: 1.33.5-gke.1201000
    MASTER_IP: 34.65.63.7
    MACHINE_TYPE: e2-medium
    NODE_VERSION: 1.33.5-gke.1201000
    NUM_NODES: 3
    STATUS: RUNNING
    STACK_TYPE: IPV4
```

### Deploying the original application in GKE

Apply the default Kubernetes configuration to deploy the project.
```
kubectl apply -f ./release/kubernetes-manifests.yaml
```

Checking if all services where successfully deployed.
```
kubectl get pods
    NAME                                     READY   STATUS    RESTARTS   AGE
    adservice-54fdcb4646-jnzv9               0/1     Pending   0          10m
    cartservice-7d76bb9df-bbzp9              1/1     Running   0          10m
    checkoutservice-5d9d84cd44-7twgf         1/1     Running   0          10m
    currencyservice-569f6c566d-sm7zf         1/1     Running   0          10m
    emailservice-7d4b8cd7d6-lpnd9            1/1     Running   0          10m
    frontend-76dbbddfc5-wvpqt                1/1     Running   0          10m
    loadgenerator-56674fd696-kn2c9           0/1     Pending   0          10m
    paymentservice-9ff6ffd6-s8hhn            1/1     Running   0          10m
    productcatalogservice-74c67b9d8b-qq6bf   1/1     Running   0          10m
    recommendationservice-5966b9f59d-4dcng   1/1     Running   0          10m
    redis-cart-c4fc658fb-wnfnj               1/1     Running   0          10m
    shippingservice-5565748dc4-llkbl         1/1     Running   0          10m
```

#### Briefly explain what is this Autopilot mode and why it hides the problem.

Autopilot mode is a mode of operation in GKE where Google will manage all the configurations of the cluster for the user, such as autoscaling, security and nodes. 

It can cause problems because the user doesn't have the control over the cluster anymore, which can lead to many undesired behaviors and a conflict of interests with Google, since the company that is managing the cluster will benefit from a high usage of computer resources for example.