# Helm chart for momo-store web application

## Usage
set <> as a environment variables
```
helm install --set secrets.dockerConfigJson=<> momo-store ./
```
to check containers installed
```
kubectl get pod
```
