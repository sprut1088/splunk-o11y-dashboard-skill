# SignalFlow Generation Rules

## Contents

- [Core rule](#core-rule)
- [Basic program structure](#basic-program-structure)
- [Stream naming and publish rules](#stream-naming-and-publish-rules)
- [Filter rules](#filter-rules)
- [Aggregation and metric-type rules](#aggregation-and-metric-type-rules)
- [Histogram and APM rules](#histogram-and-apm-rules)
- [Arithmetic and ratio rules](#arithmetic-and-ratio-rules)
- [Rollup rules](#rollup-rules)
- [Validation and failure behavior](#validation-and-failure-behavior)
- [Histogram safety rules](#histogram-safety-rules)
- [Unit and conversion safety](#unit-and-conversion-safety)

Use this reference whenever generating or reviewing SignalFlow for a Splunk Observability Cloud chart.

## Core rule

Do not generate SignalFlow from memory alone when the required syntax, metric type, function, rollup, filter, or aggregation is uncertain.

Prefer:

1. Verified examples from the target Splunk Observability Cloud environment.
2. Official Splunk SignalFlow documentation.
3. Patterns already proven in existing working dashboards.
4. Generated SignalFlow only when its syntax and semantics can be supported by the above.

Never invent SignalFlow functions, arguments, rollups, or methods.

## Basic program structure

A typical SignalFlow chart program should follow this sequence:

1. Select one or more metric streams.
2. Apply verified filters.
3. Apply the required aggregation or transformation.
4. Perform arithmetic or expressions only when needed.
5. Publish the stream that should appear in the chart.

Example:

```python
A = data('cpu.utilization').mean().publish(label='A')
```

## Stream naming and publish rules

When practical, assign SignalFlow streams to capital letters:

```python
A = ...
B = ...
C = ...
```

When Plot Builder compatibility is expected:

- Assign each stream to a capital letter from A through Z.
- Use no more than one `publish()` statement for each stream.
- If `publish()` is used, keep it as the final method in that stream.
- Include a label in `publish()`.
- Prefer the publish label to match the stream identifier.

Example:

```python
A = data('cpu.utilization').mean().publish(label='A')
B = data('memory.utilization').mean().publish(label='B')
C = data('disk.utilization').mean().publish(label='C')
```


Publish only streams that need to be visible in the chart.

Do not publish intermediate calculation streams unless they must appear as plots.

If advanced SignalFlow requires constructs that cannot be represented by the graphical Plot Builder, prioritize correct SignalFlow and clearly state that Plot Builder round-trip compatibility might be lost.


## Filter rules

Use filters only with verified dimensions or properties.

Example syntax:

```python
A = data(
    'cpu.utilization',
    filter=filter('host.name', 'server-01')
).mean().publish(label='A')
```

Treat the metric name, dimension name, and value in this example as placeholders only.

Before generating a filter:

1. Verify the exact dimension or property name.
2. Preserve its spelling, case, and punctuation.
3. Verify that the dimension is associated with the selected telemetry when possible.
4. Verify the requested filter value when live metadata is available.
5. Do not assume that common dimensions exist in every environment.

For example, do not automatically assume the availability of:

- `service.name`
- `host.name`
- `deployment.environment`
- `k8s.namespace.name`
- `cloud.region`

Use the telemetry discovery rules before including these properties in generated SignalFlow.

When multiple filters are required, combine only verified filter expressions.

Do not silently replace a missing dimension with a similarly named property.

## Aggregation and metric-type rules

Choose analytics based on the meaning and type of the metric.

Do not select `mean()`, `sum()`, `count()`, `percentile()`, or another function only because it produces a visually useful chart.

First determine whether the operation is intended to be:

- an aggregation across multiple metric time series at the same point in time
- a transformation of one or more time series over a time window

These operations can have different meanings.

### Gauge metrics

For gauge metrics, use averaging only when averaging is semantically meaningful.

Example pattern:

```python
A = data('metric.name').mean().publish(label='A')
```

Do not use `mean()` automatically for every gauge.

### Counter metrics

For counter metrics, determine whether values should be summed across reporting sources or otherwise processed according to the metric semantics.

Do not apply a rate merely because the metric name contains `count`.

### Cumulative counters

For cumulative counters, determine whether the user needs the change between measurements rather than the raw cumulative value.

Do not treat a cumulative counter as an ordinary gauge.

### Count

Be explicit about what `count()` represents.

For a normal SignalFlow stream, `count()` can represent the number of metric time series reporting data.

Do not assume:

```python
A = data('metric.name').count()
```

means "number of application requests."

Verify the metric representation first.

### Percentiles

Use percentile calculations only when percentile semantics are valid for the underlying telemetry.

Do not assume applying `percentile()` to an arbitrary latency metric produces true request-level p95 or p99 latency.

The source representation must be understood first.


## Histogram and APM rules

Treat histogram metrics differently from ordinary gauge, counter, or cumulative-counter metrics.

When the verified telemetry is a histogram, use the SignalFlow histogram interface rather than treating it as a normal `data()` stream.

Example request-count pattern:

```python
A = histogram('spans').count().publish(label='A')
```

Example latency-percentile pattern:

```python
A = histogram('spans').percentile(pct=95).publish(label='A')
```

Treat `spans` in these examples as a documented example, not as proof that the same histogram exists in every environment.

For Splunk APM Monitoring MetricSets:

1. Determine whether the target environment uses histogram-based Monitoring MetricSets.
2. Verify the exact histogram metric name.
3. Verify the indexed dimensions or tags needed for filtering.
4. Use histogram functions such as `count()`, `min()`, `max()`, `median()`, or `percentile()` only when appropriate for the requested measure.
5. Do not fabricate legacy precomputed metrics when the histogram representation is available.

Do not assume that names such as:

- `spans.count`
- `spans.duration.ns.p90`
- `spans.duration.ns.p99`

exist in the target environment.

Prefer the verified current histogram representation where available.

Do not apply an ordinary stream percentile to a histogram when the intended operation is a histogram percentile.

Do not calculate p95 or p99 latency from an arbitrary averaged latency metric.


## Arithmetic and ratio rules

Use arithmetic only when the participating streams have compatible meaning, scope, dimensions, and units.

Before generating a ratio or percentage:

1. Verify the numerator.
2. Verify the denominator.
3. Confirm both streams use compatible filters.
4. Confirm their grouping dimensions align.
5. Confirm their units are compatible.
6. Consider zero or missing denominator behavior.
7. Confirm whether the output should be a ratio or a percentage.

A conceptual percentage pattern is:

```python
A = ...
B = ...
C = (A / B * 100).publish(label='C')
```

Treat this as a structural example only.

Do not generate the formula until A and B are both verified.

### Error rate

Do not assume one universal error-rate formula.

A common conceptual formula is:

```text
errors / total_requests * 100
```

Generate actual SignalFlow only after verifying:

- the error signal
- the total-request signal
- matching filters
- matching grouping
- compatible aggregation
- compatible time resolution

If a verified error-rate metric already exists and matches the required semantics, prefer that metric instead of recalculating it unnecessarily.

### Availability and success rate

Do not fabricate availability or success-rate formulas.

Verify what the organization considers:

- success
- failure
- total traffic
- excluded responses
- ignored operations
- maintenance or no-traffic periods

Do not assume that `100 - error_rate` is equivalent to availability.

### Units

Preserve units through arithmetic.

When a conversion is required, make it explicit and mathematically correct.

Examples can include:

- ratio to percentage
- seconds to milliseconds
- nanoseconds to milliseconds
- bytes to MiB or GiB

Do not mix incompatible units in the same expression.


## Rollup rules

Distinguish metric rollups from SignalFlow analytics.

A rollup summarizes raw datapoints to the chart or job resolution before subsequent SignalFlow analytics are applied.

Splunk Observability Cloud uses metric-type-specific default rollups:

- Gauge: Average
- Counter: Sum
- Cumulative counter: Delta
- Histogram: Histogram

Prefer the default rollup unless there is a verified reason to override it.

Before explicitly specifying a rollup:

1. Verify the metric type.
2. Understand the metric's reporting semantics.
3. Determine why the default rollup is insufficient.
4. Verify that the requested rollup is supported.
5. Confirm that changing the rollup does not change the intended meaning of the chart.

Do not confuse a rollup with an analytics function.

For example, a Sum rollup and a subsequent `sum()` analytics operation solve different problems and can produce different results.

Be especially careful with cumulative counters.

Splunk Observability Cloud normally applies Delta rollup behavior to cumulative counters. Do not automatically add another delta calculation without verifying that it is required.

Do not explicitly set a rollup merely because a similar example used one.


## Validation and failure behavior

Validate generated SignalFlow before presenting it as ready for deployment.

Check:

1. Every metric or histogram name is verified.
2. Every dimension, property, or indexed tag is verified.
3. Every SignalFlow function and method is supported.
4. Function arguments are syntactically valid.
5. Aggregation matches the metric semantics.
6. Rollup behavior is appropriate for the metric type.
7. Grouping dimensions are valid and cardinality is reasonable.
8. Arithmetic combines compatible streams and units.
9. Published streams represent the intended chart output.
10. Plot Builder compatibility is preserved when required.

When live Splunk Observability Cloud access is available, prefer runtime validation against the target environment.

Distinguish validation levels:

- `RUNTIME_VALIDATED`: The SignalFlow was successfully validated or executed against the target Splunk Observability Cloud environment.
- `STATICALLY_VALIDATED`: Syntax and semantics were reviewed using verified telemetry and documented SignalFlow behavior, but the program was not executed against the target environment.
- `UNVERIFIED`: Required telemetry, syntax, or behavior could not be confirmed.

Do not describe SignalFlow as fully validated when it has not been executed or otherwise confirmed against the target environment.

### Failure behavior

If required telemetry or SignalFlow behavior cannot be verified:

- Do not invent a metric.
- Do not invent a dimension.
- Do not invent a SignalFlow function.
- Do not silently substitute a similar metric.
- Do not generate plausible-looking code and present it as correct.

Instead:

1. Identify what could not be verified.
2. State which validation source was checked.
3. Use a verified alternative only when it preserves the requested meaning.
4. Explain any substitution.
5. Leave the affected chart unresolved when no safe alternative exists.

Correctly refusing to generate one unsupported chart is preferable to generating a dashboard containing fabricated telemetry.

### Language separation

Do not mix SignalFlow with Splunk Search Processing Language (SPL).

SignalFlow is used for streaming analytics in Splunk Observability Cloud.

SPL is used for searching and processing events in Splunk Enterprise and Splunk Cloud Platform.

Never generate SPL syntax inside a SignalFlow program or describe SPL functions as SignalFlow functions.

## Histogram safety rules

Treat histogram SignalFlow as a restricted API.

Use only histogram functions and method chains that are explicitly verified by current Splunk documentation or by a proven working SignalFlow program from the target environment.

### Documented histogram patterns

Current Splunk APM documentation includes patterns such as:

```python
A = histogram('spans').count().publish(label='A')
```

and:

```python
A = histogram('service.request', filter=filter_).percentile(pct=95).publish(label='A')
```

Supported histogram summarization functions can include:

- `count()`
- `min()`
- `max()`
- `sum()`
- `percentile(pct=...)`
- other histogram-specific functions only when explicitly verified

Do not assume that an ordinary SignalFlow analytics method is valid directly on a histogram stream.

### Never invent histogram method chains

Do not generate constructs such as:

```python
histogram('metric.name').rate()
```

unless that exact method chain is verified as supported by the current Splunk SignalFlow documentation or by a proven working query from the target environment.

The fact that the user requests a concept such as "request rate" does not prove that a histogram exposes a `rate()` method.

Separate:

1. the telemetry primitive
2. the histogram summarization operation
3. any subsequent analytics required to derive the requested value

Verify each stage independently.

### Request count versus request rate

Do not treat request count and request rate as interchangeable.

For a histogram Monitoring MetricSet, a documented pattern such as:

```python
histogram('service.request').count()
```

establishes a request-count calculation.

It does not by itself establish the correct requests-per-second calculation for every dashboard, resolution, or telemetry source.

When the user asks for request rate:

- use a current Splunk-documented rate calculation if one is available for the selected telemetry
- otherwise use a proven working SignalFlow pattern from the target environment
- otherwise mark the rate calculation `UNVERIFIED`

Do not silently substitute request count for request rate.

Do not invent a division by chart resolution, `rate()`, `rateofchange()`, `delta()`, or another transformation without verifying that the operation is semantically correct for the selected telemetry.

### Percentiles

For Splunk histogram Monitoring MetricSets, use documented histogram percentile syntax such as:

```python
histogram('service.request', filter=filter_).percentile(pct=95)
```

only after verifying:

- the histogram exists
- the required filters exist
- the requested percentile is meaningful
- the returned unit is understood

Do not convert or relabel the returned unit unless the conversion is explicit and verified.


## Unit and conversion safety

Treat metric units as part of telemetry correctness.

Before assigning a chart unit, verify:

1. the source metric or histogram unit
2. the unit returned after any SignalFlow transformation
3. whether an explicit mathematical conversion is required
4. whether the Terraform chart unit is only a display hint or represents an actual transformed value

Do not relabel a value into another unit without converting it.

For example, if a latency metric is defined in seconds, do not generate:

```hcl
value_unit = "Millisecond"
```

unless the SignalFlow expression explicitly converts the value to milliseconds or the selected telemetry source is already documented as milliseconds.

A chart display-unit setting is not evidence that the underlying SignalFlow values were converted.

### Unit conversion

When a conversion is required:

- verify the source unit first
- apply an explicit arithmetic conversion
- preserve the resulting semantic meaning
- assign the chart display unit to the converted unit

Conceptually:

```text
verified source value in seconds
→ multiply by 1000
→ resulting value in milliseconds
→ chart display unit = milliseconds
```

Do not invent conversion factors for unknown units.

### APM latency

For APM latency panels, determine the unit from the selected telemetry source.

Do not assume that:

- all Splunk APM latency telemetry uses the same unit
- OpenTelemetry semantic-convention metrics use the same unit as Splunk APM Monitoring MetricSets
- a percentile operation changes the unit
- Terraform `value_unit` performs a unit conversion

If the unit cannot be verified, leave the chart unit unresolved or use the verified native unit and report the uncertainty.

### Validation

Before marking latency SignalFlow as validated, verify:

- source telemetry unit
- percentile or aggregation semantics
- explicit unit conversion when present
- chart display unit
- consistency between the SignalFlow result and chart labelling

Mark the panel `UNVERIFIED` when the source unit cannot be established.

