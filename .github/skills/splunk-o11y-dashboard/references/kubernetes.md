# Kubernetes and AKS Dashboard Telemetry Rules

Use this reference whenever generating or reviewing Kubernetes, AKS, EKS, GKE, OpenShift, pod, container, node, namespace, or workload dashboards.

## Table of contents

- [Source priority](#source-priority)
- [Receiver metric versus exported metric](#receiver-metric-versus-exported-metric)
  - [Resolve conflicts between Collector internals and Splunk distribution documentation](#resolve-conflicts-between-collector-internals-and-splunk-distribution-documentation)
- [Translated metrics](#translated-metrics)
  - [Preserve the semantics of translated Kubernetes metrics](#preserve-the-semantics-of-translated-kubernetes-metrics)
- [Pod CPU telemetry](#pod-cpu-telemetry)
- [Pod memory telemetry](#pod-memory-telemetry)
- [CPU and memory utilization semantics](#cpu-and-memory-utilization-semantics)
- [CPU throttling](#cpu-throttling)
- [Container restarts](#container-restarts)
- [Namespace resource consumption](#namespace-resource-consumption)
- [Splunk built-in Kubernetes dashboards and navigators](#splunk-built-in-kubernetes-dashboards-and-navigators)
  - [Generic Kubernetes workload identity](#generic-kubernetes-workload-identity)
  - [Workload replica coverage](#workload-replica-coverage)
- [Workload semantics](#workload-semantics)
- [Replica availability](#replica-availability)
- [Node health](#node-health)
- [Node CPU and memory](#node-cpu-and-memory)
- [Kubernetes dashboard filter safety](#kubernetes-dashboard-filter-safety)
- [Final Kubernetes pre-generation gate](#final-kubernetes-pre-generation-gate)

## Source priority

For Kubernetes telemetry, use this priority:

1. Live telemetry from the target Splunk Observability Cloud environment.
2. Metric and dimension inventory supplied by the user.
3. Current Splunk documentation describing metrics exported by the Splunk Distribution of the OpenTelemetry Collector.
4. Current Splunk OTel Collector Helm chart configuration and exporter translation rules.
5. OpenTelemetry receiver documentation.
6. Otherwise mark the telemetry `UNVERIFIED`.

Do not treat receiver capability as proof that a metric reaches Splunk Observability Cloud.

## Receiver metric versus exported metric

Always distinguish:

- metric supported by an OpenTelemetry receiver
- metric enabled in the receiver
- metric processed by the Collector pipeline
- metric translated or renamed by the SignalFx exporter
- metric actually exported to Splunk Observability Cloud

A metric listed by the kubeletstats or Kubernetes cluster receiver is not automatically available in Splunk Observability Cloud.

When using the default Splunk Kubernetes Collector configuration, prefer current Splunk documentation whose `Exported?` status is `Yes`.

If Splunk documentation says `Exported? No`, do not generate that metric for a default-pipeline dashboard unless:

- live telemetry confirms it exists
- the user provides an inventory confirming it
- or the requested Collector configuration explicitly enables and exports it

### Resolve conflicts between Collector internals and Splunk distribution documentation

When sources disagree about whether Kubernetes telemetry reaches Splunk Observability Cloud, distinguish generic component defaults from the behavior of the complete Splunk Distribution pipeline.

Use this authority order for default Splunk Kubernetes deployments:

1. Live telemetry from the target Splunk Observability Cloud organization.
2. User-provided metric inventory from that organization.
3. Current Splunk documentation explicitly stating whether the metric is `Exported? Yes` or `Exported? No`.
4. Current rendered/default Splunk OTel Collector Helm configuration.
5. SignalFx exporter translation and exclusion defaults.
6. Generic OpenTelemetry receiver documentation.

If current Splunk documentation explicitly marks a metric:

`Exported? Yes`

treat availability in the documented default Splunk distribution as `VERIFIED_DOCS`, even if a lower-level exporter default list appears to exclude the translated metric.

Do not describe this situation as unresolved merely because the generic exporter defaults differ. The complete Splunk Collector pipeline can override or transform lower-level defaults.

This still does not prove that the metric exists in the user's organization. Keep its telemetry status as `VERIFIED_DOCS`, not `VERIFIED_LIVE`.

If Splunk documentation marks the source metric as both:

- `Translated? Yes`
- `Exported? Yes`

verify the final metric name visible in Splunk Observability Cloud before generating SignalFlow.

Use current Splunk built-in dashboard, navigator, official SignalFlow, or live Metric Finder evidence to establish the translated output metric name.

For example, documentation may describe the OpenTelemetry input as:

`container.cpu.utilization`

while Splunk Kubernetes dashboards or navigators use the translated SignalFx-compatible metric:

`container_cpu_utilization`

Do not assume those names are interchangeable without verifying the translation.

## Translated metrics

The SignalFx exporter can translate OpenTelemetry metrics into different metric names.

Do not assume the receiver-side name is the final Splunk Observability Cloud metric name.

For example, node CPU and memory dashboards may use translated host metrics rather than the original kubeletstats node metrics.

Verify:

1. source receiver metric
2. exporter translation
3. exported metric name
4. final unit
5. dimensions attached to the exported metric

before generating SignalFlow.

### Preserve the semantics of translated Kubernetes metrics

Do not infer the semantic meaning of a translated Splunk metric only from the lower-level source metric used to derive it.

A translated output metric can have different semantics, units, or aggregation behavior from its source representation.

When Splunk documentation or built-in Kubernetes dashboards identify a translated metric as a utilization metric, preserve that documented utilization semantic unless stronger live evidence proves otherwise.

For example, if current Splunk documentation identifies:

`container.cpu.utilization`

as an exported container CPU utilization signal and Splunk built-in Kubernetes views use the translated metric:

`container_cpu_utilization`

for Pod CPU monitoring, do not describe `container_cpu_utilization` as merely cumulative CPU time because its translation originates from CPU-time telemetry.

Instead verify:

1. the documented semantic of the translated output metric
2. its final unit
3. whether Splunk represents it as a ratio or percentage
4. the dimensions carried by the translated metric
5. whether aggregation across containers preserves the requested pod-level semantic

Treat source implementation details and output metric semantics separately.

Source derivation can explain how the metric is computed, but it must not override the documented meaning of the final exported metric.

If the translated metric's container-level utilization semantic is verified but pod-level aggregation is not:

- mark the container metric `VERIFIED_DOCS`
- keep Pod CPU Utilization `UNVERIFIED`
- state that the remaining uncertainty is pod-level aggregation semantics
- do not say that container CPU utilization telemetry is unavailable
- do not say that the translated metric is only cumulative CPU time

## Pod CPU telemetry

Do not assume `k8s.pod.cpu.utilization` is available merely because the kubeletstats receiver defines it.

For the default Splunk Kubernetes pipeline, verify whether that exact metric is exported.

If the direct pod metric is not exported, do not stop discovery immediately.

Check whether an exported container-level CPU metric exists with dimensions such as:

- `k8s.cluster.name`
- `k8s.namespace.name`
- `k8s.pod.name`
- `k8s.container.name`
- `k8s.node.name`

For example, current Splunk documentation can expose an exported container CPU utilization metric while the direct pod CPU utilization metric is not exported.

This establishes that CPU telemetry exists, but it does not automatically establish the correct pod-level formula.

Before deriving Pod CPU utilization from container telemetry, verify:

1. the container CPU metric's unit
2. what the utilization denominator represents
3. whether values are ratios or percentages
4. whether summing containers is semantically correct
5. whether averaging containers is semantically correct
6. behavior for multi-core containers and nodes
7. whether init or sidecar containers must be included
8. the grouping dimensions required to produce one stream per pod

Do not invent the aggregation.

If container CPU telemetry exists but pod aggregation cannot be verified:

- keep Pod CPU Utilization in the dashboard design
- mark it `UNVERIFIED`
- state that container CPU telemetry exists
- state that pod-level aggregation semantics still require verification
- omit the deployable chart

Do not report simply that "no pod CPU telemetry exists" when an exported container CPU source is available.

## Pod memory telemetry

Treat CPU and memory independently.

The availability of container CPU telemetry does not prove that container memory usage telemetry is exported.

Before generating pod memory utilization, verify an exported memory usage source such as:

- memory usage
- working set
- RSS

and separately verify the denominator used for the requested utilization semantic, such as:

- container or pod limit
- request
- node capacity
- another explicitly requested definition

Do not use memory request or memory limit as memory consumption.

If usage telemetry is unavailable, leave Pod Memory Utilization `UNVERIFIED`.

## CPU and memory utilization semantics

The word `utilization` is ambiguous.

Determine whether the requested panel means:

- absolute usage
- percentage of node capacity
- percentage of Kubernetes request
- percentage of Kubernetes limit
- percentage of another capacity definition

Do not choose one automatically.

If an exported metric already has documented utilization semantics, preserve those semantics.

If deriving utilization:

1. verify numerator
2. verify denominator
3. verify compatible units
4. verify grouping
5. verify whether the result is ratio or percentage
6. handle zero or missing denominator safely

Do not label a chart `%` merely because a ratio was calculated.

## CPU throttling

Do not invent a CPU throttling metric or formula.

Only generate throttling when a verified source exists, for example telemetry explicitly representing:

- throttled CPU periods
- throttled CPU seconds
- CFS throttling
- another documented throttling signal

Verify whether the source is:

- gauge
- counter
- cumulative counter

before applying rate or percentage calculations.

If no throttling telemetry is exported, keep the panel `UNVERIFIED`.

## Container restarts

Verify the exact restart metric and its type.

Do not automatically apply `rate()` or `delta()` to restart telemetry.

A restart metric can represent the current Kubernetes restart count and may reset when container history is removed.

If displaying the current restart count:

- preserve its gauge semantics
- aggregate containers to pod level only when that grouping is intended
- explain that the value is not necessarily a lifetime monotonic total

## Namespace resource consumption

Do not substitute Kubernetes requests or limits for actual consumption.

Requests and limits represent reservation or capacity configuration.

They are not CPU or memory usage.

For a `Top namespaces by resource consumption` panel:

1. identify a verified CPU usage or utilization source
2. identify a verified memory usage source when memory is part of the requested meaning
3. verify `k8s.namespace.name`
4. verify aggregation from container or pod to namespace
5. preserve units

If only CPU telemetry is available, a chart may be generated only if it is explicitly labelled as CPU consumption rather than generic resource consumption.

If the requested generic resource-consumption semantic cannot be satisfied, mark it `UNVERIFIED`.

## Splunk built-in Kubernetes dashboards and navigators

When resolving Kubernetes metric names, dimensions, entity identity, translated metrics, or workload semantics, also inspect current Splunk built-in dashboard and navigator documentation.

Treat Splunk's built-in Kubernetes dashboards and navigators as authoritative documentation evidence for telemetry that Splunk itself uses to identify and visualize Kubernetes entities.

Use this evidence after live telemetry, user inventory, and explicit exported-metric documentation, but before concluding that a dimension or workload metric is unavailable.

A built-in dashboard or navigator can establish that Splunk currently expects a metric or dimension to participate in a specific Kubernetes entity model.

Do not generalize that evidence beyond the telemetry where it is documented.

For example:

- seeing `k8s.workload.name` used with a Kubernetes workload metric establishes that a generic workload property is supported for that telemetry
- it does not establish that `k8s.workload.name` exists on every node, deployment, StatefulSet, or container metric
- seeing a translated metric such as `container_cpu_utilization` used for Pod CPU monitoring establishes its intended utilization semantics
- it does not by itself establish the correct aggregation from multiple containers into a pod-level percentage

Before declaring a requested Kubernetes signal unavailable, check:

1. current Splunk default exported-metric documentation
2. current Splunk built-in Kubernetes dashboards
3. current Splunk Kubernetes navigators
4. current Splunk Collector Helm configuration
5. exporter translation rules
6. receiver documentation

Do not conclude that a workload metric or dimension is unavailable merely because it was not found in one receiver table.

### Generic Kubernetes workload identity

Current Splunk Kubernetes telemetry can expose a generic workload identity such as:

`k8s.workload.name`

When a generic workload filter is requested:

1. verify whether `k8s.workload.name` is documented for the selected telemetry
2. use it for chart families where the dimension is present
3. use `apply_if_exist` only when provider behavior and the desired dashboard behavior support it
4. do not assume it filters workload-specific replica metrics unless those metrics also carry the property
5. use workload-specific dimensions where necessary for Deployment, StatefulSet, DaemonSet, ReplicaSet, Job, or CronJob telemetry

Do not state that no generic workload dimension exists when current Splunk dashboards or navigators document one.

### Workload replica coverage

When the user requests generic workload replica availability, investigate all documented workload families rather than stopping after Deployment.

Check current Splunk telemetry for matching desired/current/ready/available metric pairs for at least:

- Deployment
- StatefulSet
- DaemonSet
- ReplicaSet

Also consider Job or other workload types when replica semantics are meaningful for the request.

Only generate a workload family when both sides of the comparison and their identity dimensions are verified.

Do not omit a workload family merely because its desired metric was not found in the first documentation source. Check current Splunk built-in Kubernetes navigators and exported telemetry first.

Examples of documented metric families can include:

- Deployment desired versus available
- StatefulSet desired versus ready or current
- DaemonSet desired scheduled nodes versus current or ready scheduled nodes
- ReplicaSet desired versus available

Treat these names as candidates requiring current verification, not permanent universal constants.

## Workload semantics

Do not automatically interpret `workload` as `Deployment`.

Kubernetes workloads can include:

- Deployment
- StatefulSet
- DaemonSet
- ReplicaSet
- Job
- CronJob
- other workload controllers

Determine which workload type the requested telemetry supports.

If the user explicitly requests Deployment, use deployment dimensions and metrics.

If the user requests generic `workload`:

1. check which workload types have verified telemetry
2. determine whether a common workload dimension exists
3. otherwise represent workload types separately
4. clearly state any scope limitation

Do not expose a filter named simply `Workload` while silently implementing only Deployment semantics.

If only Deployment telemetry can be implemented, label the filter:

`Deployment`

or:

`Workload (Deployment only)`

and state that generic workload coverage remains unresolved.

## Replica availability

Generate replica availability only using matching desired and available or ready telemetry for the same workload type.

Examples of workload families can include:

- Deployment desired versus available
- ReplicaSet desired versus available
- StatefulSet desired versus ready/current
- DaemonSet desired scheduled versus ready/current scheduled

Do not mix desired replicas from one workload type with available replicas from another.

Before calculating a percentage:

1. verify both metrics
2. verify workload identity dimensions
3. verify namespace
4. verify zero desired-replica behavior
5. verify arithmetic alignment

## Node health

For node readiness telemetry, verify the current documented condition semantics.

When a readiness metric uses values such as:

- `1` = True
- `0` = False
- `-1` = Unknown

preserve those semantics explicitly.

Do not treat Unknown as Ready.

If combining False and Unknown into `Not Ready`, document that choice.

## Node CPU and memory

When the default Splunk pipeline exposes translated node-level metrics, prefer the exported metric name rather than a non-exported receiver-side metric.

Verify that the metric includes the required:

- cluster dimension
- node dimension

and verify the final unit after translation.

Do not convert or relabel the value without confirming its unit.

## Kubernetes dashboard filter safety

For each requested dashboard variable, determine which chart families actually contain that property.

Typical properties can include:

- `k8s.cluster.name`
- `k8s.namespace.name`
- `k8s.node.name`
- `k8s.pod.name`
- workload-specific properties

Do not assume every Kubernetes metric contains every property.

Use provider-supported optional filtering behavior only when appropriate and verified.

Do not make node-level charts disappear merely because a namespace variable is selected if node telemetry has no namespace dimension.

## Final Kubernetes pre-generation gate

Before generating each Kubernetes chart, record:

1. requested semantic
2. exported metric name
3. receiver/source
4. metric type
5. unit
6. required dimensions
7. aggregation
8. filter compatibility
9. telemetry status
10. SignalFlow validation status

If any required item cannot be established:

- retain the requested panel in the design
- mark it `UNVERIFIED`
- describe the missing evidence
- omit it from deployable Terraform

Correctly omitting a Kubernetes chart is preferable to generating a plausible but semantically incorrect metric query.