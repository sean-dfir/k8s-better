# k8s-better
k8s-better is a quickly deployable Kubernetes cluster with preinstalled security tooling using Vagrant to support alerting and detection research.

Installed Security Tooling:
* [Cilium](https://github.com/cilium/cilium) - eBPF-based CNI that provides networking, observability, and L3/L7 security controls. 
* [Tetragon](https://github.com/cilium/tetragon) - an add-on component to Cilium that provides process and syscall visibility with Kubernetes context that supports container-level visibility and attribution.

Tetragon supports [Tracing Policies](https://tetragon.io/docs/concepts/tracing-policy/), which are user-configurable Kubernetes custome resources that can trace arbitrary events in the kernel and optionally define actions on a match. The Tetragon repo has examples of [TracingPolicies](https://github.com/cilium/tetragon/tree/main/examples/tracingpolicy). 

This is a fork of [vagrant-kubeadm-kubernetes](https://github.com/techiescamp/vagrant-kubeadm-kubernetes), a TechiesCamp repo that provides a Vagrant file and associated scripts/configs to automate creating a practice environment k8s cluster using Kubeadm for some certifications. 


## Prerequisites

1. Working Vagrant setup
2. 8 Gig + RAM workstation as the Vms use 3 vCPUS and 4+ GB RAM

## For MAC/Linux Users

The latest version of Virtualbox for Mac/Linux can cause issues.

Create/edit the /etc/vbox/networks.conf file and add the following to avoid any network related issues.
<pre>* 0.0.0.0/0 ::/0</pre>

or run below commands

```shell
sudo mkdir -p /etc/vbox/
echo "* 0.0.0.0/0 ::/0" | sudo tee -a /etc/vbox/networks.conf
```

So that the host only networks can be in any range, not just 192.168.56.0/21 as described here:
https://discuss.hashicorp.com/t/vagrant-2-2-18-osx-11-6-cannot-create-private-network/30984/23

## Bring Up the Cluster

To provision the cluster, execute the following commands.

```shell
git clone https://github.com/sean-dfir/k8s-better.git
cd k8s-better
vagrant up
```
## Set Kubeconfig file variable

```shell
cd vagrant-kubeadm-kubernetes
cd configs
export KUBECONFIG=$(pwd)/config
```

or you can copy the config file to .kube directory.

```shell
cp config ~/.kube/
```

## Install Kubernetes Dashboard

The dashboard is automatically installed by default, but it can be skipped by commenting out the dashboard version in _settings.yaml_ before running `vagrant up`.

If you skip the dashboard installation, you can deploy it later by enabling it in _settings.yaml_ and running the following:
```shell
vagrant ssh -c "/vagrant/scripts/dashboard.sh" master
```

## Kubernetes Dashboard Access

To get the login token, copy it from _config/token_ or run the following command:
```shell
kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}"
```

Proxy the dashboard:
```shell
kubectl proxy
```

Open the site in your browser:
```shell
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard
```

## To shutdown the cluster,

```shell
vagrant halt
```

## To restart the cluster,

```shell
vagrant up
```

## To destroy the cluster,

```shell
vagrant destroy -f
```

