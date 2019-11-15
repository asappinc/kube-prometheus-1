local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') + {
    _config+:: {
      namespace: 'monitoring',
    },
  };

local bases = [
    "namespace",
    "prometheus-operator",
    "prometheus-operator-serviceMonitor",
    "node-exporter",
    "kube-state-metrics",
    "alertmanager",
    "prometheus",
    "prometheus-adapter",
    "grafana"
  ];

local namespace = 
  { ['namespace/' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) };

local prometheus_operator =
  {
    ['prometheus-operator/' + name]: kp.prometheusOperator[name]
    for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
  };

local rometheus_operator_service_monitor = 
  { ['prometheus-operator-serviceMonitor/serviceMonitor']: kp.prometheusOperator.serviceMonitor };

local node_exporter =
  { ['node-exporter/' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) };

local kube_state_metrics =
  { ['kube-state-metrics/' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) };

local alertmanager =
  { ['alertmanager/' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) };

local prometheus =
  { ['prometheus/' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus)} +
  {'prometheus/roleBindingSpecificNamespaces':: super.prometheus} +
  {'prometheus/roleSpecificNamespaces':: super.prometheus};

local prometheus_adapter =
  { ['prometheus-adapter/' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) };

local grafana =
  { ['grafana/' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) };

local kustomizationResourceFile(name) = './' + std.split(name, "/")[1] + '.yaml';
local kustomizationBaseFile(name) = './' + name;

local kustomization = {
  apiVersion: 'kustomize.config.k8s.io/v1beta1',
  kind: 'Kustomization',
};

local kustomizationResource(name) = kustomization {
  resources: std.map(kustomizationResourceFile, std.objectFields( name )),
};

local kustomizationBase(bases) = kustomization {
  bases: std.map(kustomizationBaseFile, bases),
};

namespace {'../kustomize/namespace/kustomization': kustomizationResource(namespace),} +
prometheus_operator {'../kustomize/prometheus-operator/kustomization': kustomizationResource(prometheus_operator),} +
rometheus_operator_service_monitor {'../kustomize/prometheus-operator-serviceMonitor/kustomization': kustomizationResource(rometheus_operator_service_monitor),} +
node_exporter {'../kustomize/node-exporter/kustomization': kustomizationResource(node_exporter),} +
kube_state_metrics {'../kustomize/kube-state-metrics/kustomization': kustomizationResource(kube_state_metrics),} +
alertmanager {'../kustomize/alertmanager/kustomization': kustomizationResource(alertmanager),} +
prometheus {'../kustomize/prometheus/kustomization': kustomizationResource(prometheus),} +
prometheus_adapter {'../kustomize/prometheus-adapter/kustomization': kustomizationResource(prometheus_adapter),} +
grafana {'../kustomize/grafana/kustomization': kustomizationResource(grafana),} +
{ '../kustomize/kustomization': kustomizationBase(bases) }
