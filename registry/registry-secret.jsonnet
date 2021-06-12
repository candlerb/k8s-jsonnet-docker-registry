local namespace = 'registry';
local htpasswd = importstr 'registry.passwd';

// Use this command to create the registry.htpasswd file:
//   htpasswd -c -B registry.passwd <username>
// Repeat without '-c' to add additional entries.
//
// Note 1: only bcrypt hashing is supported by the registry
//
// Note 2: it's not necessary to restart the registry after redeploying, but it
// can take a minute or two to update in the container (the kubelet sync period)

{
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    name: 'registry-htpasswd',
    namespace: namespace,
  },
  data: {
    htpasswd: std.base64(htpasswd),
  },
  type: 'Opaque',
}
