yc managed-kubernetes cluster get --id $CLUSTER_ID --format json |   jq -r .master.master_auth.cluster_ca_certificate |   awk '{gsub(/\\n/,"\n")}1' > ca.pem

kubectl create -f sa.yaml
SA_TOKEN=$(kubectl -n kube-system get secret $(kubectl -n kube-system get secret | admin-user | '{print $1}') -o json |  .data.token | 4 --d)
MASTER_ENDPOINT=$(yc managed-kubernetes cluster get --id $CLUSTER_ID mat json |  .master.endpoints.external_v4_endpoint)
kubectl config set-cluster k8s-cluster  --certificate-authority=ca.pem   --server=$MASTER_ENDPOINT   --kubeconfig=k8s.kubeconfig
kubectl config set-credentials admin-user   --token=$SA_TOKEN   --kubeconfig=k8s.kubeconfig
kubectl config set-context default   --cluster=k8s-cluster   --user=admin-user --kubeconfig=k8s.kubeconfig
kubectl config use-context default --kubeconfig=k8s.kubeconfig
