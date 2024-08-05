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

