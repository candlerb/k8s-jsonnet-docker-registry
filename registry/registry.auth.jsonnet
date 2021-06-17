local conf = {
  // The namespace to deploy into
  namespace: 'registry',

  // The FQDN that the registry is accessed as (set to null to disable ingress)
  domain: 'registry.your-domain.com',

  // Certificate issuer for cert-manager (set to null for no certificate)
  issuer: 'letsencrypt-prod',

  // Authentication (none|basic)
  authtype: 'basic',

  // Storage volume size
  volsize: '20Gi',
};

// Example of local post-processing
local patch = {
  ingress+: {
    metadata+: {
      annotations+: {
        'kubernetes.io/ingress.class': 'traefik',
      },
    },
  },
};

local registry = import 'registry-resources.libsonnet';
local k8s = import 'k8s.libsonnet';

k8s.replaceNamespace(registry(conf) + patch, namespace=conf.namespace)
