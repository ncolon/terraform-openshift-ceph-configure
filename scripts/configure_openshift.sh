#!/bin/bash
set -x

MONITORS="$1"
ADMIN_SECRET=$(cat /tmp/client.admin.secret.txt)
POOL_SECRET=$(cat /tmp/client.kube.secret.txt)


mkdir ~/ceph
cat <<EOF | tee ~/ceph/ceph-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
  namespace: kube-system
data:
  key: ${ADMIN_SECRET}
type: kubernetes.io/rbd
EOF

cat <<EOF | tee ~/ceph/ceph-user-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-user-secret
  namespace: default
data:
  key: ${POOL_SECRET}
type: kubernetes.io/rbd
EOF

cat <<EOF | tee ~/ceph/ceph-user-secret-kube-system.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-user-secret
  namespace: kube-system
data:
  key: ${POOL_SECRET}
type: kubernetes.io/rbd
EOF

cat <<EOF | tee ~/ceph/ceph-storageclass.yaml
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: dynamic
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/rbd
parameters:
  monitors: ${MONITORS}
  adminId: admin
  adminSecretName: ceph-secret
  adminSecretNamespace: kube-system
  pool: kube
  userId: kube
  userSecretName: ceph-user-secret
EOF

oc adm create-bootstrap-project-template -o yaml | sed '/objects:/q' | tee -a ~/ceph/ceph-project-template.yaml
cat <<EOF | tee -a ~/ceph/ceph-project-template.yaml
- apiVersion: v1
  kind: Secret
  metadata:
    name: ceph-user-secret
  data:
    key: ${POOL_SECRET}
  type:
    kubernetes.io/rbd
EOF
oc adm create-bootstrap-project-template -o yaml | sed -e '1,/objects:/ d' | tee -a ~/ceph/ceph-project-template.yaml


oc apply -f ~/ceph/ceph-secret.yaml
oc apply -f ~/ceph/ceph-user-secret.yaml
oc apply -f ~/ceph/ceph-user-secret-kube-system.yaml
oc apply -f ~/ceph/ceph-storageclass.yaml
oc apply -f ~/ceph/ceph-project-template.yaml -n default
