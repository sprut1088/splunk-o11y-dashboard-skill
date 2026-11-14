# Telemetry Discovery and Validation

Use this reference whenever selecting metrics, dimensions, properties, services, environments, hosts, Kubernetes resources, cloud resources, or other telemetry for a dashboard.

## Source priority

Resolve telemetry in this order:

1. Live Splunk Observability Cloud metadata from the target environment.
2. User-provided metric and dimension inventories.
3. Official Splunk documentation.
4. Official OpenTelemetry semantic conventions or instrumentation documentation.
5. Mark the telemetry as unverified if none of the above can confirm it.

Do not invent telemetry.

## Validation status

Assign one of these statuses to every metric or dimension used during dashboard planning when validation is possible:

- VERIFIED_LIVE: Confirmed in the target Splunk Observability Cloud environment.
- VERIFIED_INVENTORY: Confirmed in a user-supplied metric or dimension inventory.
- VERIFIED_DOCS: Confirmed by official Splunk or OpenTelemetry documentation but not confirmed in the target environment.
- UNVERIFIED: Could not be confirmed.

Prefer VERIFIED_LIVE over all other statuses.

## Metric rules

Before generating a chart:

1. Confirm that the metric exists.
2. Determine what the metric represents.
3. Determine whether it is a gauge, counter, cumulative counter, histogram, distribution, or another supported metric type when that information is available.
4. Choose aggregations appropriate to the metric semantics.
5. Confirm required dimensions and filters.
6. Avoid applying percentiles, rates, sums, averages, or rollups without evidence that they are meaningful for that metric.
7. Do not substitute a similarly named metric without telling the user.

If the requested metric does not exist but an appropriate verified alternative exists, explain the substitution before using it.

## Dimension and property rules

Before using a dimension, property, or dashboard variable:

1. Confirm the exact key.
2. Preserve case and punctuation exactly.
3. Confirm that the property is associated with the metric or telemetry being charted when possible.
4. Do not assume common keys such as service.name, environment, host.name, k8s.namespace.name, cloud.region, or deployment.environment exist in every environment.
5. Prefer shared dashboard variables when the same property should filter multiple charts.

## Live discovery rules

When live Splunk Observability Cloud access is available:

1. Use read-only discovery first.
2. Discover only the telemetry relevant to the requested dashboard.
3. Do not modify dashboards or other Splunk resources during discovery.
4. Do not expose access tokens or credentials in output, logs, generated files, examples, or source control.
5. Record which requested telemetry was found and which was not found.
6. Do not treat successful authentication as proof that a metric exists.

## Inventory rules

When metric or dimension inventories are supplied:

1. Treat them as authoritative for that task unless the user states otherwise.
2. Match exact names before using fuzzy matching.
3. Use fuzzy or semantic matching only to identify candidates.
4. Clearly distinguish an exact match from a suggested alternative.
5. Do not add undocumented metrics to the inventory.

## Documentation fallback

When live discovery and inventories are unavailable:

1. Use only official Splunk or OpenTelemetry documentation as authoritative references.
2. Treat documented metrics as potentially available, not guaranteed to be present in the user's environment.
3. Mark them VERIFIED_DOCS rather than VERIFIED_LIVE.
4. Tell the user that runtime availability still needs validation.

## Failure behavior

If required telemetry cannot be verified:

- Do not silently generate a chart using an invented metric.
- Identify the missing telemetry.
- Explain which source was checked.
- Suggest a verified alternative when one exists.
- If no suitable alternative exists, leave the chart unresolved rather than fabricate it.

## Preflight summary

Before generating a substantial dashboard, provide or internally establish a preflight result equivalent to:

- Target environment: known or not connected
- Requested telemetry: count
- VERIFIED_LIVE: count
- VERIFIED_INVENTORY: count
- VERIFIED_DOCS: count
- UNVERIFIED: count
- Blocking gaps: list

Do not claim a dashboard is fully validated while required telemetry remains UNVERIFIED.


## Splunk APM telemetry preference

When the requested dashboard is for Splunk APM, service performance, endpoints, dependencies, traces, spans, or application latency, prefer Splunk APM-native telemetry before generic OpenTelemetry metric conventions.

Use this priority for APM dashboards:

1. Live Splunk APM telemetry and metadata from the target environment.
2. User-provided Splunk APM metric or dimension inventory.
3. Current Splunk APM Monitoring MetricSet documentation.
4. Current Splunk APM indexed span dimensions and properties.
5. Generic OpenTelemetry metric semantic conventions only when the dashboard is intentionally based on raw OpenTelemetry metrics and their presence in Splunk Observability Cloud is verified or explicitly left unresolved.

Do not select a generic OpenTelemetry metric merely because its name is documented by OpenTelemetry when Splunk APM provides a more appropriate native telemetry model for the requested dashboard.

### Splunk APM Monitoring MetricSets

For APM dashboards, consider current documented histogram Monitoring MetricSets such as:

- `service.request`
- `spans`
- `inferred.services`
- `traces`

Do not assume every Monitoring MetricSet exists or contains every requested custom dimension in the target organization.

Verify the current Splunk documentation and target environment when possible.

### APM dimensions

Prefer dimensions documented for the selected Splunk APM Monitoring MetricSet.

Current Splunk APM histogram Monitoring MetricSets can expose dimensions such as:

- `service.name`
- `deployment.environment`
- `sf_service`
- `sf_environment`
- `sf_error`
- `sf_operation`
- `sf_kind`
- `sf_httpMethod`

Availability varies by Monitoring MetricSet.

Treat the names above as candidates, not defaults. For the selected Splunk APM Monitoring MetricSet, verify the exact service and environment property before generating a filter or dashboard variable.

`service.name` and `sf_service` are not interchangeable by assumption. `deployment.environment`, `sf_environment`, and any other environment property are not interchangeable by assumption.

If the exact APM service or environment property cannot be tied to the selected Monitoring MetricSet through live telemetry, supplied inventory, or authoritative documentation for that metricset, mark that filter or variable `UNVERIFIED` and omit it from deployable Terraform.

Do not automatically replace a requested property such as `environment` with a generic OpenTelemetry property such as `deployment.environment.name`.

Resolve the property using the target Splunk APM telemetry model.

If the target property cannot be verified, mark it `UNVERIFIED` instead of silently substituting another property.

### Raw OpenTelemetry metrics

Metrics documented by OpenTelemetry, including semantic-convention metrics, establish that the metric name is defined by OpenTelemetry.

They do not establish that:

- the target application emits the metric
- the target collector exports the metric
- Splunk Observability Cloud receives the metric
- the required dimensions are present on the resulting MTS
- the metric is suitable in preference to Splunk APM Monitoring MetricSets

Treat documentation-only OpenTelemetry telemetry as `VERIFIED_DOCS`, not `VERIFIED_LIVE`.

Do not present documentation-only telemetry as confirmed available in the user's Splunk environment.