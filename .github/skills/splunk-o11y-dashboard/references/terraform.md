# Terraform Generation Rules

## Contents

- [Critical pre-generation gate: Terraform provider schema](#critical-pre-generation-gate-terraform-provider-schema)
- [Core rule](#core-rule)
- [Provider and resource hierarchy](#provider-and-resource-hierarchy)
- [Dashboard resource hierarchy](#dashboard-resource-hierarchy)
- [Dashboard group not supplied](#dashboard-group-not-supplied)
- [Generated resources must match the report](#generated-resources-must-match-the-report)
- [Dashboard layout rules](#dashboard-layout-rules)
- [Layout strategy](#layout-strategy)
- [Dashboard filters and variables](#dashboard-filters-and-variables)
- [Fixed dashboard filters](#fixed-dashboard-filters)
- [Dashboard variables](#dashboard-variables)
- [Filters versus variables](#filters-versus-variables)
- [Chart resource selection](#chart-resource-selection)
- [Terraform validation and apply safety](#terraform-validation-and-apply-safety)
- [Provider version safety](#provider-version-safety)


Use this reference whenever generating, reviewing, validating, or troubleshooting Terraform for Splunk Observability Cloud dashboards.

## Critical pre-generation gate: Terraform provider schema

Apply this gate before generating any `splunk-terraform/signalfx` resource.

### Match schema verification to the repository provider version

When an existing repository declares a provider version constraint or lock-file version, treat that version strategy as the schema target.

Before generating any Terraform resource:

1. identify the repository's existing provider constraint or locked version
2. verify the generated resource type and every generated attribute against a provider version compatible with that strategy
3. do not treat documentation for the latest provider release as sufficient evidence for an older repository constraint
4. do not assume that basic or commonly used attributes are unchanged across provider versions
5. if compatible-version schema evidence cannot be established, mark provider-schema compatibility `UNVERIFIED`

If provider-schema compatibility is `UNVERIFIED`:

- do not claim the Terraform resource is schema-verified
- omit any resource or attribute whose availability cannot be established for the repository's provider version
- preserve the intended dashboard component in the design and state that provider-version compatibility is the blocker

For example, if the repository uses `~> 9.3.0`, documentation for provider v9.36 does not by itself verify resources or attributes for the repository.

### Verify the resource schema before generating attributes

Treat each Terraform resource independently.

Do not assume an attribute supported by one chart resource is supported by another.

Before generating a resource, verify:

- resource type
- top-level attributes
- nested blocks
- allowed `plot_type`
- dashboard variable attributes
- layout attributes
- unit attributes
- exported attributes
- resource references

Do not generate plausible-looking attributes from memory.

### Terraform input variables are not Splunk dashboard variables

Do not confuse:

```hcl
variable "service_name" {
  type = string
}
```

with a Splunk Observability Cloud dashboard variable.

Terraform `variable` blocks define Terraform configuration inputs.

Splunk dashboard variables belong inside the dashboard resource using the provider-supported nested block, for example structurally:

```hcl
resource "signalfx_dashboard" "example" {
  # ...

  variable {
    property = "<verified-service-property>"
    alias    = "Service"
  }
}
```

Only include attributes inside that nested `variable` block that are verified in the applicable provider schema.

Do not invent dashboard-variable attributes such as:

```hcl
default         = "payments"
value_label     = "Service"
suggested_value = "payments"
```

unless those exact attributes are supported by the selected provider version.

### Chart units

Do not generate arbitrary chart attributes such as:

```hcl
unit = "Milliseconds"
unit = "Requests/sec"
```

unless the selected resource schema explicitly defines `unit`.

Do not use:

```hcl
unit_prefix = "m"
```

to represent milliseconds.

For resources that support plot-level display configuration, use only verified nested attributes such as `viz_options` and `value_unit`, and only on resources whose provider schema explicitly supports them.

A display unit does not convert telemetry.

The SignalFlow result must already have the correct unit.

### Table chart schema

Treat `signalfx_table_chart` separately from time charts and single-value charts.

Do not copy visualization blocks from another chart type.

Only generate attributes documented for `signalfx_table_chart`.

When appropriate and supported, table grouping can use:

```hcl
group_by = ["sf_operation"]
```

Do not generate `viz_options` or other visualization-specific nested blocks for a table chart unless the selected provider schema explicitly supports them.

### Dashboard filters and variables

Do not create fixed dimension values unless they were:

- explicitly supplied by the user
- discovered from live telemetry
- provided by an inventory

A requested service such as:

```text
payments
```

may be used as a fixed `service.name` filter because it was supplied by the user.

Do not invent environment values.

If the user requests both:

- a dashboard for service `payments`
- a service dashboard variable whose exact telemetry property is verified

preserve the user's intent carefully.

Do not generate conflicting fixed filters and variables without explaining the behavior.

### Variable-to-chart consistency

If a dashboard property is exposed as an interactive variable, do not hard-code a conflicting value for that same property inside chart SignalFlow unless the requested behavior explicitly requires both.

For example, if the dashboard contains:

```hcl
variable {
  property = "<verified-service-property>"
  alias    = "Service"
}
```

and the purpose of that variable is to switch services, do not generate every chart with:

```python
filter('<verified-service-property>', 'payments')
```

because the chart remains permanently scoped to `payments`.

Choose one of these patterns deliberately:

1. **Dedicated service dashboard**
   - use the verified service property with value `payments` as the fixed dashboard scope
   - do not expose that same verified service property as a service-switching variable

2. **Reusable service dashboard**
   - expose the verified service property as a dashboard variable
   - ensure chart filtering is compatible with that variable mechanism
   - do not hard-code `payments` inside each chart

If the user's request contains both a named service and a requested service filter, prefer the reusable variable interpretation only after the exact service property for the selected telemetry has been verified, unless the user explicitly states that the dashboard must be permanently locked to that service.

The supplied service name may be documented as the intended initial context, but do not invent an unsupported default-value attribute merely to preselect it.

Before finalizing Terraform, verify that every dashboard variable can actually affect the charts it is intended to control.

Verifying the telemetry property name is necessary but not sufficient. Also verify that the selected Splunk dashboard/provider variable or filter mechanism is documented to constrain the generated chart type and SignalFlow program as intended.

For example, do not generate a `service.name`, `sf_service`, `deployment.environment`, `sf_environment`, or other dashboard variable merely because that property exists on the selected Monitoring MetricSet. Verify that the dashboard variable/filter mechanism actually applies that property constraint to the generated `histogram()`, `data()`, or other SignalFlow chart.

If that variable-to-chart behavior cannot be verified from the compatible provider schema, authoritative Splunk dashboard documentation, supplied repository evidence, or a safe read-only inspection of an existing working dashboard, keep the requested dashboard filter in the design as `UNVERIFIED` and omit the corresponding variable or filter block from deployable Terraform.

For Splunk APM dashboards, semantic intent such as service or environment is not sufficient evidence for a property name. Do not choose `service.name`, `deployment.environment`, `sf_service`, `sf_environment`, or another candidate until the exact property is verified for the selected Monitoring MetricSet.

If the exact service or environment property is unresolved, keep the requested filter in the dashboard design as `UNVERIFIED` and omit the corresponding dashboard variable or filter from deployable Terraform.

### Dashboard URL

When the dashboard resource exports a URL attribute, reference it directly:

```hcl
output "dashboard_url" {
  value = signalfx_dashboard.example.url
}
```

Do not quote the Terraform resource reference:

```hcl
value = "signalfx_dashboard.example.url"
```

Do not construct a dashboard URL from:

- a guessed realm
- a guessed hostname
- another unrelated resource
- a fabricated data source

### Unverified panels must not become Terraform resources

If a panel is marked `UNVERIFIED` because its telemetry, SignalFlow, dimensions, unit, or semantics could not be established:

1. keep the panel in the dashboard design
2. document why it is unresolved
3. omit the chart resource from deployable Terraform
4. omit its dashboard `chart` block
5. do not generate speculative chart code and call the Terraform production-ready

The generated Terraform may therefore contain fewer chart resources than the requested dashboard design.

This is correct behavior when some panels cannot be implemented safely.

### Validation claims

Do not claim:

```text
Terraform valid
Provider schema validated
Ready to apply
Production-ready
```

merely because HCL was generated.

Use:

- `GENERATED` when code was produced only
- `STATICALLY_VALIDATED` only after the defined static validation requirements were actually met
- `PLAN_VALIDATED` only after `terraform plan` completed successfully
- `APPLIED` only after a successful apply

If `terraform validate` was not executed successfully, state that explicitly.

## Core rule

Generate Terraform only from verified Splunk Observability Cloud provider resources, attributes, and schemas.

Do not invent:
- Terraform resource names
- provider arguments
- chart attributes
- dashboard attributes
- dashboard variable attributes
- resource relationships
- layout properties
- SignalFlow-related Terraform fields

When uncertain about provider syntax or supported attributes, verify against the current Splunk Observability Cloud Terraform provider documentation before generating code.

## Provider and resource hierarchy

Use the official Splunk Observability Cloud Terraform provider:

```hcl
terraform {
  required_providers {
    signalfx = {
      source = "splunk-terraform/signalfx"
    }
  }
}
```

Do not automatically pin the provider to whatever version appears in an example.

When generating production Terraform:

1. Detect an existing provider version constraint when working in an existing repository.
2. Preserve the repository's compatible provider strategy unless the user requests an upgrade.
3. For a new repository, recommend an explicit compatible version constraint after checking the current provider release.
4. Do not silently upgrade the provider version.

### Dashboard resource hierarchy

Model dashboard resources in this dependency order:

1. Dashboard group
2. Chart resources
3. Dashboard

A Splunk Observability Cloud dashboard must belong to a dashboard group.

Typical structure:

```hcl
resource "signalfx_dashboard_group" "example" {
  name = "Example Dashboard Group"
}

resource "signalfx_time_chart" "example" {
  name = "Example Chart"

  # Verified chart configuration goes here.
}

resource "signalfx_dashboard" "example" {
  name            = "Example Dashboard"
  dashboard_group = signalfx_dashboard_group.example.id

  chart {
    chart_id = signalfx_time_chart.example.id
  }
}
```

Treat this as a structural example only.

Do not invent chart configuration merely to make the example complete.

Prefer Terraform resource references over hard-coded Splunk resource IDs when the related resource is managed in the same Terraform configuration.

Do not create a new dashboard group when the user intends to place the dashboard in an existing managed dashboard group.

### Dashboard group not supplied

The dashboard group is a required structural value. Do not invent it.

When the request does not supply a dashboard group name, an existing group ID, or a verified existing group:

1. Do not create a `signalfx_dashboard_group` with an invented name, including a name copied from the dashboard name or test title.
2. This skill defines no default dashboard group, so mark the dashboard group `UNVERIFIED`.
3. Omit every deployable resource that requires it: the `signalfx_dashboard_group`, the `signalfx_dashboard` that references it, and any output that references either one.
4. Chart resources whose telemetry and SignalFlow are verified may still be generated as standalone resources, and must be reported as not yet attached to a dashboard.
5. State exactly which value is required to complete the deployment, such as an existing dashboard group ID or an approved new group name.

When the user supplies a group name for a new group, use exactly that name. When the user supplies an existing group, reference it and do not create a duplicate.

### Generated resources must match the report

The final Terraform is the source of truth for what was generated. Before reporting, follow the reconciliation gate in `output-contract.md`.

- A panel, variable, filter, or group reported `UNVERIFIED` or omitted must not have a resource, nested `chart`, `variable`, or `filter` block, or output in the Terraform.
- A resource present in the Terraform must be reported as generated.
- Header comments in generated files, such as a "Not implemented" note, must match the final resources.


## Dashboard layout rules

Splunk Observability Cloud dashboards use a 12-column layout.

For explicit chart placement, use the dashboard `chart` block.

Example:

```hcl
chart {
  chart_id = signalfx_time_chart.request_rate.id
  width    = 6
  height   = 2
  row      = 0
  column   = 0
}
```

Layout rules:

- `width` must be between 1 and 12.
- `height` must be 1 or greater.
- `row` is zero-based.
- `column` is zero-based and must be between 0 and 11.
- `row` identifies the topmost row occupied by the chart.
- `column` identifies the leftmost column occupied by the chart.

Before generating explicit layout coordinates:

1. Ensure chart widths fit within the 12-column dashboard.
2. Avoid overlapping chart positions.
3. Group related charts into logical rows.
4. Use larger widths for charts that require trend or breakdown visibility.
5. Use compact widths for headline or single-value charts when appropriate.
6. Keep dashboard layout readable across common screen sizes.

### Layout strategy

Prefer explicit `chart` blocks when precise dashboard placement is important.

Terraform also supports `grid` and `column` layout constructs.

Do not mix `chart`, `grid`, and `column` layout strategies in the same dashboard.

Use `grid` when multiple charts should share the same width and height and exact coordinates are unnecessary.

Use `column` when charts should be arranged into consistent vertical columns.

Be aware that `grid` and `column` are Terraform-provider-side layout constructs rather than native Splunk Observability Cloud API layout objects.

Because of this, dashboards changed manually in the Splunk UI might not reconcile cleanly with Terraform when `grid` or `column` layouts are used.

For dashboards intended to be strictly managed as code and reviewed through Terraform, prefer explicit chart placement unless there is a strong reason to use `grid` or `column`.


## Dashboard filters and variables

Use dashboard-level filters and variables when the same dimension or property should apply consistently across multiple charts.

### Fixed dashboard filters

Use a `filter` block when the dashboard should always apply a specific filter.

Example:

```hcl
filter {
  property = "<verified-service-property>"
  values   = ["payments"]
}
```

Before generating a dashboard filter:

1. Verify the exact property or dimension name.
2. Verify the filter value when possible.
3. Confirm that the property is relevant to the charts that should be affected.
4. Do not invent common dimensions merely because they are frequently used.

Supported filter behavior includes:

- `property` - dimension or property name
- `values` - one or more values, treated as OR values for that property
- `negated` - invert the filter
- `apply_if_exist` - also allow telemetry that does not contain the property

Use optional filter attributes only when their behavior is explicitly required.

### Dashboard variables

Use a `variable` block when users should be able to interactively change a shared dashboard filter.

Example:

```hcl
variable {
  property = "<verified-service-property>"
  alias    = "Service"
}
```

Before generating a dashboard variable:

1. Verify the exact underlying property.
2. Choose a user-friendly alias.
3. Do not hard-code values unless fixed defaults or restrictions are required.
4. Prefer variables for dimensions such as environment, service, namespace, region, cluster, or host only after those dimensions are verified.
5. Avoid creating variables that do not materially help dashboard navigation.

Optional variable behavior can include:

- `values`
- `value_required`
- `values_suggested`
- `restricted_suggestions`
- `replace_only`
- `apply_if_exist`

Do not enable these options by default.

Use them only when the requested dashboard behavior requires them.

### Filters versus variables

Use a fixed `filter` when a constraint is part of the dashboard definition.

Use a `variable` when the user should be able to change the filter interactively.

For example:

- A dashboard dedicated permanently to the `payments` service can use a fixed service filter.
- A reusable service dashboard intended to switch between services should normally use a service variable.

Do not generate both a fixed filter and a variable for the same property unless there is a deliberate reason.

A dashboard variable or filter does not authorize SignalFlow grouping on the same property. Do not add `by=[...]` on `sf_environment`, `deployment.environment`, `sf_service`, or another dimension because a variable or filter for that dimension was requested, including when that variable is omitted as `UNVERIFIED`. Grouping requires an explicit panel-level request; see `input-spec.md`.


## Chart resource selection

Choose the Terraform chart resource that matches the intended visualization.

Do not use `signalfx_time_chart` as a generic container for every chart type.

Common provider resources include:

- `signalfx_time_chart` - time-series visualizations
- `signalfx_single_value_chart` - headline or current-value visualizations
- `signalfx_table_chart` - tabular metric views
- `signalfx_list_chart` - ranked or list-oriented metric views
- `signalfx_heatmap_chart` - heatmap visualizations
- `signalfx_event_feed_chart` - event-oriented visualizations
- `signalfx_text_chart` - explanatory or instructional text panels

Verify that the resource still exists in the target provider version before generating it.

### Selection rule

Choose the chart type based on the operational question defined in `dashboard-design.md`.

For example:

- Use a time chart to show how request rate changes over time.
- Use a single-value chart to show a current health KPI or headline value.
- Use a table or list when users need to compare multiple entities.
- Use a heatmap only when the underlying telemetry and distribution semantics support it.
- Use a text chart for dashboard guidance, context, runbook information, or section explanation.

Do not select the Terraform resource merely because it is easy to generate.

### Provider schema rule

Each chart resource has its own supported arguments.

Do not copy attributes between chart resources unless the current provider documentation confirms they are supported.

For every generated chart:

1. Verify the Terraform resource type.
2. Verify required attributes.
3. Verify optional attributes being used.
4. Verify the SignalFlow field expected by that resource.
5. Verify visualization-specific settings.
6. Avoid unsupported attributes copied from another chart type.

### SignalFlow

Where the resource requires `program_text`, generate the SignalFlow according to `signalflow.md`.

Example structural pattern:

```hcl
resource "signalfx_time_chart" "request_rate" {
  name = "Request Rate"

  program_text = <<-EOF
    A = ...
  EOF
}
```

Do not replace `A = ...` with plausible SignalFlow until the telemetry and SignalFlow have been validated.

### New versus classic dashboard experience

Do not assume that every visualization available in the Splunk Observability Cloud UI has an equivalent Terraform resource.

If a requested visualization or capability exists in the new dashboard experience but is not supported by the Terraform provider:

1. Do not invent a Terraform resource.
2. Check whether a supported Terraform representation can preserve the intended dashboard question.
3. Otherwise identify the capability as unsupported through the selected Terraform path.
4. Consider the REST API path only if the requested capability is supported there and the user permits REST output.

Prefer correctness over forcing every requested visualization into Terraform.

## Terraform validation and apply safety

Treat Terraform generation, validation, planning, and application as separate stages.

### Generate mode

In Generate mode:

1. Generate the required Terraform files.
2. Use verified provider resources and attributes.
3. Use verified telemetry and SignalFlow.
4. Do not run or imply `terraform apply`.
5. Clearly identify any unresolved assumptions or unverified values.
6. End the response with `Final lifecycle status: GENERATED` unless a later lifecycle state was actually reached as defined in [Validation status](#validation-status).

Generated Terraform is not automatically considered deployment-ready.

### Validate mode

In Validate mode, validate the Terraform without changing Splunk Observability Cloud.

Where Terraform tooling is available, prefer this sequence:

```text
terraform fmt -check
terraform init
terraform validate
terraform plan
```

Use `terraform plan` only when the required provider configuration, variables, credentials, and backend context are available.

Do not expose access tokens, secrets, or credentials in generated files, command output, examples, or logs.

If `terraform plan` cannot be executed because credentials or environment context are unavailable, report that limitation rather than claiming full validation.

### Validation status

Distinguish validation levels:

- `GENERATED`: Terraform was created but not validated by Terraform tooling.
- `STATICALLY_VALIDATED`: Resource structure, references, telemetry, and provider schema were reviewed, but Terraform was not successfully planned against the target environment.
- `PLAN_VALIDATED`: `terraform plan` completed successfully against the intended configuration and target environment.
- `APPLIED`: Terraform was explicitly applied after user approval.

Do not report `PLAN_VALIDATED` merely because `terraform validate` succeeded.

`terraform validate` checks Terraform configuration validity but does not prove that the planned Splunk resources can be created successfully in the target environment.

### Publish or apply mode

Never run or recommend automatic `terraform apply` merely because valid credentials are available.

Before apply:

1. Complete validation.
2. Produce a Terraform plan.
3. Summarize the resources to be created, changed, or destroyed.
4. Highlight destructive or replacement actions.
5. Show unresolved assumptions or warnings.
6. Require explicit user confirmation.

Only after explicit confirmation may the apply step proceed.

### Destructive changes

Treat resource destruction or replacement as high-impact changes.

Never hide destructive actions inside a normal dashboard update.

If the plan proposes deleting or replacing an existing dashboard, chart, or dashboard group:

- call out the affected resource
- explain why Terraform proposes the action when determinable
- do not proceed automatically
- require explicit confirmation

Prefer modifying managed resources in place when supported and consistent with the requested change.

### Existing resources

Do not assume an existing Splunk Observability Cloud dashboard is already managed by Terraform.

Before generating Terraform intended to modify an existing dashboard:

1. Determine whether the resource already exists in Terraform state.
2. Determine whether an import is required.
3. Avoid creating a duplicate resource with the same operational purpose.
4. Do not fabricate Terraform state or import identifiers.

When import is required, verify the provider's current import syntax and resource identifier format before generating the import command.

## Provider version safety

Do not invent or arbitrarily pin a `splunk-terraform/signalfx` provider version.

Use this priority:

1. Preserve the version constraint already used by the repository.
2. Reuse a version from an existing `.terraform.lock.hcl` when appropriate.
3. Use a user-specified provider version.
4. Use a currently verified provider version only when the task explicitly requires selecting one for a new repository.
5. Otherwise omit the `version` constraint and clearly state that the repository should define or verify its provider-version strategy.

For example, this is acceptable when no version strategy has been established:

```hcl
terraform {
  required_providers {
    signalfx = {
      source = "splunk-terraform/signalfx"
    }
  }
}
```

Do not generate:

```hcl
version = "~> 9.3.0"
```

or any other specific version merely because it appeared in an example, memory, prior dashboard, or documentation snippet.

### Version verification

Before generating a provider version constraint, verify at least one of:

- an existing repository constraint
- the repository lock file
- an explicit user requirement
- the current provider release from an authoritative source

Do not claim that a provider version is current unless it was actually verified.

### Schema compatibility

A provider version and a Terraform resource schema are related.

When using attributes that might differ across provider versions:

- verify the schema for the selected or existing provider version
- do not assume the latest documentation matches an older pinned version
- do not assume an old example works against the latest provider
- flag unresolved provider-schema compatibility when it affects correctness

If the repository has no provider version information and the generated resource depends on version-sensitive attributes, mark that compatibility as unresolved rather than silently choosing a version.