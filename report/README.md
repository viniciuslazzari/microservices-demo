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
#### PaymentService

We have chosen to analyze the configuration file of the PaymentService. The file contains the definition for three Kubernetes objects: Deployment, Service, and ServiceAccount. Some parameters define names and labels used to identify the objects, as well as environment variables. Below we describe the most significant parameters.

The first section contains the parameters related to Deployment, with the information on how to run the application:
- `terminationGracePeriodSeconds: 5` defines that Kubernetes should wait for 5 seconds for a Pod that has been deleted to shut down before forcefully killing it. Kubernetes sends SIGTERM to the containers, waits for 5 seconds, then sends SIGKILL if they are still running.
- Pod-level `securityContext`:
  - `fsGroup: 1000`: Files created in mounted volumes belong to group 1000.
  - `runAsGroup: 1000`: Processes will run with the group ID 1000.
  - `runAsNonRoot: true`: The pod cannot run as the root user.
  - `runAsUser: 1000`: Processes will run with the user ID 1000.
- Container definition inside `containers`: this deployment only has a single container.
  - Container-level `securityContext`:
    - `allowPrivilegeEscalation: false` prevents the container's process from gaining more privileges than it started with.
    - `capabilities: drop: - ALL` drops all special "Linux capabilities", restricting what the container can do.
    - `privileged: false` ensures that the container does not run in "privileged" mode.
    - `readOnlyRootFilesystem: true` ensures that the container's files cannot be modified.
  - `image: us-central1-docker.pkg.dev/google-samples/microservices-demo/paymentservice:v0.10.3` defines the specific Docker image that has to be pulled and run.
  - `ports: containerPort: 50051` tells Kubernetes that the application inside the container is listening on port 50051.
  - `readinessProbe: grpc: port: 50051` defines how Kubernetes checks if the container is ready to receive traffic. In this case it performs a gRPC health check on port 50051.
  - `livenessProbe: grpc: port: 50051`: defines how Kubernetes checks if the container is alive and healthy. If it fails, Kubernetes assumes the container is broken and restarts it.
  - `resources` defines the CPU and memory resources for the container.
    - `requests`: The guaranteed minimum.
      - `cpu: 100m`: 100 millicpu (0.1 CPU).
      - `memory: 64Mi`: 64 mebibytes of RAM.
    - `limits`: The maximum amount of resources the container is allowed to use.
      - `cpu: 200m`: 200 millicpu (0.2 CPU).
      - `memory: 128Mi`: 128 mebibytes of RAM.

The Service definition describes how the service is exposed. In the specification (`spec`) section, we find the following parameters:
- `type: ClusterIP`: Default type. Exposes the Service only on an internal IP address within the cluster. It's not reachable from outside the cluster.
- `selector: app: paymentservice:` Selects the Pods with this label (link to the Deployment Pods).
- `ports` defines the port mapping:
  - `port: 50051`: the port  exposed by the Service.
  - `targetPort: 50051`: the container port number inside the Pod.

Finally, the third section corresponds to the ServiceAccount, which creates a cluster-level identity for the application with the name `paymentservice`, referenced by the Deployment's `serviceAccountName: paymentservice`.

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

### Deploying automatically the load generator in Google Cloud

This task was completed using the scripts inside the `loadgenerator` folder. The idea is to create a virtual machine in GKE using Terraform and capture it's IP address. Later, this address is used by Ansible to stablish a SSH connection with the machine, clone the `locust` test script and execute it. All this process is managed by a python script `deploy.py`, receiving the IP address of the frontend, the number of desired users and pooling rate for testing.

If everything works well, a virtual machine should be deployed inside GKE, executing the `locust` test script with the desired parameters. The script `destroy.py` can be used to destroy the current virtual machine.

## Canary releases — ProductCatalogservice v2

This section describes how to deploy a canary for `productcatalogservice` (v2) and how to validate traffic splitting.

- **Code change (v2):** `src/productcatalogservice_v2/server.go` was updated to log `service version: v2` and to use profiling version `2.0.0` so the instance can be easily identified in logs/telemetry.

- **Kubernetes manifests:**
  - Updated `kubernetes-manifests/productcatalogservice.yaml` to add label `version: v1` to the v1 Deployment and pod template.
  - Added `kubernetes-manifests/productcatalogservice-v2.yaml` which creates a Deployment for v2 with labels `app: productcatalogservice` and `version: v2`. The existing Service `productcatalogservice` keeps selecting pods with `app: productcatalogservice`.

- **Istio routing:** Added `istio-manifests/productcatalogservice-canary.yaml` containing:
  - `DestinationRule` with subsets `v1` and `v2` (selecting pods by label `version`).
  - `VirtualService` routing 75% of traffic to subset `v1` and 25% to subset `v2`.

Deployment steps (example):
```
# Build/push v2 image (tag as productcatalogservice:v2)
docker build -t productcatalogservice:v2 ./src/productcatalogservice_v2
# push to registry if using remote cluster

# Apply v1 (if not already present)
kubectl apply -f kubernetes-manifests/productcatalogservice.yaml

# Deploy v2
kubectl apply -f kubernetes-manifests/productcatalogservice-v2.yaml

# Apply Istio canary routing
kubectl apply -f istio-manifests/productcatalogservice-canary.yaml
```

Methodology to validate traffic split:
- Use `kubectl get pods -l app=productcatalogservice -o wide` to see pods and their versions via label `version`.
- Check logs on pods: pods with v2 will include the startup log `service version: v2`.
- Generate traffic (e.g., with the existing load generator or `curl`/`grpcurl`) to the frontend or directly to the service entrypoint and observe distribution.
- Use Istio / Kiali: Kiali shows traffic distribution between service versions visually. Confirm approximately 25% of requests go to pods labeled `version=v2`.
- Alternative quick check: stream logs from all pods and count requests hitting v2 vs v1 during a test run.

Switching to v2 (full promotion):
- Once validated, update the `VirtualService` weights to 100% for subset `v2` and 0% for `v1`, or update Deployment labels and/or scale down the v1 Deployment:
```
kubectl patch virtualservice productcatalogservice-vs -n default --type='json' -p='[{"op":"replace","path":"/spec/http/0/route/0/weight","value":0},{"op":"replace","path":"/spec/http/0/route/1/weight","value":100}]'

# then scale down v1
kubectl scale deployment productcatalogservice --replicas=0
```

Notes:
- Ensure Istio is installed in the cluster and sidecar injection is enabled to use subset routing.
- The image name `productcatalogservice:v2` is an example; adapt to your registry naming and push process.