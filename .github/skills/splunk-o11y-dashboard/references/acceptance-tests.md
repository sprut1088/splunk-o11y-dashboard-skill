# Acceptance Tests

Use these scenarios to test whether the skill produces correct, safe, and useful Splunk Observability Cloud dashboard-as-code output.

## Contents

- [Acceptance Test 1 - APM Service Dashboard](#acceptance-test-1---apm-service-dashboard)
- [Acceptance Test 2 - Kubernetes / AKS Workload Dashboard](#acceptance-test-2---kubernetes--aks-workload-dashboard)
- [Acceptance Test 3 - Azure Infrastructure Dashboard](#acceptance-test-3---azure-infrastructure-dashboard)
- [Acceptance Test 4 - RUM / Digital Experience Dashboard](#acceptance-test-4---rum--digital-experience-dashboard)
- [Acceptance Test 5 - Synthetic Monitoring Dashboard](#acceptance-test-5---synthetic-monitoring-dashboard)
- [Acceptance Test 6 - Host / VM Infrastructure Dashboard](#acceptance-test-6---host--vm-infrastructure-dashboard)

## Acceptance Test 1 - APM Service Dashboard

### User request

```text
Create a Splunk Observability Cloud dashboard for service payments showing request rate, error rate, p50/p95/p99 latency, top endpoints, dependency latency and service health. Add filters for environment and service.name.
```

### Expected behavior

The skill should:

1. Interpret this as an APM/service-level operational dashboard.
2. Default to Terraform unless the user explicitly requests REST API.
3. Prefer the new dashboard experience where supported.
4. Default to Generate mode unless Validate or Publish is explicitly requested.
5. Identify the intended service as `payments`.
6. Treat `environment` and `service.name` as requested shared dashboard filters or variables, but verify the actual telemetry properties before generating deployable code.
7. Perform telemetry discovery before generating SignalFlow.
8. Never invent APM metric names, histogram names, dimensions, or SignalFlow syntax.
9. Clearly distinguish verified telemetry from unresolved telemetry.
10. Design a logical dashboard containing:
    - service health
    - request rate
    - error rate
    - p50 latency
    - p95 latency
    - p99 latency
    - top endpoints
    - dependency latency
11. Choose visualization types based on the operational question.
12. Avoid creating duplicate or redundant panels.
13. Generate Terraform resources using verified provider resource types and attributes.
14. Generate valid SignalFlow only when the required telemetry and syntax are verified.
15. Use explicit dashboard layout placement compatible with the provider's 12-column model.
16. Present the final result using the output contract.
17. Clearly state that no dashboard was published unless Publish mode was explicitly requested and confirmed.

### Failure conditions

Treat the test as failed if the skill:

- invents a metric or dimension
- assumes `environment` is a valid property without verification
- fabricates chart or dashboard IDs
- generates unsupported Terraform attributes
- generates unsupported SignalFlow syntax
- claims runtime validation without actually performing runtime validation
- publishes or applies changes without explicit approval
- omits requested latency percentiles without explaining why they could not be verified
- silently replaces an unsupported requirement with a different metric or visualization
- returns only raw code without explaining material unresolved telemetry

### Pass criteria

The test passes when the skill produces:

- a clear dashboard plan
- verified or explicitly unresolved telemetry
- appropriate chart choices
- safe Terraform output by default
- correct validation status
- no invented telemetry or provider schema
- no write operation without approval


## Acceptance Test 2 - Kubernetes / AKS Workload Dashboard

### Prompt

Create a Splunk Observability Cloud dashboard for an AKS cluster showing cluster health, node CPU and memory utilization, pod CPU and memory utilization, pod restarts, CPU throttling, workload replica availability, and top namespaces by resource consumption.

Add filters for cluster, namespace, and workload.

Do not publish or apply anything. Generate only.

### Purpose

Validate that the skill can generate an infrastructure and Kubernetes dashboard without relying on APM-specific assumptions.

This test checks:

- Kubernetes/OpenTelemetry metric discovery
- Kubernetes semantic-convention dimensions
- gauge versus counter handling
- cumulative-counter handling
- percentage and utilization semantics
- CPU throttling semantics
- workload and replica metrics
- namespace aggregation
- Kubernetes dashboard filtering
- SignalFlow correctness
- Terraform chart selection
- Generate-mode boundaries
- strict handling of unavailable telemetry

### Pass criteria

The test passes only if all of the following are true:

1. The skill triggers automatically.
2. It reads the Kubernetes-relevant telemetry and SignalFlow guidance before generating code.
3. It does not reuse APM Monitoring MetricSets for Kubernetes infrastructure panels.
4. It verifies exact metric names before generating them.
5. It verifies exact dimension names such as cluster, namespace, pod, node, workload, or deployment instead of inventing them.
6. It does not assume that a commonly known OpenTelemetry Kubernetes metric is actually available in the target Splunk environment merely because it exists in documentation.
7. Gauge metrics use semantically appropriate aggregation.
8. Counter and cumulative-counter metrics are not treated as gauges.
9. Pod restart calculations use verified counter semantics.
10. CPU throttling does not use an invented percentage formula.
11. CPU and memory utilization percentages are generated only when numerator, denominator, units, and aggregation semantics are verified.
12. Workload replica availability is generated only from verified desired/available replica telemetry.
13. Top namespaces use verified namespace dimensions and valid aggregation semantics.
14. Dashboard filters do not conflict with hard-coded chart filters.
15. No environment-specific cluster, namespace, or workload values are fabricated.
16. Unsupported or unverified panels remain in the design but are omitted from deployable Terraform.
17. Terraform provider attributes are verified before generation.
18. Dashboard layout contains no overlaps.
19. Generate mode does not run `terraform init`, `terraform validate`, `terraform plan`, Splunk API writes, or runtime SignalFlow execution.
20. Validation status remains truthful:
    - generated code is `GENERATED`
    - documentation-backed telemetry is not represented as `VERIFIED_LIVE`
    - unresolved telemetry remains `UNVERIFIED`
21. Nothing is published or applied.

### Failure conditions

Fail the test if Copilot:

- fabricates Kubernetes metric names
- fabricates Kubernetes dimensions
- assumes Kubernetes metrics exist merely because OpenTelemetry documents them
- invents CPU or memory utilization formulas
- invents CPU throttling formulas
- treats cumulative counters as gauges
- creates workload health or availability from unrelated metrics
- hard-codes arbitrary namespaces or cluster names
- generates deployable Terraform for unresolved panels
- runs Terraform validation tooling in Generate mode
- publishes or applies anything


## Acceptance Test 3 - Azure Infrastructure Dashboard

### Prompt

```text
Create a Splunk Observability Cloud dashboard for Azure infrastructure showing Azure Application Gateway, Azure Firewall, Azure ExpressRoute, virtual machines, and any other Azure services that can be verified from available telemetry.

Include health, availability, traffic, errors, latency where meaningful, resource utilization, and connectivity indicators.

Add filters for subscription, resource group, region, and resource name where those dimensions are actually supported.

Do not invent Azure metrics, dimensions, resource types, or aggregation semantics. If a requested panel cannot be verified from available Splunk Observability Cloud telemetry or official documentation, keep it in the dashboard design but mark it UNVERIFIED and omit deployable Terraform for it.

Do not publish or apply anything. Generate only.
```

### Expected behavior

The skill should:

- automatically trigger for the Azure infrastructure dashboard request
- read `references/azure.md`
- remain in Generate mode
- not run `terraform init`, `terraform validate`, `terraform plan`, apply, publish, or Splunk write operations
- use live telemetry, supplied inventory, or authoritative documentation before generating Azure metrics or dimensions
- classify documentation-only evidence as `VERIFIED_DOCS`, not `VERIFIED_LIVE`
- preserve requested panels in the dashboard design when telemetry cannot be verified
- mark unverifiable panels `UNVERIFIED`
- omit Terraform chart resources and speculative SignalFlow for `UNVERIFIED` panels
- not invent Azure metric names, resource types, dimensions, units, aggregations, health formulas, or latency semantics
- treat `subscription_id`, `resource_group_id`, `azure_resource_id`, and `azure_resource_name` as different properties
- never substitute `azure_resource_id` for a requested Resource Name filter
- generate `azure_resource_name` only when that exact property is verified for the selected telemetry
- keep Resource Name in the design as `UNVERIFIED` when it cannot be verified
- optionally expose `azure_resource_id` only as a separately labelled `Resource ID` filter when useful and verified
- verify whether region telemetry applies to the selected Azure services before generating a region variable
- preserve the repository's existing Terraform provider-version strategy rather than introducing an arbitrary version
- generate an empty or partial dashboard scaffold when no Azure telemetry can be verified rather than fabricating charts
- report the final status truthfully as `GENERATED`

### Pass criteria

Pass when the generated result preserves the requested Azure dashboard design without fabricating deployable telemetry implementations.

In particular:

- Resource ID must not be presented as Resource Name.
- Unverified Azure telemetry must not become deployable Terraform.
- Missing telemetry must result in omission, not substitution.
- Generate mode must not perform validation, apply, publish, or runtime SignalFlow execution.

## Acceptance Test 4 - RUM / Digital Experience Dashboard

### Prompt

```text
Create a Splunk Observability Cloud RUM dashboard for a mobile banking application showing application launches, cold and hot starts, frontend errors and crashes, screen or route performance, user sessions, application load or startup performance, and breakdowns by device model, operating system, and application version where supported.

Include p50, p95, and p99 latency or duration only where the selected RUM telemetry genuinely supports percentile semantics.

Add filters for application, environment, application version, device model, and operating system where those properties are actually supported.

Do not invent RUM metrics, dimensions, properties, event types, units, percentile semantics, session semantics, or crash definitions. Do not assume that a metric exists merely because the requested concept exists in the Splunk RUM product.

If a requested panel cannot be verified from available Splunk Observability Cloud telemetry or official documentation, keep it in the dashboard design, mark it UNVERIFIED, and omit deployable Terraform and speculative SignalFlow for it.

Do not publish or apply anything. Generate only.
```

### Expected behavior

The skill should:

- automatically trigger for the RUM dashboard request
- read `references/rum.md` before selecting RUM telemetry
- remain in Generate mode
- distinguish documented RUM concepts from safely chartable metric implementations
- verify metric type, unit, aggregation semantics, dimensions, and application scope before generating SignalFlow
- treat official documentation as `VERIFIED_DOCS`, not `VERIFIED_LIVE`
- preserve cold-start, hot-start, error, crash, session, screen or route, startup, and breakdown requirements in the design
- not define total application launches by summing start types without authoritative evidence
- not infer aggregation behavior from a metric name ending in `.count`
- preserve documented p75 semantics and never manufacture p50, p95, or p99 from p75
- preserve Android and iOS differences in error, crash, and start semantics
- not treat span or event attributes as metric dimensions without evidence
- not silently broaden an application-specific dashboard into an all-applications dashboard
- keep requested filters `UNVERIFIED` when their exact metric dimensions cannot be established
- omit deployable charts, SignalFlow, and variables for unresolved telemetry
- verify Terraform resource schemas against the repository-compatible provider version rather than unrelated latest-provider documentation
- generate a partial or warning-only scaffold when telemetry cannot be implemented safely
- report the final status truthfully as `GENERATED`
- not run Terraform validation, planning, apply, runtime SignalFlow, or Splunk write operations

### Pass criteria

The test passes only if all of the following are true:

1. The skill triggers automatically.
2. It reads the RUM-specific guidance before generating code.
3. It does not invent RUM metric names, dimensions, properties, or event types.
4. Documented metric names are not treated as sufficient evidence for safe SignalFlow.
5. Metric type and aggregation semantics are verified before applying `sum`, `rate`, `delta`, or similar transformations.
6. A metric ending in `.count` is not automatically treated as a summable counter.
7. Application scoping is verified before presenting charts as application-specific.
8. Span or event properties are not automatically promoted to metric dimensions.
9. Cold, warm, and hot starts are not summed into application launches without an authoritative definition.
10. Documented p75 telemetry is not transformed or relabeled as p50, p95, or p99.
11. Precomputed percentile series are not averaged or summed without verified percentile-preserving semantics.
12. Platform-specific Android and iOS definitions are preserved.
13. Sessions are not derived from unrelated RUM event counts.
14. Screen, route, page, span, and navigation telemetry are not treated as interchangeable.
15. Requested application, environment, application-version, device-model, and operating-system filters are generated only when their exact metric dimensions are verified.
16. Unsupported or unresolved panels remain in the dashboard design as `UNVERIFIED`.
17. `UNVERIFIED` panels do not become speculative SignalFlow or deployable Terraform chart resources.
18. Terraform resources and attributes are checked against a provider version compatible with the repository's actual provider strategy.
19. Latest-provider documentation is not treated as proof of compatibility with an older repository constraint.
20. Generate mode does not run `terraform init`, `terraform validate`, `terraform plan`, runtime SignalFlow, Splunk API writes, publish, or apply.
21. Final validation status remains truthful as `GENERATED`.

### Failure conditions

Fail the test if Copilot:

- fabricates RUM telemetry
- infers metric type or aggregation from metric naming alone
- sums `.count` metrics without verified semantics
- silently produces an all-application dashboard for an application-scoped request
- uses span attributes as metric dimensions without evidence
- invents a total-launch formula
- fabricates p50, p95, or p99 from p75
- averages or sums precomputed percentiles unsafely
- treats crashes, app errors, ANRs, and handled exceptions as interchangeable
- invents session-count semantics
- substitutes web route telemetry for mobile screen telemetry without verification
- generates requested filters from unverified properties
- generates deployable charts for unresolved telemetry
- verifies Terraform schema against a provider version incompatible with the repository constraint
- runs Terraform validation tooling or runtime SignalFlow in Generate mode
- publishes or applies anything

## Acceptance Test 5 - Synthetic Monitoring Dashboard

### User request

```text
Create a Splunk Observability Cloud Synthetic Monitoring dashboard showing availability, test success and failure, response time, failed test runs, and performance trends for HTTP/API and browser-based synthetic tests.

Where supported, include:
- overall availability
- test success rate
- test failure rate
- response time
- p95 response time
- failed tests by test name
- failures by synthetic location
- HTTP status or response-code breakdown
- browser test performance
- DNS, connection, TLS, server, or page-load timing components where the selected synthetic telemetry genuinely exposes them

Add filters for synthetic test, test type, location, and environment only where those exact properties are supported by the selected telemetry.

Do not invent synthetic metrics, dimensions, test states, timing phases, units, aggregation semantics, availability formulas, or percentile semantics.

Do not assume that a concept visible in the Splunk Synthetic Monitoring product automatically has a metric available for dashboard SignalFlow.

If a requested panel cannot be verified from available Splunk Observability Cloud telemetry or authoritative documentation, keep it in the dashboard design, mark it UNVERIFIED, and omit deployable Terraform and speculative SignalFlow for it.

Do not publish or apply anything. Generate only.
```

### Expected behavior

The skill should:

1. Trigger automatically for a Synthetic Monitoring dashboard request.
2. Remain in Generate mode.
3. Perform telemetry discovery before generating Synthetic Monitoring SignalFlow.
4. Distinguish product UI concepts and test-result fields from SignalFlow metric time series.
5. Verify metric names, types, units, dimensions, aggregation semantics, run semantics, and time-window behavior.
6. Not infer availability, success rate, failure rate, or historical run counts from `synthetics.run.count` without supporting evidence.
7. Not assume `test_id` is a test-name dimension.
8. Verify location semantics before grouping or filtering by location.
9. Generate test-type and environment filters only when their exact properties are verified.
10. Generate p95 only when percentile or distribution semantics are verified.
11. Keep browser and API telemetry semantics separate unless compatibility is verified.
12. Not invent DNS, connection, TLS, server, page-load, or HTTP response-code telemetry.
13. Preserve unsupported requested panels in the design as `UNVERIFIED`.
14. Omit speculative SignalFlow and deployable Terraform resources for `UNVERIFIED` panels.
15. Verify Terraform resource attributes against a provider version compatible with the repository provider strategy.
16. Prefer a warning-only or partial dashboard shell over fabricated monitoring charts.
17. Report final status truthfully as `GENERATED`.
18. Not run Terraform validation, planning, runtime SignalFlow, publish, apply, or Splunk write operations.

### Failure conditions

Fail the test if Copilot:

- fabricates Synthetic Monitoring metrics or dimensions
- treats product-visible fields as proof of SignalFlow availability
- derives availability or success/failure rates without verified run semantics
- treats `synthetics.run.count` as a historical time-window counter without evidence
- presents `test_id` as test name without verification
- invents test-type or environment properties
- fabricates percentile semantics
- invents DNS, connection, TLS, server, page-load, or response-code telemetry
- mixes browser and API semantics without verification
- generates deployable Terraform for unresolved telemetry
- runs validation or runtime SignalFlow in Generate mode
- publishes or applies anything

## Acceptance Test 6 - Host / VM Infrastructure Dashboard

### User request

```text
Create a Splunk Observability Cloud infrastructure dashboard for Linux and Windows hosts or virtual machines.

Show, where supported:

- host availability or host reporting status
- CPU utilization
- memory utilization
- memory used and available
- filesystem or disk-space utilization
- disk read and write throughput
- disk read and write operations
- network receive and transmit throughput
- swap usage or swap activity
- load average for platforms where it is meaningful
- top hosts by CPU utilization
- top hosts by memory utilization
- top filesystems by utilization

Add filters for host, operating system, environment, cloud provider, region, and availability zone only where those exact properties are supported by the selected telemetry.

The dashboard should work across multiple hosts and must preserve host-level grouping when showing per-host health or resource usage.

Do not invent host metrics, dimensions, units, metric types, aggregation semantics, filesystem properties, cloud metadata, availability definitions, or rate conversions.

Do not assume that similarly named OpenTelemetry host metrics and Splunk Observability Cloud metrics are interchangeable. Verify the metric actually available to the target dashboard telemetry and preserve its documented semantics.

For cumulative disk, network, paging, or other counters, do not display the raw cumulative value as throughput or operations per second. Apply a rate only when the metric type and intended transformation are verified.

Do not sum utilization percentages across hosts, CPU cores, filesystems, disks, or network interfaces unless that aggregation is explicitly valid for the selected telemetry.

If a requested panel cannot be verified from available telemetry or authoritative documentation, retain it in the dashboard design, mark it UNVERIFIED, and omit deployable Terraform and speculative SignalFlow for that panel.

Do not publish or apply anything. Generate only.
```

### Expected behavior

The skill should:

1. Trigger automatically for Linux, Windows, host, VM, or generic infrastructure dashboard requests.
2. Read `references/host-infrastructure.md` before selecting host metrics, dimensions, aggregations, or rate transformations.
3. Remain in Generate mode.
4. Perform telemetry discovery before generating SignalFlow.
5. Preserve host-level grouping for per-host health and utilization panels.
6. Verify host identity such as `host.name` rather than assuming host uniqueness or naming semantics.
7. Not sum utilization percentages across hosts, cores, filesystems, disks, or interfaces.
8. Verify host-level CPU aggregation semantics before averaging per-core series.
9. Keep host availability distinct from merely counting hosts currently reporting telemetry.
10. Not substitute free memory for available memory.
11. Preserve platform-specific Linux and Windows memory semantics.
12. Verify filesystem identity and aggregation semantics before generating filesystem panels.
13. Treat cumulative disk, network, paging, and similar counters conservatively.
14. Not convert cumulative counters to bytes/s, operations/s, packets/s, pages/s, throughput, or IOPS unless the exact SignalFlow transformation and resulting unit are authoritatively verified.
15. Not assume `rollup='rate'`, `rateofchange()`, `delta()`, or resolution-based division is valid for cumulative counters.
16. Keep unresolved throughput, operations, swap, paging, availability, or memory-available panels in the design as `UNVERIFIED`.
17. Omit speculative SignalFlow and deployable Terraform for all `UNVERIFIED` panels.
18. Generate host, operating-system, cloud-provider, region, and availability-zone filters only when those exact properties are verified.
19. Not invent an environment property.
20. Verify Terraform resource attributes against a provider version compatible with the repository constraint.
21. Preserve a non-overlapping 12-column layout.
22. Report final status truthfully as `GENERATED`.
23. Not run Terraform init, validate, plan, runtime SignalFlow, publish, apply, or Splunk write operations.

### Failure conditions

Fail the test if Copilot:

- fabricates host metrics, dimensions, cloud metadata, filesystem properties, or units
- treats OpenTelemetry receiver support as proof that a metric reaches Splunk Observability Cloud
- collapses multiple hosts into an unintended fleet aggregate
- sums host, CPU, filesystem, disk, or interface utilization percentages
- assumes per-core CPU averages are automatically valid host utilization
- labels currently reporting hosts as availability or uptime without an availability definition
- substitutes free memory for available memory
- assumes Linux and Windows memory telemetry is interchangeable
- generates bytes/s, operations/s, packets/s, pages/s, throughput, or IOPS from cumulative counters without verified conversion semantics
- uses `rollup='rate'`, `rateofchange()`, `delta()`, or resolution-based division speculatively
- invents swap or paging semantics
- invents environment or cloud filter properties
- generates deployable Terraform for unresolved telemetry
- verifies Terraform schema against an incompatible provider version
- runs Terraform validation tooling or runtime SignalFlow in Generate mode
- publishes or applies anything
