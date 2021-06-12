{
  local k8s = self,

  // convert {"foo":"bar"} to [{"name":"foo","value":"bar"}]
  // convert {"foo":{...}} to [{"name":"foo",...}]
  namedList(tab,
            kfield='name',
            vfield='value'):: [
    (if std.isObject(tab[k]) then tab[k] else { [vfield]: tab[k] }) +
    { [kfield]: k }
    for k in std.objectFields(tab)
  ],

  // apply namespace to all objects
  replaceNamespace(data, namespace, key='items'):: data {
    [key]: [
      item { metadata+: { namespace: namespace } }
      for item in super[key]
    ],
  },

  // template objects
  list:: {
    apiVersion: 'v1',
    kind: 'List',
    items: [],
  },

  podSpec:: {
    initContainers: k8s.namedList(self.initContainersObj),
    initContainersObj:: {},
    containers: k8s.namedList(self.containersObj),
    containersObj:: error 'Missing containersObj',
    volumes: k8s.namedList(self.volumesObj),
    volumesObj:: {},
    hostAliases: k8s.namedList(self.hostAliasesObj, 'ip', 'hostnames'),
    hostAliasesObj:: {},
  },

  container:: {
    env: k8s.namedList(self.envObj),
    envObj:: {},
    volumeMounts: k8s.namedList(self.volumeMountsObj),
    volumeMountsObj:: {},
  },
}
