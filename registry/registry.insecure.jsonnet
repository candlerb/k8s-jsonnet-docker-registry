local conf = {
  // The namespace to deploy into
  namespace: 'registry',

  // The FQDN that the registry is accessed as (set to null to disable ingress)
  domain: null,

  // Certificate issuer for cert-manager (set to null for no certificate)
  issuer: null,

  // Authentication (none|basic)
  authtype: 'none',

  // Storage volume size
  volsize: '20Gi',
};

local registry = import 'registry-resources.libsonnet';
local k8s = import 'k8s.libsonnet';

k8s.replaceNamespace(registry(conf), namespace=conf.namespace)
