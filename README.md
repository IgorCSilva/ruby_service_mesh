# RubyServiceMesh

A step by stey how to use service mesh with a ruby project.

# Starting project
The initial project has the Dockerfile and docker-compose files to easily start development. You can find a version of this initial project in `starting_project` branch. Get this branch to start this tutorial.

# Tools to install

## Kubernetes - kubectl
You need to have kubernetes installed to proceed. With kubernetes you will use kubectl to manage clusters.

### Install kubectl
Linux:
- `snap install kubectl --classic`
- Check version: `kubectl version --client`

## k3d
We will use Istio to implement service mesh, and a good tool to work with Istio is k3d.

### Install k3d

k3d installation page: https://k3d.io/v5.4.6/#installation

Obs.: For versions of k3d 5.x we need to have docker version 20.10.5. If the Docker version is below this, we must install a version of k3d below 5.x, for example v4.4.8.

- Run the command (accordingly your docker version):
`curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.4.6 bash`

### Create cluster

Run:  
`k3d cluster create -p "8000:30000@loadbalancer" --agents 2`  

With this command we have:

* Redirection of accesses on port 8000 of the machine to port 30000 of the cluster, and port 30000 of the cluster calls the service you want to access.
* The agents command specifies our 2 nodes.
* Kubernetes Control-Plane is created

Change context:
`kubectl config use-context k3d-k3s-default`

List cluster's nodes:
`kubectl get nodes`

* Here we have to see two agents and one contro-plane.
<br>
Nodes:

| NAME | STATUS | ROLES | AGE | VERSION |
| ---- | ------ | ----- | --- | ------- |
| k3d-k3s-default-agent-1 | Ready | \<none> | 10m | v1.24.4+k3s1 |
| k3d-k3s-default-server-0 | Ready | control-plane,master | 10m | v1.24.4+k3s1 |
| k3d-k3s-default-agent-0 | Ready | \<none> | 10m | v1.24.4+k3s1 |
<br>

## Install Istio

Site: [https://istio.io/latest/docs/setup/getting-started/](https://istio.io/latest/docs/setup/getting-started/)

Istio has a CLI called *istioctl*.

Linux:
- Download Istio:
`curl -L `[`https://istio.io/downloadIstio`](https://istio.io/downloadIstio)` | sh -`

- Environment variable configuration:
`sudo nano ~/.bashrc`

* Add at end of file (remenber to put you istio folder path).

`export ISTIO_HOME=~/istio-1.15.0`
    `export PATH=$PATH:$ISTIO_HOME/bin`

This way we now have access to the `istioctl` command from any part of the computer.

During installation, we can choose which types of configuration we want Istio to have through the profile parameter. Here we will install with the default configuration.

`istioctl install`
<br>
* Local installation is quick but may take a while when in production.

### Sidecar proxy injection

Create the file manifests/deployment.yaml.

``` yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
```
<br>
Apply it:
`kubectl apply -f deployment.yaml`

List the pods:
`kubectl get po`

* here we have only one nginx container running

Let's create a label for the default namespace so Istio knows when to inject the sidecar-proxy:
`kubectl label namespace default istio-injection=enabled`

Delete the deploy and create again::  
`kubectl delete deploy nginx`  
`kubectl apply -f deployment.yaml`

Listing the pods (`kubectl get po`) we see two containers.
Running the kubernetes describe command (`kubectl describe pod {pod-name}`) we see the istio-proxy creation.
<br>
### addons configuration

Github with default addons: [https://github.com/istio/istio/tree/master/samples/addons](https://github.com/istio/istio/tree/master/samples/addons)

Apply Prometheus addon:
`kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml`

Apply kiali addon:
`kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml`

Apply jaeger addon:
`kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/jaeger.yaml`

Apply grafana addon:
`kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml`

Again, list pods to see what was installed:
`kubectl get po -n istio-system`

Show kiali dashboard:
`istioctl dashboard kiali`

* a web page will open.


**Overview tab**  

![image](https://raw.githubusercontent.com/IgorCSilva/ruby_service_mesh/nginx_deployment/images/00_istion_home.png)

**Traffic Graph tab**

![image](https://raw.githubusercontent.com/IgorCSilva/ruby_service_mesh/nginx_deployment/images/01_traffic_graph.png)

**Mesh tab**

![image](https://raw.githubusercontent.com/IgorCSilva/ruby_service_mesh/nginx_deployment/images/02_mesh.png)


# Create a simple ruby server

First, run the application:  
`docker-compose up --build`

Get inside the container:  
`docker exec -it ruby_service_mesh bash`


Add `sinatra` and `rackup` in Gemfile.

```ruby
gem "sinatra", "~> 4.0.0"

gem "rackup", "~> 2.1.0"
```

Inside the container run the `bundle install`.

Create the routes in app/main.rb:

```ruby
require "sinatra"

set :bind, "0.0.0.0"

get "/" do
  "Hello, world! V1"
end

```

Update the Dockerfile CMD command to start server.
```dockerfile
...

CMD ["ruby", "app/main.rb"]
```

Update docker-compose.yml file to add ports mapping:
```yaml
version: '3'

services:
  ruby_service_mesh:
    build: .
    container_name: ruby_service_mesh
    volumes:
      - .:/app
    ports:
      - 8080:4567
```

Stop application with Ctrl+C.

Run the application again:  
`docker-compose up --build`


Access `localhost:8080` and you will see a Hello, world! V1 message.


## Dockerhub
Create the first version app image:  
`docker build -t igoru23/ruby_sinatra:v1 .`

Check if the image is working running the command below an accessing the `localhost:8080` url:  
`docker run --rm -p 8080:4567 igoru23/ruby_sinatra:v1`

Push image to dockerhub:  
`docker push igoru23/ruby_sinatra:v1`

Now, you can see the app image in dockerhub.

![dockerhub app version 1](https://raw.githubusercontent.com/IgorCSilva/ruby_service_mesh/nginx_deployment/images/03_dockerhub_v1.png)

### Version 2
Update the server code to use the version 2.

In app/main.rb:

```ruby
require "sinatra"

set :bind, "0.0.0.0"

get "/" do
  "Hello, world! V2"
end

```

Then, follow the same steps before until publish image in dockerhub.

Create the second version app image:  
`docker build -t igoru23/ruby_sinatra:v2 .`

Check if image is ok:  
`docker run --rm -p 8080:4567 igoru23/ruby_sinatra:v2`

Push image to dockerhub:  
`docker push igoru23/ruby_sinatra:v2`

The second image now is in dockerhub.


![dockerhub app version 1](https://raw.githubusercontent.com/IgorCSilva/ruby_service_mesh/nginx_deployment/images/04_dockerhub_v2.png)

## Update deployment
Update deployment to include a service and use the app versions created.

``` yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: V1
    spec:
      containers:
      - name: nginx
        image: igoru23/ruby_sinatra:v1
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 4567

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-b
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        version: V2
    spec:
      containers:
      - name: nginx
        image: igoru23/ruby_sinatra:v2
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 4567

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 8000
    targetPort: 4567
    nodePort: 30000
```
<br>

Apply the updated deployment:  
`kubectl apply -f deployment.yaml`  

Accessing `localhots:8000` the text Hello, world! V2 is showed.