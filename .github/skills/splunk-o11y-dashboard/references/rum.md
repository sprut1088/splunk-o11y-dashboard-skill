# RUM dashboard telemetry rules

## Contents

- [Evidence priority](#evidence-priority)
- [Metric existence versus metric semantics](#metric-existence-versus-metric-semantics)
- [Application scoping](#application-scoping)
- [Mobile application starts](#mobile-application-starts)
- [Start-duration percentiles](#start-duration-percentiles)
- [Errors and crashes](#errors-and-crashes)
- [Sessions](#sessions)
- [Screen and route performance](#screen-and-route-performance)
- [RUM dimensions and dashboard filters](#rum-dimensions-and-dashboard-filters)
- [Generate mode](#generate-mode)
- [RUM pre-generation gate](#rum-pre-generation-gate)

## Evidence priority

For Splunk RUM dashboards, use this priority:

1. Live target-org RUM metric and dimension metadata.
2. User-supplied telemetry inventory.
3. Official Splunk RUM documentation and official Splunk RUM data-model documentation.
4. Official OpenTelemetry mobile/web semantic conventions where relevant to raw telemetry.
5. Otherwise mark the requirement `UNVERIFIED`.

Do not treat community repositories, examples, or third-party dashboards as authoritative proof that a metric dimension or aggregation is available in the target Splunk organization.

Documentation proves that telemetry is defined by Splunk. It does not prove that the telemetry is present in the user's organization.


## Metric existence versus metric semantics

Verifying a RUM metric name is not sufficient to generate SignalFlow.

Before generating deployable SignalFlow, verify:

1. exact metric name
2. metric type
3. unit
4. aggregation semantics
5. supported dimensions
6. whether cross-series aggregation preserves the requested meaning
7. whether the metric is available for the requested mobile platform

If metric type or aggregation semantics are unresolved, keep the panel in the design as `UNVERIFIED` and omit deployable SignalFlow.

Do not assume that a metric ending in `.count` can safely use `.sum()`, `.rate()`, `.delta()`, or another transformation.

Do not infer counter, gauge, cumulative-counter, or interval-count semantics from the metric name alone.


## Application scoping

A dashboard requested for a specific application must not silently become an all-applications dashboard.

Before generating application-scoped charts, verify the exact application dimension attached to the selected RUM metric.

A documented span or event attribute such as `app` does not prove that the same property is available as a dimension on a `rum.\*` metric.

If application scoping cannot be verified:

- keep the application filter in the dashboard design
- mark it `UNVERIFIED`
- omit the dashboard variable from deployable Terraform
- do not generate charts that are presented as application-specific
- if an unscoped chart is retained for diagnostic value, label it explicitly as cross-application and do not claim it satisfies an application-scoped requirement


## Mobile application starts

Splunk documentation may expose mobile start telemetry such as cold, warm, or hot starts.

Treat metric existence, start-type semantics, platform support, metric type, and aggregation behavior as separate verification requirements.

Do not define "application launches" by summing cold, warm, and hot starts unless Splunk documentation or live telemetry explicitly establishes that this is the correct launch definition.

If no authoritative launch definition exists, keep Application Launches `UNVERIFIED`.

Do not assume warm-start telemetry exists on every platform.


## Start-duration percentiles

Do not fabricate p50, p95, or p99 from a documented p75 metric.

A precomputed percentile metric represents that percentile only.

Do not average, sum, or otherwise combine percentile series and describe the result as the same percentile unless the operation is explicitly valid for the selected telemetry.

For a documented metric such as a start-duration p75 metric:

- preserve p75 semantics
- preserve the documented source unit
- do not relabel it p50, p95, or p99
- do not combine percentile series across dimensions unless the aggregation is verified to preserve percentile meaning

A chart display unit does not perform numeric conversion.


## Errors and crashes

Treat crashes and application errors according to Splunk's documented definitions.

Do not assume:

- crashes are equivalent to all frontend errors
- app errors are equivalent across Android and iOS
- ANRs, handled exceptions, reported errors, and crashes have identical semantics
- crash rate can be calculated without a verified denominator and aggregation model

If platform-specific definitions differ, preserve those differences in the dashboard design and chart descriptions.


## Sessions

A documented RUM session concept does not prove the existence of a session-count metric.

Before generating a session panel, verify:

- exact session telemetry source
- whether it is a metric, event, or derived value
- uniqueness semantics
- time-window behavior
- dimensions available for filtering

Do not derive session counts from unrelated RUM event counts.


## Screen and route performance

Do not assume that mobile screen performance, web route performance, RUM nodes, spans, or navigation events are interchangeable.

Verify the exact telemetry source and operational meaning before generating screen or route panels.

A dimension such as a node, route, screen, or operation name is valid only when verified for the selected telemetry.


## RUM dimensions and dashboard filters

Verify every requested RUM filter against the selected metric series.

Common concepts that still require verification include:

- application
- environment
- application version
- device model
- operating system
- browser
- screen
- route
- platform

Do not promote a span attribute to a metric dimension without evidence.

If a property is documented only for spans or events, it remains unverified for `rum.\*` metric filtering until confirmed.


## Generate mode

In Generate mode:

- read-only telemetry discovery is allowed
- official documentation lookup is allowed
- do not run generated SignalFlow against the target environment
- do not run `terraform init`, `terraform validate`, or `terraform plan`
- do not publish or modify Splunk resources

Documentation-backed telemetry may be labelled `VERIFIED\_DOCS`.

Telemetry is `VERIFIED\_LIVE` only when confirmed from the target Splunk organization.


## RUM pre-generation gate

Before emitting a deployable RUM chart, confirm all of the following:

- metric exists
- metric type is known
- unit is known
- aggregation behavior is known
- requested semantic matches the metric
- required dimensions are verified
- application scope is correct
- platform differences are preserved
- percentile handling is mathematically valid
- no requested filter is being silently replaced with another property

If any required condition fails, keep the panel in the design as `UNVERIFIED` and omit deployable Terraform for that panel.
