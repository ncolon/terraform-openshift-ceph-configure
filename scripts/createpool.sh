ceph osd pool create kube 128 128
ceph auth get-or-create client.kube mon 'allow r, allow command "osd blacklist"' osd 'allow class-read object_prefix rbd_children, allow rwx pool=kube' -o ceph.client.kube.keyring
ceph auth get-key client.admin | base64 > /tmp/client.admin.secret.txt
ceph auth get-key client.kube  | base64 > /tmp/client.kube.secret.txt
