报错1：
calico-kube-controllers 报错信息如下：
Readiness probe errored: rpc error: code = Unknown desc = container not running
Readiness probe failed: Failed to read status file /status/status.json: unexpected end of JSON input


解决1：
# ETCD 地址
ETCD_ENDPOINTS="https://192.168.101.100:2379"
sed -i "s#.*etcd_endpoints:.*#  etcd_endpoints: \"${ETCD_ENDPOINTS}\"#g" calico.yaml
sed -i "s#__ETCD_ENDPOINTS__#${ETCD_ENDPOINTS}#g" calico.yaml

# ETCD 证书信息
ETCD_CA=`cat /etc/kubernetes/pki/etcd/ca.crt | base64 | tr -d '\n'`
ETCD_CERT=`cat /etc/kubernetes/pki/etcd/server.crt | base64 | tr -d '\n'`
ETCD_KEY=`cat /etc/kubernetes/pki/etcd/server.key | base64 | tr -d '\n'`

# 替换修改
sed -i "s#.*etcd-ca:.*#  etcd-ca: ${ETCD_CA}#g" calico.yaml
sed -i "s#.*etcd-cert:.*#  etcd-cert: ${ETCD_CERT}#g" calico.yaml
sed -i "s#.*etcd-key:.*#  etcd-key: ${ETCD_KEY}#g" calico.yaml

sed -i 's#.*etcd_ca:.*#  etcd_ca: "/calico-secrets/etcd-ca"#g' calico.yaml
sed -i 's#.*etcd_cert:.*#  etcd_cert: "/calico-secrets/etcd-cert"#g' calico.yaml
sed -i 's#.*etcd_key:.*#  etcd_key: "/calico-secrets/etcd-key"#g' calico.yaml

sed -i "s#__ETCD_CA_CERT_FILE__#/etc/kubernetes/pki/etcd/ca.crt#g" calico.yaml
sed -i "s#__ETCD_CERT_FILE__#/etc/kubernetes/pki/etcd/server.crt#g" calico.yaml
sed -i "s#__ETCD_KEY_FILE__#/etc/kubernetes/pki/etcd/server.key#g" calico.yaml

sed -i "s#__KUBECONFIG_FILEPATH__#/etc/cni/net.d/calico-kubeconfig#g" calico.yaml




报错2：
 Normal   Scheduled               28s                 default-scheduler  Successfully assigned kube-system/coredns-6f6b8cc4f6-t8p6q to node01
  Warning  FailedCreatePodSandBox  27s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "b7c95cf0ac9bbe8ad0529e6470fcfa6222feb61ccddbd4e3de99a8f682c623c0" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  25s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "beab595d150657c38306135c5e8e03cff5da455847f26c82a89a9b14794db587" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  24s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "4a046219c69ffa7c5208c71725c041a74ce391c644ad7c38ce7d865761ca7cf8" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  23s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "5af2d02cefe105ef2cdcfe9d8d0dca3f8976d42c514df86244c5450e425fb4ce" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  22s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "e3504b8a6ec2f5d282a8a7f985b2a7077852660ac0a82e1dd25d650cc6aa3501" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  21s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "d4e1da21e9f1e3c27c8d335384de690c1de33d88131e91aa98b9ae609ecb7f47" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  20s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "b4888eee629690bd0df9f72fcf4d2567e3385ffa87f6e61f2ff8c357e5e1cc14" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  19s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "3d6e840566399569dd786f1b0f77852a25fd0346a6b783105d2b9a5bbed5a4ed" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory
  Warning  FailedCreatePodSandBox  18s                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "5956b36b2b28e2c5277201d2edff6276c8fa7441acb8d7b8311a7f4c89ba0688" network for pod "coredns-6f6b8cc4f6-t8p6q": networkPlugin cni failed to set up pod "coredns-6f6b8cc4f6-t8p6q_kube-system" network: could not initialize etcdv3 client: open /etc/kubernetes/pki/etcd/server.crt: no such file or directory

解决2：
scp -rp /etc/kubernetes/pki/etcd/* node01:/etc/kubernetes/pki/etcd/
scp -rp /etc/kubernetes/pki/etcd/* node02:/etc/kubernetes/pki/etcd/

