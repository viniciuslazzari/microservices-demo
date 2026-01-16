# Lab Assignment README

- The scripts that reproduce the steps taken during this lab can be found inside the [scripts directory](scripts).
- The report can be found inside the [report directory](report).

## Base Steps

The main steps to create the cluster and deploy the application can be found in the `created-and-deploy` script, which can be executed to deploy the application without the load generator.

Below are the steps taken to execute the lab in order, beginning with the configuration and the first attempt at deploying the application.

**GKE configuration**

Starting the necessary services.

```
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

Configuring the default compute and zone of the project.
```
gcloud config set compute/zone europe-west6-a
```

Create a new cluster called `microservices-demo`. Using the default GKE configuration (e2-medium machine type, 3 nodes).

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

**Deploying the original application in GKE**

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

**Reconfiguring the application**

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

**Deploying the load generator on a local machine**

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

**Deploying automatically the load generator in Google Cloud**

- The code for deploying the load generator in Google Cloud can be found inside the [loadgenerator directory](loadgenerator), which contains a ̀`README` with the detailed  instructions on how to deploy the load generator and execute load tests. More information can be found in the Perfomance Evaluation section.

## Advanced Steps

**Monitoring the application and the infrastructure**

- The code related to monitoring the application can be found inside the [monitoring directory](monitoring), which contains a `README` with detailed instructions on how to apply and test each part of the monitoring stack.
- A script to create and deploy the monitoring stack (̀`create-monitoring-stack.sh`) can be found inside the [scripts directory](scripts).

```
# Run the monitoring stack creation script
# which creates the namespace and deploys the monitoring infrastructure

cd scripts
./create-monitoring-stack.sh

# Access the Grafana service with `kubectl port-forward`
kubectl -n monitoring port-forward svc/grafana 3000:3000

# Access the dashboards and view the collected data
http://localhost:3000/

with user/password = admin
```

**Performance Evaluation**

- The code related to Performance Evaluation is also inside the [loadgenerator directory](loadgenerator), which uses `locust` alongside some infrastructure-as-code tools like
`terraform` and `ansible` to deploy a load generator for any specific IP, in this case the `frontend` IP of the cluster.

The `deploy.py` script works as follows:

1. Receives the arguments: `<frontend_ip> <users> <rate> [run_time] [csv_prefix]`.
2. Create a new SSH key on the `keys` folder, if none exists.
3. Deploy a new VM using terraform with the public key that was just created.
4. Get the VM IP and configure `ansible` using it and the private key.
5. `ansible` will configure the machine and install the necessary dependencies.
6. Run `locust` on the new VM using the arguments received in step 1.
7. Collect results from the new VM to local folder `results`.
8. Destroy the VM.

This ensures a smooth flow of testing, where all the infrastructure is created from the ground up and destroyed in the end.

`terraform` will also create the new VM on the cluster region that was used to create the cluster, which ensures that no real network bottleneck will be
observed since both the deploy cluster and the load generator VM will be very close to each other.

**Canary releases**

## Bonus steps

**Monitoring the application and the infrastructure [Bonus]**

**Canary releases [Bonus]**

**Review of recent publications [Bonus]**
The review of the Cloudscape article can be found inside the [report](report/README.md).
