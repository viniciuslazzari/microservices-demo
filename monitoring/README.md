# Monitoring

Deploying monitoring stack.

## Option 1: apply everything
```bash
kubectl apply -f monitoring/
```

## Option 2: apply each resource individually

# Namespace

```bash
kubectl apply -f 00-namespace.yaml
```

## RBAC
RBAC permissions to allow Prometheus to discover pods and services inside the cluster.

```bash
kubectl apply -f 01-rbac.yaml
```

## Prometheus

- Scrape configuration
- Deployment
- Service

```bash
kubectl apply -f 02-prometheus.yaml
```

Port-forwarding

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Test:
```http://localhost:9090```

## Node Exporter
- Exposes node-level metrics.
- Deploy as DaemonSet.

```bash
kubectl apply -f 03-node-exporter.yaml
```

Port-forwarding

```bash
kubectl port-forward ds/node-exporter 9100:9100 -n monitoring
```

Test:
```http://localhost:9100/metrics```

## cAdvisor
- Pod-level metrics
- Deploy as DaemonSet

```bash
kubectl apply -f 04-cadvisor.yaml
```

Port-forwarding

```bash
kubectl port-forward ds/cadvisor 8080:8080 -n monitoring
```

Test:
```http://localhost:8080/```



## Grafana

- resource consumption at the level of each node
- resource consumption at the level of each pod

```bash
kubectl apply -f 05-grafana.yaml
```
Access the service

```bash
kubectl -n monitoring port-forward svc/grafana 3000:3000
```

Test:
```http://localhost:3000/```



#  Previous Version with Helm and kube-prometheus-stack

## Prerequisites

### Helm
From https://helm.sh/docs/intro/install/

## Create monitoring namespace

```bash
kubectl create namespace monitoring
```

## Add the Prometheus Community chart repository
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Install Prometheus stack inside namespace
```bash
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
```


### Output

```bash
NAME: monitoring
LAST DEPLOYED: Tue Nov 18 16:37:16 2025
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=monitoring"

Get Grafana 'admin' user password by running:

  kubectl --namespace monitoring get secrets monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Access Grafana local instance:

  export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -oname)
  kubectl --namespace monitoring port-forward $POD_NAME 3000

Get your grafana admin user password by running:

  kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
```

### Confirm


```bash
kubectl get pods -n monitoring
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-monitoring-kube-prometheus-alertmanager-0   2/2     Running   0          2m29s
monitoring-grafana-6dd7c5fffb-5t266                      3/3     Running   0          2m37s
monitoring-kube-prometheus-operator-9888744d8-zw8z6      1/1     Running   0          2m37s
monitoring-kube-state-metrics-689d998768-wpgdd           1/1     Running   0          2m38s
monitoring-prometheus-node-exporter-c6zhk                1/1     Running   0          2m38s
monitoring-prometheus-node-exporter-lfqzv                1/1     Running   0          2m38s
monitoring-prometheus-node-exporter-v642h                1/1     Running   0          2m38s
prometheus-monitoring-kube-prometheus-prometheus-0       2/2     Running   0          2m28s
```

## Access Grafana


```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```




kubectl get services -n monitoring
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                     ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   34m
monitoring-grafana                        ClusterIP   34.118.233.105   <none>        80/TCP                       34m
monitoring-kube-prometheus-alertmanager   ClusterIP   34.118.232.202   <none>        9093/TCP,8080/TCP            34m
monitoring-kube-prometheus-operator       ClusterIP   34.118.228.50    <none>        443/TCP                      34m
monitoring-kube-prometheus-prometheus     ClusterIP   34.118.239.91    <none>        9090/TCP,8080/TCP            34m
monitoring-kube-state-metrics             ClusterIP   34.118.226.52    <none>        8080/TCP                     34m
monitoring-prometheus-node-exporter       ClusterIP   34.118.233.7     <none>        9100/TCP                     34m
prometheus-operated                       ClusterIP   None             <none>        9090/TCP                     34m
