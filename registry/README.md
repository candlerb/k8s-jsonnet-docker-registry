# Configuration file

There are three sample configuration files provided:

* `registry.insecure.jsonnet` is insecure (http) without ingress
* `registry.https.jsonnet` enables ingress and https certificate
* `registry.auth.jsonnet` enables https certificate and authentication

Copy one of these to `registry.jsonnet` and edit it as required: e.g.

```
cp registry.insecure.jsonnet registry.jsonnet
vi registry.jsonnet
```

Create the namespace and the other resources:

```
kubectl create ns registry
jsonnet registry.jsonnet | kubectl apply -f -
```

## Insecure without ingress

You can find the service cluster IP allocated:

```
# kubectl get service -n registry
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
docker-registry-service   ClusterIP   10.43.101.144  <none>        5000/TCP   20d
```

This can be used directly on port 5000. although only from the local cluster.
The address is cluster-internal and will change if you delete and redeploy
the registry.

Note that most users of a docker registry will default to HTTPS and require
special configuration to be able to communicate over HTTP.  For example,
with `k3s` you can edit `/etc/rancher/k3s/registries.yaml`:

```
mirrors:
  "registry.localdomain":
    endpoint:
      - "http://10.43.101.144:5000"
```

## With ingress and https

An ingress resource will be created if you set `domain` in your config file. 
This must resolve to your cluster's IP address.

If you have deployed [cert-manager](https://cert-manager.io/) in your
cluster then it will use it to obtain a certificate.

BEWARE: without additional restrictions, your cluster will be accessible to
the world for image pushes and pulls!

## With ingress, https and basic authentication

This limits access to your registry by username and password.

To use this, you will need to create a file of usernames with bcrypt
password hashes:

```
htpasswd -c -B registry.passwd <username>
```

(repeat without `-c` to add more users).  Then use it to create a "secret"
object in kubernetes:

```
jsonnet registry-secret.jsonnet | kubectl apply -f -
```

Test:

```
# this should give UNAUTHORIZED response
curl https://registry.your-domain.com/v2/_catalog
# this should work
curl https://username:password@registry.your-domain.com/v2/_catalog
```

For k3s to be able to pull images from the registry, add the credentials
into `/etc/rancher/k3s/registries.yaml`

```
configs:
  "registry.your-domain.com":
    auth:
      username: <plaintext-username>
      password: <plaintext-password>
```
