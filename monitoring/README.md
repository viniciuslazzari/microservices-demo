# Monitoring

## TODO:
Create our own monitoring stack

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



