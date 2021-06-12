local k8s = import 'k8s.libsonnet';

function(conf)

  // The base set of resources
  local base = k8s.list {
    items: std.prune([
      if conf.domain != null then self.ingress,
      self.service,
      self.deployment,
      self.pvc,
    ]),

    ingress:: {
      apiVersion: 'networking.k8s.io/v1',
      kind: 'Ingress',
      metadata: {
        name: 'docker-registry-ingress',
        labels: {
          app: 'docker-registry',
        },
        annotations: {
          [if conf.issuer != null then 'cert-manager.io/cluster-issuer']: conf.issuer,
        },
      },
      spec: {
        rules: [
          {
            host: conf.domain,
            http: {
              paths: [
                {
                  backend: {
                    service: {
                      name: 'docker-registry-service',
                      port: {
                        number: 5000,
                      },
                    },
                  },
                  path: '/',
                  pathType: 'Prefix',
                },
              ],
            },
          },
        ],
        tls: [
          {
            hosts: [
              conf.domain,
            ],
            secretName: 'registry-tls',
          },
        ],
      },
    },

    service:: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'docker-registry-service',
        labels: {
          app: 'docker-registry',
        },
      },
      spec: {
        selector: {
          app: 'docker-registry',
        },
        ports: [
          {
            protocol: 'TCP',
            port: 5000,
          },
        ],
      },
    },

    deployment:: {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'docker-registry',
        labels: {
          app: 'docker-registry',
        },
      },
      spec: {
        revisionHistoryLimit: 1,
        replicas: 1,
        selector: {
          matchLabels: {
            app: 'docker-registry',
          },
        },
        strategy: {
          type: 'Recreate',
        },
        template: {
          metadata: {
            labels: {
              app: 'docker-registry',
            },
          },
          spec: k8s.podSpec {
            shareProcessNamespace: true,
            containersObj:: {
              'docker-registry': k8s.container {
                image: 'registry',
                ports: [
                  {
                    containerPort: 5000,
                    protocol: 'TCP',
                  },
                ],
                volumeMountsObj:: {
                  storage: {
                    mountPath: '/var/lib/registry',
                  },
                },
                envObj:: {
                  REGISTRY_HTTP_ADDR: ':5000',
                  REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: '/var/lib/registry',
                },
              },
            },
            volumesObj:: {
              storage: {
                persistentVolumeClaim: {
                  claimName: 'registry-pvc',
                },
              },
            },
          },
        },
      },
    },

    pvc:: {
      apiVersion: 'v1',
      kind: 'PersistentVolumeClaim',
      metadata: {
        name: 'registry-pvc',
        labels: {
          app: 'docker-registry',
        },
      },
      spec: {
        accessModes: ['ReadWriteOnce'],
        // Specifying the volumeName prevents the volume being auto-created
        //volumeName: "registry-pv",
        resources: {
          requests: {
            storage: conf.volsize,
          },
        },
      },
    },
  };

  // Overlay for HTTP Basic authentication
  local auth_basic = {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containersObj+: {
              'docker-registry'+: {
                volumeMountsObj+: {
                  htpasswd: {
                    mountPath: '/auth',
                  },
                },
                envObj+: {
                  REGISTRY_AUTH_HTPASSWD_REALM: 'docker-registry-realm',
                  REGISTRY_AUTH_HTPASSWD_PATH: '/auth/htpasswd',
                },
              },
            },
            volumesObj+: {
              htpasswd: {
                secret: {
                  secretName: 'registry-htpasswd',
                },
              },
            },
          },
        },
      },
    },
  };

  local auth = {
    none: {},
    basic: auth_basic,
  };

  base + auth[conf.authtype]
