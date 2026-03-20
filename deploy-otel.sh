#!/bin/bash

# https://docs.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad

# Set the `errexit` option to make sure that
# if one command fails, all the script execution
# will also fail (see `man bash` for more 
# information on the options that you can set).
set -o errexit

main () {
    myNamespace=opensearch
    NS=$(sudo kubectl get namespace $myNamespace --ignore-not-found);
    if [[ "$NS" ]]; then
        echo "Skipping creation of namespace $myNamespace - already exists";
    else
        echo "Creating namespace $myNamespace";
        sudo kubectl create namespace $myNamespace;
    fi;
    # deploy otel with argocd
    sudo kubectl apply -n argocd -f otel.yaml
    # login to argocd
    argocd login kube.local:443 --grpc-web-root-path /argocd-server --insecure  --username admin --password $(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    # inject the OpenSearch password as a Helm parameter override (not stored in git)
    OS_PWD=$(sudo kubectl get secret opensearch-admin-password -n "$myNamespace" -o jsonpath='{.data.password}' | base64 -d)
    argocd app set otel --helm-set-string dataPrepperPassword="$OS_PWD"
    argocd app sync otel

}
main "$@"
