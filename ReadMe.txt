URL : 
https://computingforgeeks.com/how-to-install-ansible-awx-on-centos-7/




How To Install Ansible AWX on CentOS 7 / RHEL 7
ByJosphat Mutai-April 3, 2022203472
Welcome to our guide on how to install Ansible AWX on CentOS 7 / RHEL 7 using Kubernetes k3s distribution. If you have a separate Kubernetes cluster the installation process should just work fine. In this setup we shall use the operator meant to provide a more Kubernetes-native installation method for AWX via an AWX Custom Resource Definition (CRD).

What is AWX?
AWX is the upstream project from which the Red Hat Ansible Tower which provides a web-based user interface, REST API, and task engine built on top of Ansible. It is the upstream project for Tower, a commercial derivative of AWX. This is an open source community project, sponsored by Red Hat, that enables users to better control their Ansible project use in IT environments.  The AWX source code is available under the Apache License 2.0.
We have some setup requirements to run Ansible AWX on CentOS 7 / RHEL 7 Linux system.

Kubernetes Cluster / Docker
CentOS 7 / RHEL 7 server
User with sudo access
Minimum of 8GB of RAM – if you have more memory the better
Minimum of 4vcpus
25GB minimum disk space
1. Disable SELinux and firewalld
Let’s ensure our system is updated.
sudo yum -y update
Once the update is successful perform a system reboot

sudo reboot
Disable SELinux or put it in permissive mode to ensure no issues are experienced during the deployment:
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
cat /etc/selinux/config | grep SELINUX=
Disable Firewalld since it’s a recommendation by K3s.
sudo systemctl disable firewalld --now
2. Install K3s Kubernetes Distribution
All recent releases of AWX can run as a containerized application using Docker images deployed on Kubernetes, OpenShift cluster, or using docker-compose. In this guide we shall focus on the installation of Ansible AWX on CentOS 7 / RHEL 7 using k3s Kubernetes distribution.

But first we need to install k3s. This can be done by running the commands below in your terminal.

curl -sfL https://get.k3s.io | sudo bash -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
After installation check the status of k3s service.

$ systemctl status k3s.service
● k3s.service - Lightweight Kubernetes
   Loaded: loaded (/etc/systemd/system/k3s.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2022-04-03 22:28:01 UTC; 10s ago
     Docs: https://k3s.io
  Process: 6273 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
  Process: 6265 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=0/SUCCESS)
  Process: 6262 ExecStartPre=/bin/sh -xc ! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service (code=exited, status=0/SUCCESS)
 Main PID: 6277 (k3s-server)
    Tasks: 30
   Memory: 668.9M
   CGroup: /system.slice/k3s.service
           ├─6277 /usr/local/bin/k3s server
           └─6299 containerd
....
Switch to root user account and test the installation works.

$ sudo su -
# kubectl get nodes
NAME                  STATUS   ROLES                  AGE   VERSION
centos7.example.com   Ready    control-plane,master   81s   v1.22.7+k3s1
Kubernetes server and client versions can be checked with the commands;

# kubectl version --short
Client Version: v1.22.7+k3s1
Server Version: v1.22.7+k3s1
3. Deploy AWX Operator on k3s Kubernetes
Install git and make tools required in this setup.
sudo yum -y install jq git make
We’ll need to deploy Kubernetes Operator used to manage one or more AWX instances in any namespace. Clone deployment code from Github:

git clone https://github.com/ansible/awx-operator.git
Create namespace called awx where an operator and AWX instance will be deployed.

export NAMESPACE=awx
kubectl create ns ${NAMESPACE}
We can set the current Kubernetes context to created namespace for easy operation.

# kubectl config set-context --current --namespace=$NAMESPACE 
Context "default" modified.
Navigate to the awx-operator directory:

cd awx-operator/
Get the latest version of AWX operator from AWX Operator releases and save as RELEASE_TAG variable.

RELEASE_TAG=`curl -s https://api.github.com/repos/ansible/awx-operator/releases/latest | grep tag_name | cut -d '"' -f 4`
echo $RELEASE_TAG
Checkout to the branch using git command:

git checkout $RELEASE_TAG
Deploy AWX Operator into your cluster with the make deploy commands:

export NAMESPACE=awx
make deploy
Command execution terminal output:

namespace/awx configured
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
serviceaccount/awx-operator-controller-manager created
role.rbac.authorization.k8s.io/awx-operator-awx-manager-role created
role.rbac.authorization.k8s.io/awx-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/awx-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/awx-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/awx-operator-awx-manager-rolebinding created
rolebinding.rbac.authorization.k8s.io/awx-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/awx-operator-proxy-rolebinding created
configmap/awx-operator-awx-manager-config created
service/awx-operator-controller-manager-metrics-service created
deployment.apps/awx-operator-controller-manager created
Wait a few minutes and awx-operator should be running:

# kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-557589c5f4-wm2h5   2/2     Running   0          42s
4. Install AWX on CentOS 7 / RHEL 7 using operator
With the operator running we can proceed to deploy AWX instance in the cluster. But first create a PVC for data persistence in the cluster.

Create a file named public-static-pvc.yaml:

vi public-static-pvc.yaml
Paste and modify the contents below to your liking.

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: public-static-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 8Gi
Apply the settings with kubectl apply commands:

# kubectl apply -f public-static-pvc.yaml -n awx
persistentvolumeclaim/public-static-data-pvc created
Notice that the PVC won’t be bound at this time. A running Pod is needed for binding to be created.

# kubectl get pvc -n awx
NAME                     STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
public-static-data-pvc   Pending                                      local-path     32s
Create AWX instance deployment YAML file contents:

vi awx-instance-deployment.yml
Paste below contents to the file created.

---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  service_type: nodeport
  projects_persistence: true
  projects_storage_access_mode: ReadWriteOnce
  web_extra_volume_mounts: |
    - name: static-data
      mountPath: /var/lib/projects
  extra_volumes: |
    - name: static-data
      persistentVolumeClaim:
        claimName: public-static-data-pvc
Deploy AWX on CentOS 7 / RHEL 7 Linux machine.

# kubectl apply -f awx-instance-deployment.yml -n awx
awx.awx.ansible.com/awx created
Wait for the Pods status to change to running

# watch kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator" -n awx
NAME                   READY   STATUS    RESTARTS   AGE
awx-postgres-0         1/1     Running   0          2m58s
awx-75698588d6-qz2gf   4/4     Running   0          2m42s
Logs of the deployment progress can be checked using commands shared below.

kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager
Extra PVCs are created automatically during AWX deployment.

# kubectl  get pvc
NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
postgres-awx-postgres-0   Bound    pvc-c67f0695-fd13-4ca5-a742-7e85bdcdd05e   8Gi        RWO            local-path     3m42s
awx-projects-claim        Bound    pvc-af9d7b38-a508-46ae-ae22-8a74e612a33d   8Gi        RWO            local-path     2m45s
public-static-data-pvc    Bound    pvc-8162895a-ae35-4d3d-bb37-50edef756fbf   8Gi        RWO            local-path     6m42s
List of Pods created in awx namespace:

# kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-557589c5f4-wm2h5   2/2     Running   0          12m
awx-postgres-0                                     1/1     Running   0          5m2s
awx-5f9c564556-mz6hd                               4/4     Running   0          3m58s
5. How to Check AWX Container’s logs
The awx-xxx-yyy pod will have four containers, namely:

redis
awx-web
awx-task
awx-ee
As can be seen from below command output:

# kubectl get deploy
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
awx-operator-controller-manager   1/1     1            1           9m58s
awx                               1/1     1            1           7m47s

# kubectl -n awx  logs deploy/awx
error: a container name must be specified for pod awx-66596c8fcb-s28tw, choose one of: [redis awx-web awx-task awx-ee] or one of the init containers: [database-check init]
Specify the name of the container for which you need to check its logs.

kubectl -n awx  logs deploy/awx -c awx-task
kubectl -n awx  logs deploy/awx -c redis
kubectl -n awx  logs deploy/awx -c awx-web
kubectl -n awx  logs deploy/awx -c awx-ee
6. Accessing AWX Pod container shell
Commands used to check the logs of each container.

kubectl exec -ti deploy/awx  -c  awx-task -- /bin/bash
kubectl exec -ti deploy/awx  -c  awx-ee -- /bin/bash
kubectl exec -ti deploy/awx  -c  redis -- /bin/bash
kubectl exec -ti deploy/awx  -c  awx-web -- /bin/bash
To get out of the shell, just type exit

bash-5.1$ exit
exit
7. Access AWX Web Interface
Get the AWX Web service port:

# kubectl get service -n awx
NAME                                              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
awx-operator-controller-manager-metrics-service   ClusterIP   10.43.60.112   <none>        8443/TCP       20m
awx-postgres                                      ClusterIP   None           <none>        5432/TCP       13m
awx-service                                       NodePort    10.43.90.239   <none>        80:30080/TCP   12m
From the output we can confirm service node port is 30080. Access AWX web console using your k3s server IP address and service nodeport.

http://k3s-server-ip-address:30080
Welcome to AWX page will be displayed.

install ansible awx ubuntu using operator 01
The login username is admin with the password as output of the following command:

kubectl -n awx get secret awx-admin-password -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
Sample output:

password: ZMXFxKxPpDq10iZDyZNhY2cBLxs32Ohu
Login with the admin username and decoded password from above commands:

install ansible awx ubuntu using operator 02
Once the authentication is successful, you’ll get to AWX administration dashboard.

awx deployed in k3s
Therein, there is a lot of stuff to do. Take your time to explore and refer to official AWX documentation for detailed user guides.

8. How to Upgrade AWX instance on Kubernetes
Follow the guide in the following link to upgrade your AWX operator and instance deployed in a Kubernetes cluster.

Upgrading Ansible AWX running in Kubernetes
9. Uninstalling AWX Operator (Only for reference)
The operator and all associated CRDs can be uninstalled by running the commands below:

# export NAMESPACE=awx
# make undeploy
/root/awx-operator/bin/kustomize build config/default | kubectl delete -f -
namespace "awx" deleted
customresourcedefinition.apiextensions.k8s.io "awxbackups.awx.ansible.com" deleted
customresourcedefinition.apiextensions.k8s.io "awxrestores.awx.ansible.com" deleted
customresourcedefinition.apiextensions.k8s.io "awxs.awx.ansible.com" deleted
serviceaccount "awx-operator-controller-manager" deleted
role.rbac.authorization.k8s.io "awx-operator-leader-election-role" deleted
role.rbac.authorization.k8s.io "awx-operator-manager-role" deleted
clusterrole.rbac.authorization.k8s.io "awx-operator-metrics-reader" deleted
clusterrole.rbac.authorization.k8s.io "awx-operator-proxy-role" deleted
rolebinding.rbac.authorization.k8s.io "awx-operator-leader-election-rolebinding" deleted
rolebinding.rbac.authorization.k8s.io "awx-operator-manager-rolebinding" deleted
clusterrolebinding.rbac.authorization.k8s.io "awx-operator-proxy-rolebinding" deleted
configmap "awx-operator-manager-config" deleted
service "awx-operator-controller-manager-metrics-service" deleted
deployment.apps "awx-operator-controller-manager" deleted
Wrapping Up
To this point we have shown you how to install and use AWX on CentOS 7 / RHEL 7 Linux system. AWX is created to help teams, both small and large in management of complex multi-tier deployments by knowledge, adding control, and delegation to Ansible-powered environments.
