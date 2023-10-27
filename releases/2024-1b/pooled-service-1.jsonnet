local hash = importstr 'pooled-service-1.version.txt';
local imageStr = "486157446650.dkr.ecr.us-east-1.amazonaws.com/k8s-test-1@sha256:" + hash;
{
    apiVersion: 'ecms.scholastic.com/v1',
    kind: 'PooledService',
    metadata: {
      name: 'test-pooled-service-1'
    },
    spec: {
      serviceName: 'k8s-poolsvc-1',
      serviceAccountName: 'asset-service',
      serviceType: 'ClusterIP',
      servicePorts: [
          {
              port: 80,
              targetPort: 8080,
              name: "http"
          },
          {
              port: 5701,
              targetPort: 5701,
              name: "hazelcast"
          }
      ],
      containers: [
          {
            name: 'k8s-test-1',
            image: imageStr,
            imagePullPolicy: 'Always',
            resources: {
                requests: {
                    cpu: '500m',
                    memory: '200Mi'
                }
            },
            ports: [
                {
                    containerPort: 8080
                }
            ],
            env: [
                {
                    name: 'SERVICE_BASEPATH',
                    value: "/data"
                },
                {
                    name: 'SERVER_FORWARD_HEADERS_STRATEGY',
                    value: "framework"
                },
                {
                    name: 'SERVICE_CLUSTER_STRATEGY',
                    value: "kubernetes"
                },
                {
                    name: 'SERVICE_CLUSTER_KUBERNETES_SERVICENAME',
                    value: "k8s-poolsvc-1"
                }
           ],
          volumeMounts: [
            {
                name: 'persistent-storage',
                mountPath: "/data"
            }
          ],
          startupProbe: {
            httpGet: {
              path: "/actuator/health",
              port: 8080
            },
            initialDelaySeconds: 5,
            periodSeconds: 2,
            failureThreshold: 30
          },
          readinessProbe: {
            httpGet: {
              path: "/actuator/health",
              port: 8080
            },
            periodSeconds: 2,
            failureThreshold: 30
          }
         }
      ],
      volumes: [
         {
            name: 'persistent-storage',
            persistentVolumeClaim: {
                claimName: 'efs-claim'
            }
         }
      ],
      maxCorePoolReplicas: 1,
      maxTotalReplicas: 5,
      targetCpuUtilization: 50,
      scaleUpRules: {
        stabilizationWindowSeconds: 60,
        policies: [
            {
                type: 'Pods',
                value: 1,
                periodSeconds: 30
            },
            {
                type: 'Percent',
                value: 50,
                periodSeconds: 120
            }
        ],
        selectPolicy: 'Max'
      },
      scaleDownRules: {
        stabilizationWindowSeconds: 60,
        policies: [
            {
                type: 'Percent',
                value: 50,
                periodSeconds: 300
            },
            {
                type: 'Percent',
                value: 20,
                periodSeconds: 60
            }
        ],
        selectPolicy: 'Min'
      }
    }
}