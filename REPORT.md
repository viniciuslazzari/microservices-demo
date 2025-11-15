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

### Reconfiguring the application

Delete all running services.

```
kubectl delete -f ./release/kubernetes-manifests.yaml
```

Create new Kubernetes config using Kustomize.

```
cd kustomize
kustomize edit add component components/without-loadgenerator
kubectl kustomize .
```

Re-create services.

```
kubectl apply -k .
```

Now we can see that the load-generator service is not deployed anymore with the current Kubernetes manifest.
```
kubectl get pods
    NAME                                     READY   STATUS    RESTARTS   AGE
    adservice-54fdcb4646-xm26z               1/1     Running   0          18m
    cartservice-7d76bb9df-rk9vb              1/1     Running   0          18m
    checkoutservice-5d9d84cd44-x7wbd         1/1     Running   0          18m
    currencyservice-569f6c566d-cbp6s         1/1     Running   0          18m
    emailservice-7d4b8cd7d6-b5xcx            1/1     Running   0          18m
    frontend-76dbbddfc5-pk8q9                1/1     Running   0          18m
    paymentservice-9ff6ffd6-8jt22            1/1     Running   0          18m
    productcatalogservice-74c67b9d8b-w6k7k   1/1     Running   0          18m
    recommendationservice-5966b9f59d-zdtjs   1/1     Running   0          18m
    redis-cart-c4fc658fb-vpmlr               1/1     Running   0          18m
    shippingservice-5565748dc4-9b2js         1/1     Running   0          18m
```

#### Which of the two parameters (`requests` and `limits`) actually matters when Kubernetes decides that it can deploy a service on a worker node?

During deploy phase, the `requests` parameter is the one observed, where a service is not deployed if it's node cannot handle the desired `request` of the service. The limit is a parameter to be observed during runtime, where a service is forbidden to use more computing and memory than it's `limits` parameter allows it.

#### Select 2 services among those that seem less critical in the application to reduce their resource requirement and justify your choices in the report

##### AdService

Since it's not part of the core infrastructure of the system and it's not part of the buying workflow, this service can have it's computing power decreased, in order to keep the total computing power inside the desired constraints.

In our system, we set the `request` parameter to 100m (from 200m) and the `limits` parameter to 150m (from 300m).

##### EmailService

We think that this service is not critical and does not resource heavy since it consists of only sending emails and it's done after the buying pipeline, which should compromise to much the user experience on a real system.

In our system, we set the `request` parameter to 50m (from 100m) and the `limits` parameter to 100m (from 200m).

### Analyzing the provided configuration

### Deploying the load generator on a local machine

This load generator was deployed using the Google Shell in order to avoid conflicts between different instruction set architectures.

We first need to build the image of the load generator.

```
cd src/loadgenerator
docker build -t loadgenerator .
```

Then we can obtain the frontend service `EXTERNAL-IP`, which is going to be used as our entry point in order to generate load into the system.

```
kubectl get service frontend-external | awk '{print $4}'
    EXTERNAL-IP
    34.65.30.228
```

Finally, we can run the previously compiled image with this IP as the target, with optional parameters as the number of users and pooling rate.

```
docker run --rm -p 8089:8089 -e FRONTEND_ADDR=34.65.30.228 -e USERS=10 -e RATE=10 loadbalancer
    Response time percentiles (approximated)
    Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
    --------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
    GET      /                                                                                     900    960   1100   1100   1100   1100   1100   1100   1100   1100   1100     14
    GET      /cart                                                                                  36     44     54     55    110    120    120    120    120    120    120     20
    POST     /cart                                                                                  63     66     67     67    220    300    300    300    300    300    300     20
    POST     /cart/checkout                                                                         61     61     67    180    260    260    260    260    260    260    260      9
    GET      /product/0PUK6V6EV0                                                                    38     39     40     40     41    200    200    200    200    200    200     11
    GET      /product/1YMWWN1N4O                                                                    36     37     38     38     38     41     41     41     41     41     41     11
    GET      /product/2ZYFJ3GM2N                                                                    36     41     44     44    310    310    310    310    310    310    310      8
    GET      /product/66VCHSJNUP                                                                    37     38     39     39     41     42     42     42     42     42     42     11
    GET      /product/6E92ZMYYFZ                                                                    36     37     38     41     53     53     53     53     53     53     53     10
    GET      /product/9SIQT8TOJO                                                                    40     43     46     46     49    200    200    200    200    200    200     13
    GET      /product/L9ECAV7KIM                                                                    38     38     38     38     40     40     40     40     40     40     40      7
    GET      /product/LS4PSXUNUM                                                                    40     40     41    190    310    310    310    310    310    310    310     10
    GET      /product/OLJCESPC7Z                                                                    38     38     41     42     43    220    220    220    220    220    220     18
    POST     /setCurrency                                                                           67     68     72     84    140    140    160    160    160    160    160     25
    --------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
            Aggregated                                                                             41     58     64     67    200    700   1100   1100   1100   1100   1100    187
```