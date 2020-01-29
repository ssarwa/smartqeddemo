# create Azure Container Registry

RESOURCE_GROUP=SmartQED-RG
#az group create --name=$RESOURCE_GROUP --location=westus
az acr create --resource-group $RESOURCE_GROUP --location westus --name smartqeddemoregistry --sku Basic --admin-enabled
# set the default name for Azure Container Registry, otherwise you will need to specify the name in "az acr login"
az configure --defaults acr=smartqeddemoregistry
az acr login

# build image
docker build -t smartqeddemoregistry.azurecr.io/smartqeddemo-acr .
# verify locally
docker run -d -p 8080:8080 smartqeddemoregistry.azurecr.io/smartqeddemo-acr
# push it to Azure Container registry
docker push smartqeddemoregistry.azurecr.io/smartqeddemo-acr

# create AKS Cluster
az aks create --resource-group=$RESOURCE_GROUP --name=smartqeddemo-akscluster --dns-name-prefix=$RESOURCE_GROUP --generate-ssh-keys
# Get the id of the service principal configured for AKS
CLIENT_ID=$(az aks show -g $RESOURCE_GROUP -n smartqeddemo-akscluster --query "servicePrincipalProfile.clientId" --output tsv)

# Get the ACR registry resource id
ACR_ID=$(az acr show -g $RESOURCE_GROUP -n smartqeddemoregistry --query "id" --output tsv)

# Create role assignment
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID

az aks install-cli

az aks get-credentials --resource-group=$RESOURCE_GROUP --name=smartqeddemo-akscluster

kubectl run smartqeddemo-acr --image=smartqeddemoregistry.azurecr.io/smartqeddemo-acr:latest

# expose deploym,ent
kubectl expose deployment smartqeddemo-acr --type=LoadBalancer --port=80 --target-port=8080

# get service ip
kubectl get services -o jsonpath="{.items[*].status.loadBalancer.ingress[0].ip}" --namespace=default