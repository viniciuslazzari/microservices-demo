# Lab Assignment README

- The scripts that reproduce the steps taken during this lab can be found inside the [scripts directory](scripts):
  - `create-and-deploy.sh` to create the cluster and deploy the basic application.
  - `create-monitoring-stack.sh` for the monitoring stack.
  - `canary_test_and_rollback.sh` for the canary releases.
  - `clean-up.sh` to delete the resources.

- The report can be found inside the [report directory](report). It contains additional information about design choices, technical choices, experiments, results, challenges, and conclusions.

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

- The code related to monitoring the application can be found inside the [monitoring directory](monitoring), which contains a `README` with detailed instructions on how to apply and test each part of the monitoring stack. This folder includes both the code for the advanced steps and the bonus steps.
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

**Canary releases - ProductCatalogservice v2**

This section describes how to deploy a canary for `productcatalogservice` (v2) and how to validate traffic splitting.

- **Code change (v2):** `src/productcatalogservice_v2/server.go` was updated to log `service version: v2` and to use profiling version `2.0.0` so the instance can be easily identified in logs.

- **Kubernetes manifests:**
  - Updated `kubernetes-manifests/productcatalogservice.yaml` to add label `version: v1` to the v1 Deployment and pod template.
  - Added `kubernetes-manifests/productcatalogservice-v2.yaml` which creates a Deployment for v2 with labels `app: productcatalogservice` and `version: v2`. The existing Service `productcatalogservice` keeps selecting pods with `app: productcatalogservice`.

- **Istio routing:** Added `istio-manifests/productcatalogservice-canary.yaml` containing:
  - `DestinationRule` with subsets `v1` and `v2` (selecting pods by label `version`).
  - `VirtualService` routing 75% of traffic to subset `v1` and 25% to subset `v2`.

Deployment steps:

Before everything, the user needs to be sure that `istio` is correctly installed in the destination cluster, this can be done using the following commands:

```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.28.1
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
```

After this step, `istio` will create some `pods` and `services` on the cluster, as the `control-plane`, `ingress gateway`, `egress gateway`...
This services are responsible to manipulate the incoming traffic to the cluster and redirect it following the virtual rules defined by the user,
in this case, the rule was to split the traffic to `product-catalog` between to versions, with `25%` and `75%` of the traffic respectfully.


After installing `istio` on the cluster, the user can the add the rule `with-canary` to `kustomize`, in order to create a new `manifest` with the
new version of `product-catalog` and the split rule.

```
kustomize edit add component components/with-canary
kubectl kustomize .
```

Finally, the new configuration can be used to deploy the new pods and rules.

```
kubectl apply -k .
```

Running `kubectl get pods --all-namespaces` now should give the following result.

```
// Both versions of the product-catalog service
default           productcatalogservice-85f8c79c75-hdd28                         2/2     Running   0          35m
default           productcatalogservice-v2-758965c6f8-tg5k9                      2/2     Running   0          35m

// Istio pods and services
istio-system      istio-egressgateway-6f6bb8f7f9-s47cq                           1/1     Running   0          61m
istio-system      istio-ingressgateway-7b787c97fc-6kw8r                          1/1     Running   0          61m
istio-system      istiod-877576bdc-klzfp                                         1/1     Running   0          62m
```

If the traffic split is not working be default, is necessary to allow `istio` to inject
traffic inside the pods, which may be disabled by default, this can be done with the
following commands.

```
# Enable injection
kubectl label namespace default istio-injection=enabled --overwrite

# Restart the deployments and pods
kubectl rollout restart deployment -n default
```

**Validating the traffic split**

To validate the traffic split, we used the `kiali` tool, a visualization tool to observe the deploy and traffic of namespaces inside a cluster.

In order to do this, it was necessary to install two addons to the already existing `istio` installing: `kiali` and `prometheus`. This can be done
using the following commands.

```
kubectl apply -f ./samples/addons/kiali.yaml
kubectl apply -f ./samples/addons/prometheus.yaml
```

After the install, new `pods` should be available at the cluster, confirming that the new plugins are already available.

```
istio-system      kiali-7b58697666-cvwnl                                         1/1     Running   0          47m
istio-system      prometheus-7c48c5c5c7-vfct8                                    2/2     Running   0          6m53s
```

Running the command `istioctl dashboard kiali` start a `localhost` dashboard, that can be used to inspect what is happening on the cluster.

![Kiali traffic dashboard](./images/kiali.png "Kiali traffic dashboard")

Here we can see the full connection tree between the services of the cluster. We can validate that the split is working by looking only to the
`productcatalogservice`. We can see that there are two versions of the service running, as well as the successful requests that reached each one
of the individual services.

![Product catalog traffic split](./images/traffic_split.png "Product catalog traffic split")

If we take a look only at the `productcatalog` service, we can observe that the `inbound` traffic is coming only from the `frontend`, which makes sense,
but the `outbound` traffic is divides between `productcatalogservice` and `productcatalogservice-v2`, where the rate for the first is roughly **0.2rps**
while for the second we have **0.04rps** after some refreshes, so we can validate that the percentages are working as well.

**Completely rolling out the new version**

In order to completely rollout the old version once the new version is validated, we can simply update the parameters of the `productcatalogservice-vs` to
route **100%** of the traffic to the `v2` version and **0%** to `v1`.

```
kubectl patch virtualservice productcatalogservice-vs -n default \
  --type merge -p '{
    "spec": {
      "http": [{
        "route": [
          {"destination":{"host":"productcatalogservice","subset":"v1"},"weight":0},
          {"destination":{"host":"productcatalogservice","subset":"v2"},"weight":100}
        ]
      }]
    }
  }'

virtualservice.networking.istio.io/productcatalogservice-vs patched
```

![Kiali traffic dashboard after rollout](./images/kiali_v2.png "Kiali traffic dashboard after rollout")

We can see that even after many refreshes and incoming traffic, the only version of `productcatalogservice` being used is the `v2` one.

Now we can safelly disable the delete the old replicas of `v1`.

```
kubectl delete deploy productcatalogservice -n default

deployment.apps "productcatalogservice" deleted from default namespace
```

## Bonus steps

**Canary releases [Bonus]**

For this step, it was necessary to implement one service with a defect, in this case an artificial one, then
do a deploy using splitted traffic with `istio` and detect possible problems with the new deployed version, rolling
out the service in case of any problem.

In order to do this, the `productcatalog` service was used, just like in the **Advanced Step of Canary versions**.
A `v3` version was created, in `src/productcatalogservice_v3`. This version is exactly the same as the `v2`, but
with an artificial delay of `3s` on each request.

Then, new manifests and destination rules were created under `kustomize/components/with-canary-rollback`. They
are exatcly the same as the ones used for the **Advanced Step**, but with one difference: this rule has a
exception where every time the **header** `x-canary-test: v3` is found in any request, the `v3` version (defective
one) is always used. This was done to validate the only the new version on the test script.

```
spec:
  hosts:
  - productcatalogservice
  http:
  - match:
    - headers:
        x-canary-test:
          exact: v3
    route:
    - destination:
        host: productcatalogservice
        subset: v3
      weight: 100
  - route:
    - destination:
        host: productcatalogservice
        subset: v1
      weight: 80
    - destination:
        host: productcatalogservice
        subset: v3
      weight: 20
```

By using this rule, we can use the `scripts/canary_test_and_rollback.sh` to do the following:

1. Test the current latency of the `v1` version.
1. Deploy the `v3` version and `istio` rules.
1. Wait for the pods to be running and healthy.
1. Test the latency of the newly deployed version using `x-canary-test: v3`.
1. If the latency is beyond the `threshold` value defined by the user, rollout the `v3` version and `istio` rules.
1. Otherwise, keep the `v3` version and `istio` rules in the cluser.

By doing this we can verify that the newly deployed version of a service is working and immediatly rollback
in case of any problems.

This setup could be improved by using actual `prometheus` metrics of the newly created pod to check for any
problems, since leaving a **header** like this in a production product could bring potential problems if
users or bots could discover it.

**Monitoring the application and the infrastructure [Bonus]**

The code to implement some of the bonus steps can be found in the [monitoring directory](monitoring).


**Review of recent publications [Bonus]**
The review of the Cloudscape article can be found inside the [report](report/README.md).
