# Dashboard Input Specification

## Contents

- [Core rule](#core-rule)
- [Recommended structured input](#recommended-structured-input)
- [Supported top-level sections](#supported-top-level-sections)
- [Dashboard fields](#dashboard-fields)
- [Target fields](#target-fields)
- [Scope fields](#scope-fields)
- [Variables and filters](#variables-and-filters)
- [Panel fields](#panel-fields)
- [Missing information](#missing-information)
- [Conflicting input](#conflicting-input)
- [Output normalization](#output-normalization)

Use this reference when the user provides structured YAML or JSON requirements for a Splunk Observability Cloud dashboard.

## Core rule

Accept both:

- free-form natural-language dashboard requirements
- structured YAML or JSON dashboard specifications

Do not require structured input when the user's natural-language request is sufficient.

When structured input is supplied, treat it as the primary dashboard specification for that request.

Do not silently override explicit structured values with assumed defaults.

## Recommended structured input

A structured dashboard request can use the following logical fields:

```yaml
dashboard:
  name: "Payments Service Overview"
  description: "Operational dashboard for the payments service"
  audience: "sre"
  experience: "new"
  output: "terraform"
  mode: "generate"

target:
  realm: "eu0"
  dashboard_group: "Application Observability"

scope:
  service: "payments"
  environment: "production"

variables:
  - property: "deployment.environment"
    alias: "Environment"

  - property: "service.name"
    alias: "Service"

panels:
  - title: "Request Rate"
    question: "How much traffic is the service receiving?"
    visualization: "time_chart"
    metric: "<verified metric or histogram>"
    aggregation: "<verified operation>"

  - title: "Error Rate"
    question: "What percentage of requests are failing?"
    visualization: "time_chart"
    metric: "<verified telemetry>"
    calculation: "<verified formula>"

  - title: "P95 Latency"
    question: "What is the p95 request latency?"
    visualization: "time_chart"
    metric: "<verified histogram or latency representation>"
    percentile: 95
```

Treat this as a logical input example, not as proof that the example telemetry exists.

## Supported top-level sections

Prefer these sections when structured input is used:

- `dashboard`
- `target`
- `scope`
- `variables`
- `filters`
- `panels`

Additional sections may be accepted when they are clearly relevant.

Do not reject a request merely because it contains extra useful fields.

## Dashboard fields

The `dashboard` section can include:

- `name`
- `description`
- `audience`
- `experience`
- `output`
- `mode`

Recommended values:

- `audience`: `executive`, `sre`, `engineering`, or another clearly stated audience
- `experience`: `new`, `classic`, or `auto`
- `output`: `terraform` or `rest`
- `mode`: `generate`, `validate`, or `publish`

Default behavior when omitted:

- `experience`: prefer new experience where supported
- `output`: Terraform
- `mode`: Generate

Do not invent a dashboard name when a meaningful name can be derived directly from the user's request.

## Target fields

The `target` section can describe where the dashboard belongs.

Typical fields include:

- `realm`
- `dashboard_group`
- `dashboard_id`
- `existing_dashboard`

Do not fabricate resource IDs.

When the dashboard group or dashboard already exists, prefer resolving the existing resource rather than creating a duplicate.

## Scope fields

The `scope` section describes the operational scope of the dashboard.

Typical scope can include:

- service
- environment
- namespace
- cluster
- host
- cloud provider
- region
- application
- business domain

Treat these values as intent.

Do not assume the corresponding telemetry dimension exists until it has been verified.

## Variables and filters

Structured variables and filters must follow the telemetry-validation rules.

For every variable or filter:

1. Verify the property or dimension.
2. Preserve exact spelling and case.
3. Validate values where possible.
4. Distinguish interactive variables from fixed filters.
5. Do not silently substitute similarly named properties.

## Panel fields

Each panel should describe the question the chart is intended to answer.

Useful fields include:

- `title`
- `question`
- `visualization`
- `metric`
- `histogram`
- `dimensions`
- `filters`
- `aggregation`
- `percentile`
- `calculation`
- `unit`
- `group_by`
- `sort`
- `limit`

Not every field is required for every panel.

Do not force irrelevant fields into the panel definition.

## Missing information

When structured input is incomplete:

1. Use verified context already supplied by the user.
2. Use live read-only discovery when available.
3. Use verified inventory or documentation.
4. Ask only for information that blocks correct generation.
5. Leave unsupported telemetry unresolved rather than inventing it.

Do not reject an otherwise usable specification merely because optional fields are missing.

## Conflicting input

If natural-language instructions and structured input conflict:

1. Prefer the user's most recent explicit instruction.
2. Prefer explicit structured values over inferred defaults.
3. Do not silently choose between two materially conflicting explicit requirements.
4. Call out the conflict when it affects correctness or deployment behavior.

## Output normalization

Internally normalize both natural-language and structured requests into the same conceptual dashboard plan before generating Terraform or REST output.

That normalized plan should include:

- dashboard purpose
- audience
- target experience
- output path
- generation mode
- target realm and dashboard group when relevant
- variables and fixed filters
- required panels
- verified telemetry
- unresolved telemetry
- validation status