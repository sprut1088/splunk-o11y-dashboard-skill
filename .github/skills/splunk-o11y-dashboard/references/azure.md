# Azure dashboard telemetry rules


## Filter semantics

Treat Azure dashboard filters according to their exact requested meaning.
 - `subscription_id` is a subscription identifier.
 - `resource_group_id` is a resource-group identifier.
 - `azure_resource_id` is a full Azure resource identifier.
 - `azure_resource_id` is not equivalent to a resource name.
 - Do not use `azure_resource_id` as a substitute for a requested resource-name filter.
 - Use `azure_resource_name` only when that exact property is verified for the selected Azure telemetry or resource type.
 - If a resource-name property cannot be verified:
   - keep the requested Resource Name filter in the dashboard design
   - mark it `UNVERIFIED`
   - omit that dashboard variable from deployable Terraform
 - An additional Resource ID filter may be generated only when useful, clearly labelled `Resource ID`, and not presented as fulfilling a Resource Name requirement.


## Azure dimensions

Distinguish generic Azure integration dimensions from service-specific dimensions.

Do not assume a property applies to every Azure resource merely because it exists for one Azure service.

Before generating a dashboard variable, verify that the selected telemetry supports the property.

For properties that exist only on some dashboard telemetry, use `apply_if_exist = true` only when the Terraform provider supports it and partial filtering is operationally appropriate.


## Azure metric availability

Azure Monitor documentation proves that Azure exposes a metric. It does not by itself prove that the metric is present in the user's Splunk Observability Cloud organization.

Classify telemetry accordingly:

 - live target-org evidence: `VERIFIED_LIVE`
 - supplied inventory: `VERIFIED_INVENTORY`
 - Splunk Azure documentation only: `VERIFIED_DOCS`
 - insufficient evidence: `UNVERIFIED`

Do not claim `VERIFIED_LIVE` from Microsoft Azure Monitor documentation.


## Aggregation semantics

Azure metrics can expose multiple aggregations.

Verify:
1. metric name
2. Azure unit
3. supported aggregation
4. Splunk `primary_aggregation_type` behavior
5. whether additional Azure dimensions split the metric
6. whether SignalFlow aggregation changes its meaning

Do not convert a Total metric into a rate unless the requested semantic requires a rate and the transformation is verified.

Do not combine split Azure series with `sum()` unless summing those series preserves the requested resource-level semantic.


## Resource type filtering

Use documented Azure `resource_type` values.

Do not infer resource types from display names.

If multiple casing variants are supported by verified Splunk content, they may be included explicitly.


## Generate mode

Documentation and read-only discovery are allowed.

Do not run generated SignalFlow against the target Splunk environment in Generate mode.

Do not run Terraform init, validate, or plan in Generate mode.

Do not publish or modify Splunk resources.

