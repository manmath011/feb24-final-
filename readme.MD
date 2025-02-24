
step 1:created image of flask based application in which i used following commands



1.source env/bin/activate

2.pip install flask

3.flask run

4.docker build -t manmath-flask .

5.docker run -d -p 4041:3000 manmath-flask



step 2: Push Docker Image to GitHub Container Registry for this commands as follows:

docker login --username <your-github-username>

docker build -t ghcr.io/<your-github-username>/hello-world-ghcr:latest .

docker push ghcr.io/<your-github-username>/hello-world-ghcr:latest

docker image ls | grep <your-github-username>

docker run ghcr.io/<your-github-username>/hello-world-ghcr:latest



step 3: Set up a Kubernetes cluster using Minikube locally


 kubectl apply -f deployment.yml

 2042  kubectl get pods

 2043  kubectl apply -f service.yml

 2044  minikube service my-service-flask

 2045  kubectl get pods


 step 4: if i used AKS without using minikube then steps as follows:


az aks create --resource-group <resource-group-name> --name <aks-cluster-name> --node-count 1 --enable-addons monitoring –generate-ssh-keys


pip install azure-mgmt-resource azure-mgmt-containerservice azure-identity kubernetes

from azure.identity import DefaultAzureCredential

from azure.mgmt.resource import ResourceManagementClient

from azure.mgmt.containerservice import ContainerServiceClient

from kubernetes import client, config

 
subscription_id = '<your-subscription-id>'

resource_group_name = '<resource-group-name>'


aks_cluster_name = '<aks-cluster-name>'
 
credential = DefaultAzureCredential()

resource_client = ResourceManagementClient(credential, subscription_id)

aks_client = ContainerServiceClient(credential, subscription_id)

aks_credentials = aks_client.managed_clusters.list_cluster_user_credentials(resource_group_name, aks_cluster_name)



kubeconfig = aks_credentials.kubeconfigs[0].value.decode()

with open('kubeconfig', 'w') as f:
    f.write(kubeconfig)
 
config.load_kube_config('kubeconfig')
 
# Create Image Pull Secret

from kubernetes.client import V1Secret, V1ObjectMeta
 
secret = V1Secret(
    metadata=V1ObjectMeta(name='ghcr-secret'),
    type='kubernetes.io/dockerconfigjson',
    data={
        '.dockerconfigjson': '<base64-encoded-docker-config>'  # Replace with your base64-encoded secret
    }
)
 
v1 = client.CoreV1Api()
v1.create_namespaced_secret(namespace='default', body=secret)
 
# Deploy Application
from kubernetes.client import (
    V1Deployment, V1DeploymentSpec, V1PodTemplateSpec, V1PodSpec,
    V1Container, V1ContainerPort, V1Service, V1ServiceSpec, V1ServicePort,
    V1LabelSelector, V1ObjectMeta
)
 
deployment = V1Deployment(
    api_version='apps/v1',
    kind='Deployment',
    metadata=V1ObjectMeta(name='web-app-dep-manmath'),
    spec=V1DeploymentSpec(
        replicas=3,
        selector=V1LabelSelector(match_labels={'app': 'web-app'}),
        template=V1PodTemplateSpec(
            metadata=V1ObjectMeta(labels={'app': 'web-app'}),
            spec=V1PodSpec(
                containers=[
                    V1Container(
                        name='web-app',
                        image='ghcr.io/<your-github-username>/hello-world-ghcr:latest',
                        ports=[V1ContainerPort(container_port=80)]
                    )
                ],
                image_pull_secrets=[{'name': 'ghcr-secret'}]
            )
        )
    )
)
 
# Create Kubernetes Service
service = V1Service(
    api_version='v1',
    kind='Service',
    metadata=V1ObjectMeta(name='my-service-flask'),
    spec=V1ServiceSpec(
        selector={'app': 'web-app'},
        ports=[V1ServicePort(protocol='TCP', port=80, target_port=9376)]
    )
)
 
apps_v1 = client.AppsV1Api()
core_v1 = client.CoreV1Api()
apps_v1.create_namespaced_deployment(namespace='default', body=deployment)
core_v1.create_namespaced_service(namespace='default', body=service)
 
