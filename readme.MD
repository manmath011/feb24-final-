
step 1:created image of flask based application in which i used following commands

1.source env/bin/activate
2.pip install flask
3.flask run
4.docker build -t manmath-flask .
5.docker run -d -p 4041:3000 manmath-flask

step 2: Push Docker Image to GitHub Container Registry for this commands as follows:

docker login --username manmath011 --password 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 ghcr.io
 1993  docker build -t ghcr.io/manmath011/hello-world-ghcr:latest
 1994  docker build .  -t ghcr.io/manmath011/hello-world-ghcr:latest
 1995  docker push ghcr.io/manmath011/hello-world-ghcr:latest
 1996  docker image ls | grep manmath011
 1997  docker run ghcr.io/manmath011/hello-world-ghcr:latest


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

from kubernetes.client import V1Secret, V1ObjectMeta

secret = V1Secret(
    metadata=V1ObjectMeta(name='ghcr-secret'),
    type='kubernetes.io/dockerconfigjson',
    data={
        '.dockerconfigjson': '<base64-encoded-docker-config>'
    }
)

v1 = client.CoreV1Api()
v1.create_namespaced_secret(namespace='default', body=secret)

from kubernetes.client import V1Deployment, V1DeploymentSpec, V1PodTemplateSpec, V1PodSpec, V1Container, V1ContainerPort, V1Service, V1ServiceSpec, V1ServicePort
from kubernetes.client import V1LabelSelector, V1ObjectMeta

# Define Deployment
deployment = V1Deployment(
    api_version='apps/v1',
    kind='Deployment',
    metadata=V1ObjectMeta(name='web-app-dep-manmath'),
    spec=V1DeploymentSpec(
        replicas=3,
        selector=V1LabelSelector(
            match_labels={'app': 'web-app'}
        ),
        template=V1PodTemplateSpec(
            metadata=V1ObjectMeta(labels={'app': 'web-app'}),
            spec=V1PodSpec(
                containers=[
                    V1Container(
                        name='web-app',
                        image='ghcr.io/manmath011/hello-world-ghcr:latest',
                        ports=[V1ContainerPort(container_port=80)]
                    )
                ],
                image_pull_secrets=[{'name': 'ghcr-secret'}]
            )
        )
    )
)

# Define Service
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

