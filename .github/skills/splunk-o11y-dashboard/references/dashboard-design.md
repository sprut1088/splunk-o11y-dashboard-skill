# Splunk Observability Cloud Dashboard Design

## Table of Contents

- [Design principle](#design-principle)
- [Dashboard hierarchy](#dashboard-hierarchy)
- [Audience](#audience)
- [Chart selection](#chart-selection)
- [APM service dashboard pattern](#apm-service-dashboard-pattern)
- [Dashboard variables](#dashboard-variables)
- [Filters](#filters)
- [Cardinality](#cardinality)
- [Layout](#layout)
- [Terraform layout](#terraform-layout)
- [New and classic dashboard experiences](#new-and-classic-dashboard-experiences)
- [Panel naming](#panel-naming)
- [Dashboard quality check](#dashboard-quality-check)


Use this reference when deciding dashboard structure, chart selection, layout, variables, filters, and information hierarchy.

## Design principle

Design every dashboard around questions the user needs to answer.

Do not start by selecting metrics or chart types.

For each proposed panel, identify:

1. What operational or business question does this panel answer?
2. Which verified telemetry answers that question?
3. Which visualization communicates the answer most effectively?
4. What dimensions or filters are needed?
5. Is this panel materially different from other panels?

Remove panels that do not answer a useful question.

## Dashboard hierarchy

Prefer this information hierarchy for operational dashboards:

1. Health and headline status
2. Traffic and workload
3. Errors and failures
4. Latency and performance
5. Saturation or resource pressure
6. Dependencies and contributing components
7. Diagnostic breakdowns

Do not force every dashboard to contain every category.

Adapt the hierarchy to the telemetry domain and intended audience.

## Audience

Determine the intended audience before designing the dashboard.

### Executive or leadership

Prioritize:

- service health
- availability
- customer impact
- transaction volume
- error or failure rate
- major trends
- SLO or SLA status when available

Avoid excessive low-level infrastructure detail unless it directly explains business impact.

### SRE or operations

Prioritize:

- service health
- request or transaction rate
- error rate
- latency percentiles
- saturation
- dependencies
- resource pressure
- abnormal trends
- drill-down dimensions

### Engineering

Prioritize:

- endpoints or operations
- dependency behavior
- latency distributions
- errors
- runtime metrics
- resource utilization
- deployment or version dimensions
- diagnostic breakdowns

## Chart selection

Choose chart types based on the question being answered.

### Line or time chart

Use when the primary question is:

- How is this changing over time?
- When did degradation begin?
- Is there a trend, spike, or periodic pattern?

Typical examples:

- request rate
- error rate
- latency
- CPU utilization
- memory utilization
- active sessions

Do not replace a useful time trend with a single-value visualization merely to save space.

### Single value

Use for a headline value that can be represented by one meaningful time series.

Typical examples:

- current availability
- current error rate
- total requests over a defined period
- active hosts
- current p95 latency

Do not use a single-value chart when multiple metric time series can reach the visualization without first reducing them intentionally to one meaningful result.

### Table

Use when comparison across dimensions is more important than time-series shape.

Typical examples:

- endpoints by request count, error rate, and latency
- hosts by CPU and memory
- services by health indicators
- namespaces by resource usage

Prefer a table over many small charts when users need to compare the same measures across many entities.

### List

Use when users need a ranked or current list of entities and values.

Typical examples:

- top services by error rate
- top endpoints by latency
- top hosts by CPU

Use meaningful plot labels rather than exposing raw metric names where possible.

### Heatmap

Use when users need to identify outliers or distribution across many entities quickly.

Typical examples:

- node CPU utilization
- pod resource pressure
- host health

Do not use a heatmap for a small number of series that are clearer in a line chart or table.

### Pie or donut

Use only when the question is genuinely part-to-whole.

Typical examples:

- traffic distribution by region
- requests by response category
- workload distribution by environment

Avoid pie or donut charts for high-cardinality dimensions or time trends.

### Histogram or distribution-oriented visualization

Use when the distribution itself is operationally important.

Typical examples:

- request duration distribution
- payload size distribution

Do not treat a histogram as a substitute for p50, p95, or p99 latency when percentile trends are the operational question.

### Service map

Use when the question concerns APM service relationships or dependencies.

Do not substitute a service map for dependency latency, error, or request-rate charts when users need quantitative analysis.

### Event feed

Use when operational events, deployments, incidents, or other events provide useful context for metric changes.

### Text

Use sparingly for:

- section purpose
- operational instructions
- links or runbook context
- important interpretation guidance

Do not fill dashboards with explanatory text that could be expressed through clear titles and descriptions.

## APM service dashboard pattern

For a standard service-level APM dashboard, consider this baseline structure when verified telemetry exists.

### Row 1 - Service health

Use compact headline charts for:

- request rate
- error rate
- p95 latency
- p99 latency

Add availability or SLO status when valid data exists.

### Row 2 - Traffic and latency trends

Use time charts for:

- request or transaction rate
- latency percentiles

Prefer showing p50, p95, and p99 together only when the chart remains readable.

### Row 3 - Errors

Use:

- error-rate trend
- error count where useful
- top failing endpoints or operations

### Row 4 - Operations and endpoints

Use a table or ranked list for dimensions such as:

- endpoint
- operation
- route
- transaction

Include relevant measures such as:

- request count
- error rate
- latency

Use only verified dimension keys.

### Row 5 - Dependencies

When APM dependency telemetry exists, show:

- downstream request rate
- downstream error rate
- downstream latency
- service relationships

### Row 6 - Runtime or infrastructure context

Add runtime, Kubernetes, host, or cloud telemetry only when it helps explain application behavior.

Do not turn an APM service dashboard into a complete infrastructure dashboard.

## Dashboard variables

Prefer dashboard variables when the same property should filter multiple charts.

Common candidates can include:

- environment
- service
- namespace
- cluster
- region
- host

However, use only exact property names verified through telemetry discovery.

Do not assume that properties such as `service.name`, `deployment.environment`, or `k8s.namespace.name` exist merely because they are common conventions.

Use aliases that are understandable to dashboard users.

## Filters

Use dashboard-level filtering for scope shared across most or all panels.

Use chart-specific filtering only when:

- the chart intentionally represents a narrower subset
- the metric requires different scope
- applying the dashboard filter would produce incorrect results

Avoid repeating the same hard-coded filter separately across every chart when a dashboard variable or dashboard-level filter is appropriate.

## Cardinality

Consider dimension cardinality before grouping.

Avoid generating charts that produce hundreds or thousands of visible time series.

For high-cardinality dimensions:

1. aggregate first when appropriate
2. use Top N when supported and meaningful
3. use tables or lists for ranked entities
4. add filters to narrow scope
5. avoid rendering every entity simultaneously

Never reduce cardinality in a way that changes the intended meaning without explaining it.

## Layout

Design for scanning from top-left to bottom-right.

Place the most important health indicators near the top.

Group related charts together.

Avoid:

- isolated panels with no relationship to nearby panels
- excessively narrow time charts
- very large single-value panels
- inconsistent sizing for equivalent KPIs
- large empty gaps
- repeating the same information in multiple visualization types without a clear reason

## Terraform layout

When generating dashboards using the Terraform `signalfx_dashboard` resource:

- Treat the dashboard as a 12-column grid.
- Ensure chart widths fit within the 12-column row.
- Use explicit row and column positioning when deterministic placement is important.
- Use grid or column helpers only when appropriate for the requested Terraform design.
- Remember that Terraform-specific layout helpers might not correspond directly to native API-side layout constructs.

A common starting layout is:

- four headline KPIs: width 3 each
- two major time charts: width 6 each
- detailed tables or diagnostic charts: width 6 or 12 depending on content

This is a starting pattern, not a mandatory layout.

## New and classic dashboard experiences

Prefer the new Splunk Observability Cloud dashboard experience when the requested capability and chosen automation path support it.

Use classic-compatible patterns when required by:

- available Terraform resources
- API capability
- unsupported new-dashboard functionality
- explicit user request

Never claim a feature is supported by the new or classic experience without verification.

State the selected dashboard experience in the generated plan.

## Panel naming

Use titles that describe the operational meaning of the panel.

Prefer:

- Request Rate
- Error Rate
- P95 Request Latency
- Top Failing Endpoints
- Downstream Service Latency

Avoid titles that merely repeat raw metric names.

Include units where ambiguity is possible.

## Dashboard quality check

Before generating code, confirm:

- Every panel answers a useful question.
- Every metric is verified according to telemetry-discovery rules.
- Every dimension is verified.
- Chart types match the question being asked.
- Shared filters are implemented consistently.
- High-cardinality visualizations are controlled.
- The most important information appears first.
- Panels do not unnecessarily duplicate each other.
- The dashboard remains usable at a normal screen resolution.
