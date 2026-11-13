---
name: splunk-o11y-dashboard
description: Create, validate, and optionally publish Splunk Observability Cloud dashboards from natural-language requirements or structured YAML/JSON specifications. Use for Splunk Observability Cloud dashboard-as-code tasks involving Terraform, REST API payloads, SignalFlow, chart selection, dashboard variables, filters, layout, APM, infrastructure, Kubernetes, cloud, RUM, SRE, executive, or service-level dashboards. Prefer the new dashboard experience where supported, fall back to classic-compatible patterns when required, verify telemetry and provider schemas before use, and never invent unsupported metrics, dimensions, SignalFlow, dashboard attributes, or operational semantics.
---

# Splunk Observability Cloud Dashboard Workflow

Follow this workflow in order.

1. Understand the dashboard request.
   - Accept either natural-language requirements or structured YAML/JSON.
   - Identify the dashboard purpose, intended audience, telemetry domain, desired output format, target Splunk realm if relevant, requested filters, and required services or resources.
   - Ask only for information that is genuinely required to produce a correct dashboard.
   - Preserve requested panels even when their implementation cannot yet be verified.

2. Determine the generation mode.
   - Default to Terraform unless the user explicitly requests REST API.
   - Support three modes:
     - Generate: create dashboard code only.
     - Validate: create and validate dashboard code.
     - Publish: create, validate, show planned changes, and publish only after explicit user confirmation.
   - Never treat Generate mode as permission to publish, apply, or modify Splunk resources.
  - Treat Generate, Validate, and Publish as strictly separate execution modes.
  - In Generate mode:
    - generate the requested dashboard artifacts only
    - perform reasoning-time checks against references and documentation
    - web or documentation lookup is allowed when needed to verify telemetry, SignalFlow, or provider schema
    - do not install or download Terraform or other validation tooling
    - do not run `terraform init`
    - do not run `terraform validate`
    - do not run `terraform plan`
    - do not execute SignalFlow against the target Splunk environment
    - read-only Splunk metadata or telemetry discovery is allowed when an existing authenticated connection is already available and the lookup does not modify resources
    - do not use Splunk APIs to create, update, delete, publish, or otherwise modify resources
    - do not execute generated SignalFlow against the target environment as runtime validation
    - do not change the target environment
  - Run Terraform tooling or runtime validation only when the user explicitly requests Validate or Publish mode.
  - Static reasoning, documentation verification, and read-only telemetry discovery do not change the mode from `GENERATED`.

3. Determine the dashboard experience.
   - Prefer the Splunk Observability Cloud new dashboard experience where supported.
   - Fall back to classic-compatible dashboard patterns when the requested feature or supported code path requires it.
   - State which dashboard experience is being targeted.
   - Do not claim that Terraform or REST supports a new-experience capability unless that support has been verified.

4. Discover and validate telemetry before generating charts.
   - Prefer read-only live Splunk Observability Cloud metadata when an existing authenticated connection is available.
   - Use live discovery only to establish telemetry availability, dimensions, properties, metric types, or metadata; do not treat it as permission to run generated SignalFlow or modify Splunk resources.
   - Otherwise use user-provided metric and dimension inventories.
   - Otherwise use officially documented Splunk telemetry.
   - Use OpenTelemetry semantic conventions only when appropriate for the requested telemetry model.
   - Never invent metric names, histogram names, dimensions, properties, values, aggregations, or unsupported SignalFlow.
   - Clearly flag telemetry that cannot be verified.

## Mandatory generation gates

Treat the following rules as non-negotiable before generating Terraform, REST payloads, or SignalFlow.

1. Read the relevant reference instructions before generating code.
   - Do not rely only on an initial preview of a reference file.
   - Read the sections required to verify:
     - telemetry
     - dimensions
     - SignalFlow operations
     - units
     - provider resources
     - provider attributes
     - layout
     - variables
     - filters
   - For Splunk APM requests, read the relevant APM sections of both `references/telemetry-discovery.md` and `references/signalflow.md` before selecting telemetry.
   - For Kubernetes, AKS, EKS, GKE, OpenShift, pod, container, node, namespace, or workload dashboards, read `references/kubernetes.md` before selecting metrics, dimensions, aggregations, or generating SignalFlow.
   - For Kubernetes telemetry, distinguish metrics supported by an OpenTelemetry receiver from metrics actually exported to Splunk Observability Cloud. Receiver documentation alone is not proof that a metric is available in the target Splunk environment.
   - For Azure infrastructure, Azure Monitor, Application Gateway, Azure Firewall, ExpressRoute, Load Balancer, virtual machine, subscription, resource-group, region, or Azure resource dashboards, read `references/azure.md` before selecting metrics, dimensions, variables, aggregations, or generating SignalFlow.
   - For RUM, Real User Monitoring, Digital Experience, mobile application, web frontend, session, crash, app-start, screen, route, browser, device, or frontend performance dashboards, read `references/rum.md` before selecting metrics, dimensions, variables, aggregations, percentile logic, or generating SignalFlow.

2. Prefer Splunk APM-native telemetry for Splunk APM dashboards.
   - Consider documented Monitoring MetricSets such as:
     - `service.request`
     - `spans`
     - `traces`
     - `inferred.services`
   - Do not select a generic OpenTelemetry metric merely because its name appears suitable.
   - Do not assume a Monitoring MetricSet exists in the target organization merely because Splunk documents it.

3. Do not generate telemetry expressions unless their semantics are verified.
   - `count()` must not be interpreted as request count unless the selected telemetry representation establishes that meaning.
   - Request count and request rate are different measures.
   - Do not label a count as requests/second unless the rate semantics have been verified.
   - Do not calculate request-level latency percentiles from arbitrary metric streams.
   - Do not use `mean()`, `sum()`, `rate()`, `delta()`, or another transformation merely because it creates the desired visualization.

4. Never invent dimension values.
   - A documented dimension name does not prove values such as `prod`, `staging`, or `dev` exist.
   - If values are unknown, leave the dashboard variable unrestricted or mark its values unresolved.
   - Never fabricate service names, environments, regions, endpoints, namespaces, hosts, or other dimension values.

5. Preserve telemetry units.
   - Verify the source unit.
   - Verify whether SignalFlow changes the unit.
   - Apply an explicit conversion when necessary.
   - Do not relabel seconds, nanoseconds, bytes, or another source unit as a different unit without conversion.
   - A Terraform visualization unit setting is not evidence that the underlying data was converted.

6. Generate only verified Terraform resources and attributes.
   - Verify chart resource type.
   - Verify supported `plot_type`.
   - Verify dashboard attributes.
   - Verify dashboard variable attributes.
   - Verify nested blocks.
   - Verify unit attributes.
   - Verify resource references.
   - Do not invent convenience attributes.
   - Do not arbitrarily pin a provider version.
   - Preserve an existing repository provider-version strategy when one exists.
   - If no provider version strategy exists, omit the version constraint unless a specific version has been verified for the task.

7. Do not claim validation that did not occur.
   - Editor diagnostics are not Terraform validation.
   - Generated HCL is not automatically statically validated.
   - If `terraform validate` did not run successfully, do not claim Terraform validation.
   - Documentation-backed telemetry is `VERIFIED_DOCS`, not `VERIFIED_LIVE`.
   - Do not claim SignalFlow is runtime-valid unless it was validated against the target Splunk Observability Cloud environment.

8. Do not fabricate deployable implementations for unresolved panels.
   - Keep the requested panel in the dashboard design.
   - Mark the implementation `UNVERIFIED`.
   - State exactly what telemetry, dimension, SLO, threshold, unit, API capability, or provider-schema evidence is missing.
   - Do not silently substitute another metric, dimension, aggregation, formula, or visualization.

## Explicit forbidden generation patterns

Do not generate any of the following unless the exact syntax and semantics have been independently verified for the selected telemetry and provider version:

```python
histogram('spans').rate()
histogram('spans').sum().rate()
histogram('spans').sum(by=[...]).rate()
```

For Splunk APM service traffic and latency, prefer the documented `service.request` Monitoring MetricSet when it represents the requested service-level signal.

Documented structural examples include:

```python
histogram('service.request', filter=filter_).count()
histogram('service.request', filter=filter_).percentile(pct=95)
```

Treat these as documentation-backed patterns, not proof that the telemetry exists in the target environment.

Do not interpret:

```python
histogram('service.request').count()
```

as requests per second unless the rate semantics have been independently verified.

Do not generate arbitrary service-health formulas or thresholds such as:

```text
error rate < 1%
p95 latency < 500ms
health score = weighted error and latency formula
```

unless those thresholds or the health definition were supplied by the user or verified from an authoritative source.

If the user requests service health but no health definition, SLO, thresholds, availability formula, or detector state is available:

- keep Service Health in the dashboard design
- mark its implementation `UNVERIFIED`
- state what definition or SLO is required
- do not invent a composite health score

Do not mark a dimension as `VERIFIED_DOCS` unless that exact dimension is documented for the selected telemetry source.

Do not infer an endpoint dimension merely because endpoint information exists somewhere in APM.

Do not generate:

```hcl
unit_prefix = "m"
```

to represent milliseconds.

For SignalFx Terraform chart resources, `unit_prefix` is not a general time-unit selector.

Use only provider-supported unit configuration and only when:

1. the underlying telemetry unit is known
2. any required conversion is explicit
3. the selected chart resource supports the generated unit attribute

Do not assign a default Splunk realm such as:

```hcl
default = "us0"
```

when the target realm is unknown.

Keep the realm required, derive it from verified configuration, or mark it unresolved.

Do not generate a dashboard URL from an assumed realm or legacy hostname.

Prefer a provider-exported dashboard URL attribute when available.

Before declaring generated Terraform structurally correct, verify every generated:

- resource type
- resource attribute
- nested block attribute
- `plot_type`
- dashboard variable attribute
- unit attribute
- resource reference

against the applicable `splunk-terraform/signalfx` provider schema.

## Splunk APM panel-to-telemetry routing

For Splunk APM dashboards, select telemetry according to the operational question instead of using one Monitoring MetricSet for every panel.

Use these routing rules unless live telemetry proves a better source.

### Service-level request, error, and latency

For service-level RED signals, prefer:

```text
service.request
```

Documented default histogram Monitoring MetricSet dimensions can include:

- `sf_environment`
- `deployment.environment`
- `sf_service`
- `service.name`
- `sf_error`

Do not assume `sf_operation`, `sf_kind`, endpoint, peer-service, HTTP route, or other dimensions exist on the default `service.request` Monitoring MetricSet.

Use documented histogram operations such as:

```python
histogram('service.request').count()
histogram('service.request').percentile(pct=95)
```

Treat `count()` as request count unless a requests-per-second calculation has been independently verified.

Do not label `count()` as `Requests/sec` merely because it is shown on a time chart.

For error percentage:

- verify the error dimension
- verify its actual values
- verify numerator and denominator use the same scope
- verify the percentage arithmetic
- consider missing or zero-denominator behavior

### Endpoint and operation breakdowns

Do not use `service.request` with `sf_operation` unless:

- a custom Monitoring MetricSet providing that dimension has been verified, or
- live metadata confirms the dimension exists on the selected Monitoring MetricSet.

For default endpoint or operation analysis, consider the documented:

```text
spans
```

Monitoring MetricSet.

The `spans` Monitoring MetricSet can expose dimensions such as:

- `sf_operation`
- `sf_kind`
- `sf_error`
- `sf_httpMethod`
- `service.name`
- `deployment.environment`

Verify the exact dimensions required by the requested panel.

Use grouping semantics explicitly.

Do not use:

```python
filter('sf_operation')
```

as a substitute for grouping.

Filtering selects dimension values.

Grouping creates one output stream per dimension value.

Verify the supported histogram grouping syntax before generating grouped endpoint code.

If grouping syntax cannot be verified, keep the Top Endpoints panel in the design and mark its implementation `UNVERIFIED`.

### Dependency latency

Treat dependency latency as a separate APM capability.

Do not assume that:

```python
histogram('spans', filter=filter('span.kind', 'SPAN_KIND_CLIENT'))
```

is a valid dependency-latency implementation.

For Splunk Monitoring MetricSets, prefer documented Splunk dimensions such as `sf_kind` rather than raw span properties such as `span.kind`, unless live telemetry explicitly supports the raw property.

Do not assume CLIENT spans are represented by the default Monitoring MetricSet.

Do not invent a peer-service dimension.

If dependency telemetry cannot be established from:

1. live Splunk APM dependency metadata
2. a verified Monitoring MetricSet or Troubleshooting MetricSet
3. a documented dependency/service-map data source
4. an explicitly supplied working SignalFlow program

keep Dependency Latency in the dashboard design and mark its implementation `UNVERIFIED`.

### Service health

Do not derive a synthetic health score.

If the user requests service health, prefer one of:

1. a verified existing SLO or SLI
2. verified availability semantics
3. verified success-rate semantics
4. detector or alert state when explicitly requested and supported
5. a collection of RED health indicators without combining them into an invented score

Do not assume:

```text
availability = 100 - error rate
```

unless the organization's availability semantics establish that relationship.

If no verified health definition is available, mark Service Health `UNVERIFIED`.

### Dashboard variables

For service and environment dashboard variables:

- verify the property name
- do not invent values
- do not invent defaults
- use unrestricted variables when supported and appropriate
- use fixed filters only when the requested scope is explicitly fixed

For a dashboard specifically requested for service `payments`, it is acceptable to use a verified `service.name` property with the supplied value `payments`.

Do not infer the environment value.

### Terraform chart-specific schema

Treat each Terraform chart resource schema independently.

Do not assume attributes supported by one chart resource are supported by another.

For example:

- verify `signalfx_time_chart` attributes independently
- verify `signalfx_single_value_chart` attributes independently
- verify `signalfx_table_chart` attributes independently
- do not generate `viz_options` for a resource unless that resource schema supports it
- do not generate a table-chart setting merely because the same attribute exists on a time chart

For dashboard URLs, prefer the provider-exported dashboard attribute:

```hcl
signalfx_dashboard.<resource>.url
```

when the selected provider schema supports it.

Do not construct a dashboard URL using an unrelated resource, guessed hostname, guessed realm, or fabricated data source.

5. Design the dashboard before generating code.
   - Select charts based on the operational question being answered, not merely on visualization availability.
   - Define shared dashboard variables and filters before chart-level filters where appropriate.
   - Group related panels logically.
   - Avoid duplicate charts that answer the same operational question.
   - Prefer useful operational signals over decorative visualizations.
   - Preserve requested but unresolved panels in the design and clearly mark them `UNVERIFIED`.
   - Use the Splunk APM panel-to-telemetry routing rules above for APM dashboards.

### Final pre-generation consistency gate

Immediately before creating Terraform, REST payloads, or SignalFlow, perform this check for every requested panel.

For each panel determine:

1. the exact operational question
2. the exact telemetry source
3. the exact SignalFlow operation
4. required dimensions and values
5. source and output units
6. Terraform resource type
7. implementation status: `VERIFIED_DOCS`, `VERIFIED_LIVE`, `VERIFIED_INVENTORY`, or `UNVERIFIED`

Apply these rules before writing code:

- If the requested semantic and implemented semantic differ, do not generate the chart.
- Request count must not be generated under a chart named `Request Rate`.
- Error rate must not be renamed or substituted as `Service Health`.
- An `UNVERIFIED` panel must not have a deployable Terraform chart resource.
- Do not include speculative SignalFlow for an `UNVERIFIED` panel, including commented placeholder programs.
- Do not mark a SignalFlow method chain `VERIFIED_DOCS` unless that exact required operation or composition is supported by documentation.
- Provider `group_by` support does not prove that a SignalFlow expression such as `count(by=[...])` is supported.
- Do not generate both a fixed dashboard filter and an interactive variable for the same property unless their combined behavior is explicitly required and non-conflicting.
- A fixed `service.name = payments` filter prevents a service variable from switching the dashboard to another service.
- Verify every dashboard-level Terraform attribute against the provider schema; omit attributes that cannot be verified.
- Before finalizing layout, calculate each chart's occupied rows and columns and ensure no chart regions overlap.
- Do not describe the Terraform as production-ready or ready to apply while any generated resource depends on unresolved semantics.

If any requested panel fails this gate:

1. preserve it in the dashboard design
2. mark it `UNVERIFIED`
3. state the blocking requirement
4. omit its deployable code

Correct partial Terraform is preferable to complete but speculative Terraform.

6. Generate the requested code.
   - Produce complete Terraform for all verified panels by default.
   - Produce REST API payloads when explicitly requested.
   - Generate SignalFlow only when the selected syntax and semantics are sufficiently verified.
   - Keep generated resources readable, reusable, and suitable for version control.
   - Omit deployable resources for panels that remain `UNVERIFIED`.
   - Do not include speculative placeholder SignalFlow for unresolved panels.
   - Do not create additional documentation files unless they materially help the requested task.
   - Do not generate publish/apply commands as though the requested action has already been approved.


7. Validate the result.
   - Check every referenced metric or histogram.
   - Check every dimension and filter property.
   - Check dimension values where values are explicitly generated.
   - Check chart type compatibility.
   - Check SignalFlow structure and semantics.
   - Check request-count versus request-rate semantics.
   - Check percentile semantics.
   - Check arithmetic and ratio semantics.
   - Check source telemetry units.
   - Check explicit unit conversions.
   - Check chart display units.
   - Check dashboard variables.
   - Check fixed filters.
   - Check layout and resource references.
   - Check Terraform or REST payload consistency.
   - Check every Terraform resource attribute against the selected provider schema.
   - Report assumptions and unresolved gaps.
   - Assign only the validation status actually achieved.

8. Publish only when explicitly requested.
   - Never publish or apply merely because credentials or connectivity are available.
   - Show the planned dashboard creation or update before any write.
   - Identify create, update, replace, or delete operations.
   - Require explicit user confirmation before creating, modifying, replacing, or deleting dashboards in Splunk Observability Cloud.

## References

Use [references/telemetry-discovery.md](references/telemetry-discovery.md) whenever discovering, selecting, validating, or substituting metrics, histograms, dimensions, properties, filters, services, hosts, Kubernetes resources, cloud resources, or other telemetry.
Use [references/kubernetes.md](references/kubernetes.md) whenever generating or reviewing Kubernetes, AKS, EKS, GKE, OpenShift, pod, container, node, namespace, workload, replica, resource-utilization, restart, or CPU-throttling dashboard panels. Use it to distinguish receiver-supported telemetry from metrics actually exported to Splunk Observability Cloud and to verify Kubernetes-specific metric, dimension, aggregation, workload, and utilization semantics.
Use [references/azure.md](references/azure.md) whenever generating or reviewing Azure infrastructure dashboards. Use it to preserve exact Azure filter semantics, distinguish generic from service-specific dimensions, verify aggregation behavior, and avoid substituting resource IDs for requested resource names.
Use [references/dashboard-design.md](references/dashboard-design.md) whenever designing dashboard structure, choosing charts, organizing rows, selecting dashboard variables, or validating the 12-column layout.
Use [references/signalflow.md](references/signalflow.md) whenever generating or reviewing SignalFlow, including Splunk APM Monitoring MetricSets, histogram operations, grouping, count-versus-rate semantics, custom Monitoring MetricSet filtering, transformations, and units.
Use [references/terraform.md](references/terraform.md) whenever generating or reviewing Terraform resources, provider schema, chart resources, dashboard variables, layout blocks, units, provider-version strategy, resource references, or dashboard URLs.
Use [references/rest-api.md](references/rest-api.md) whenever REST API output, read-only API discovery, or publish/update operations are requested.
Use [references/input-spec.md](references/input-spec.md) whenever interpreting structured YAML/JSON input or mapping natural-language requirements into a dashboard specification.
Use [references/output-contract.md](references/output-contract.md) whenever formatting the final response, reporting preflight findings, telemetry status, validation status, unresolved panels, or publish/apply status.
Use [references/acceptance-tests.md](references/acceptance-tests.md) when regression-testing or evaluating this skill against the maintained acceptance scenarios.
Use [references/rum.md](references/rum.md) whenever generating or reviewing RUM, Real User Monitoring, Digital Experience, mobile, web frontend, session, crash, app-start, screen, route, browser, device, or frontend-performance dashboards. Use it to verify RUM metric type and aggregation semantics, preserve platform-specific definitions, validate application scoping and filters, and prevent unsafe percentile or cross-series aggregation.