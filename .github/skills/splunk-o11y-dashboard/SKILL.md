---
name: splunk-o11y-dashboard
description: Create, validate, and optionally publish Splunk Observability Cloud dashboards from natural-language requirements or structured YAML/JSON specifications. Use for Splunk Observability Cloud dashboard-as-code tasks involving Terraform, REST API payloads, SignalFlow, chart selection, dashboard variables, filters, layout, APM, infrastructure, Kubernetes, cloud, RUM, SRE, executive, or service-level dashboards. Prefer the new dashboard experience where supported, fall back to classic-compatible patterns when required, verify metrics and dimensions before use, and never invent unsupported telemetry.
---

# Splunk Observability Cloud Dashboard Workflow

Follow this workflow in order.

1. Understand the dashboard request.
   - Accept either natural-language requirements or structured YAML/JSON.
   - Identify the dashboard purpose, intended audience, telemetry domain, desired output format, target Splunk realm if relevant, filters, and any required services or resources.
   - Ask only for information that is genuinely required to produce a correct dashboard.

2. Determine the generation mode.
   - Default to Terraform unless the user explicitly requests REST API.
   - Support three modes:
     - Generate: create dashboard code only.
     - Validate: create and validate dashboard code.
     - Publish: create, validate, show planned changes, and publish only after explicit user confirmation.

3. Determine the dashboard experience.
   - Prefer the Splunk Observability Cloud new dashboard experience where supported.
   - Fall back to classic-compatible dashboard patterns when the requested feature or supported code path requires it.
   - State which dashboard experience is being targeted.

4. Discover and validate telemetry before generating charts.
   - Prefer live Splunk Observability Cloud metadata when connectivity is available.
   - Otherwise use user-provided metric and dimension inventories.
   - Otherwise use officially documented Splunk or OpenTelemetry telemetry names.
   - Never invent metric names, dimensions, properties, aggregations, or unsupported SignalFlow.
   - Clearly flag any telemetry that cannot be verified.

5. Design the dashboard before generating code.
   - Select charts based on the operational question being answered, not merely on the available visualization type.
   - Define dashboard variables and filters before individual chart filters where shared filtering is appropriate.
   - Group related panels logically.
   - Avoid duplicate charts that answer the same question.
   - Prefer useful operational signals over decorative visualizations.

6. Generate the requested code.
   - Produce complete Terraform by default.
   - Produce REST API payloads when explicitly requested.
   - Use valid SignalFlow where SignalFlow is required.
   - Keep generated resources readable, reusable, and suitable for version control.

7. Validate the result.
   - Check referenced metrics and dimensions.
   - Check chart type compatibility.
   - Check SignalFlow structure.
   - Check dashboard variables, filters, layout, and resource references.
   - Check Terraform or REST payload consistency.
   - Report any assumptions or unresolved validation gaps.

8. Publish only when explicitly requested.
   - Never publish a generated dashboard merely because credentials or connectivity are available.
   - Show the planned dashboard creation or update first.
   - Require explicit confirmation before creating, modifying, or replacing dashboards in Splunk Observability Cloud.

## References

Use [references/telemetry-discovery.md](references/telemetry-discovery.md) whenever discovering, selecting, validating, or substituting metrics, dimensions, properties, filters, services, hosts, Kubernetes resources, cloud resources, or other telemetry.

Use [references/dashboard-design.md](references/dashboard-design.md) whenever designing dashboard structure, choosing visualizations, arranging layout, defining dashboard variables or filters, controlling cardinality, or selecting an APM dashboard pattern.

Use [references/signalflow.md](references/signalflow.md) whenever generating, reviewing, validating, or troubleshooting SignalFlow, including filters, aggregations, histograms, APM Monitoring MetricSets, arithmetic, ratios, rollups, and validation behavior.

Use [references/terraform.md](references/terraform.md) whenever generating, reviewing, validating, planning, or applying Terraform for Splunk Observability Cloud dashboards, including provider configuration, dashboard groups, chart resources, layout, filters, variables, resource selection, validation, and apply safety.

Use [references/rest-api.md](references/rest-api.md) whenever generating, reviewing, validating, discovering, or executing Splunk Observability Cloud REST API operations for dashboards, including realm endpoints, authentication, dashboard groups, charts, dashboards, create/update/delete behavior, runtime validation, and publish safety.

Use [references/input-spec.md](references/input-spec.md) whenever the user provides structured YAML or JSON dashboard requirements, or when normalizing natural-language requirements into a consistent internal dashboard plan before generating Terraform or REST output.

Use [references/output-contract.md](references/output-contract.md) whenever presenting generated dashboard output to the user, including dashboard summary, telemetry preflight, design summary, generated Terraform or REST output, validation status, unresolved assumptions, and publish or apply status.

Use [references/acceptance-tests.md](references/acceptance-tests.md) when testing or reviewing the skill against representative Splunk Observability Cloud dashboard scenarios, beginning with the APM service dashboard acceptance test and its explicit pass/fail criteria.