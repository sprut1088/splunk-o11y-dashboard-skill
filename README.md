# Splunk Observability Cloud Dashboard Skill

A GitHub Copilot agent skill that turns natural-language or structured YAML/JSON requirements into **Splunk Observability Cloud dashboards-as-code**: Terraform (`splunk-terraform/signalfx`) or REST API payloads, with SignalFlow chart programs.

The skill is built around one principle: **never invent telemetry**. Every metric, dimension, SignalFlow operation, unit, provider attribute, and API field must be verified before it reaches deployable output. Panels that cannot be verified stay in the dashboard design, marked `UNVERIFIED`, with no deployable code.

## Features

- **Two output paths**: Terraform (default) or REST API (`/v2/chart`, `/v2/dashboard`, `/v2/dashboardgroup`).
- **Three strictly separated modes**: Generate, Validate, and Publish. Publish always requires a separate, explicit confirmation before any write.
- **Telemetry-first workflow**: live read-only discovery, then user inventories, then official Splunk/OpenTelemetry documentation, otherwise `UNVERIFIED`.
- **Splunk APM-native routing**: prefers Monitoring MetricSets (`service.request`, `spans`, `traces`, `inferred.services`) and the histogram interface, and excludes custom MetricSets (`sf_dimensionalized`) to avoid over-counting.
- **Semantic guardrails**: request count is not request rate, error rate is not service health, percentiles require a known unit, and no guessed error-rate or health formulas.
- **Domain references** for APM, Kubernetes, Azure, host/VM infrastructure, and RUM / Digital Experience.
- **Secret safety**: tokens are referenced only through environment variables such as `${SPLUNK_ACCESS_TOKEN}`.
- **Consistent output contract** ending with an honest lifecycle status.

## Repository layout

```text
.github/skills/splunk-o11y-dashboard/
├── SKILL.md                     # Skill entry point: workflow, generation gates, APM routing
└── references/
    ├── telemetry-discovery.md   # Source priority, verification statuses, APM telemetry preference
    ├── signalflow.md            # SignalFlow rules: histograms, count vs rate, ratios, units
    ├── terraform.md             # signalfx provider resources, attributes, layout, versioning
    ├── rest-api.md              # Realm endpoints, auth, read-before-write, publish safety
    ├── dashboard-design.md      # Chart selection, variables, 12-column layout
    ├── input-spec.md            # Structured YAML/JSON input specification
    ├── output-contract.md       # Response structure and lifecycle status vocabulary
    ├── kubernetes.md            # Kubernetes / AKS / EKS / GKE / OpenShift dashboards
    ├── azure.md                 # Azure Monitor and Azure infrastructure dashboards
    ├── host-infrastructure.md   # Linux / Windows host and VM dashboards
    ├── rum.md                   # RUM / Digital Experience dashboards
    └── acceptance-tests.md      # Regression scenarios for evaluating the skill
```

## Getting started

1. Clone this repository, or copy `.github/skills/splunk-o11y-dashboard/` into the `.github/skills/` folder of your own repository.
2. Open the repository in VS Code with GitHub Copilot (agent mode) or use the Copilot CLI. Skills under `.github/skills/` are discovered automatically.
3. Ask for a dashboard. The skill triggers on Splunk Observability Cloud dashboard requests.

## Usage

### Natural language

```text
Create a Splunk Observability Cloud dashboard for the payments service in realm eu0
with Request Count, Error Rate, and P95 Latency panels. Output Terraform.
```

### Structured input

```yaml
dashboard:
  name: "Payments Service Overview"
  audience: "sre"
  experience: "new"        # new | classic | auto
  output: "terraform"      # terraform | rest
  mode: "generate"         # generate | validate | publish

target:
  realm: "eu0"
  dashboard_group: "Application Observability"

scope:
  service: "payments"

panels:
  - title: "Request Count"
    question: "How many requests is the service receiving?"
    visualization: "single_value"
  - title: "P95 Latency"
    question: "What is the p95 request latency?"
    visualization: "time_chart"
    percentile: 95
```

Structured input is authoritative: the skill does not add windows, intervals, groupings, filters, variables, or dashboard groups that you did not request. See [input-spec.md](.github/skills/splunk-o11y-dashboard/references/input-spec.md).

## Modes

| Mode | What it does | Remote writes |
|---|---|---|
| **Generate** (default) | Produces Terraform or REST artifacts using documentation and read-only discovery. | Never |
| **Validate** | Generate, plus static/tooling validation (for example `terraform validate`/`plan`) and read-only runtime checks. | Never |
| **Publish** | Generate and validate, then show the planned create/update operations. | Only after a separate, explicit confirmation |

A request phrased as "publish now, no confirmation needed" is still treated as a request to *plan* the publication.

## Verification and lifecycle vocabulary

Telemetry status:

| Status | Meaning |
|---|---|
| `VERIFIED_LIVE` | Confirmed in the target Splunk Observability Cloud organization |
| `VERIFIED_INVENTORY` | Confirmed in a user-supplied metric/dimension inventory |
| `VERIFIED_DOCS` | Confirmed by official documentation only; runtime availability still unproven |
| `UNVERIFIED` | Could not be confirmed; no deployable code is generated |

Artifact lifecycle (each response ends with `Final lifecycle status: <STATUS>`):

| Terraform | REST | Reached when |
|---|---|---|
| `GENERATED` | `GENERATED` | Artifacts were produced |
| `STATICALLY_VALIDATED` | `STATICALLY_VALIDATED` | Schema, syntax, and semantics were reviewed or tool-validated |
| `PLAN_VALIDATED` | `RUNTIME_VALIDATED` | `terraform plan` succeeded / read-only API checks succeeded against the target org |
| `APPLIED` | `PUBLISHED` | An explicitly approved write actually completed |

The skill never reports a status higher than the one actually reached.

## Safety rules at a glance

- User assertions ("assume this metric exists") are not evidence.
- Unverified panels stay in the design but get no SignalFlow, chart resource, or payload.
- No invented metrics, dimensions, dimension values, formulas, thresholds, REST fields, or provider attributes.
- No unit relabelling without an explicit, verified conversion.
- No default realm (for example `us0`) when the realm is unknown.
- No real tokens in code, payloads, logs, or output.
- No create, update, delete, apply, or publish without explicit approval.

## Testing the skill

[acceptance-tests.md](.github/skills/splunk-o11y-dashboard/references/acceptance-tests.md) contains regression scenarios covering:

- APM service dashboards (Generate, Validate, Publish)
- Kubernetes / AKS workloads
- Azure infrastructure
- RUM / Digital Experience
- Synthetic Monitoring
- Host / VM infrastructure
- Database monitoring
- Structured YAML input
- REST API Generate and Publish modes

Run a scenario's prompt against the skill and compare the response with its expected behavior, failure conditions, and pass criteria.

## Contributing

1. Keep guidance grounded in official Splunk, OpenTelemetry, or `splunk-terraform/signalfx` documentation.
2. When adding a domain or rule, update the relevant file in `references/` and link it from `SKILL.md`.
3. Add or update an acceptance test in `acceptance-tests.md` for every behavioral change.

## Disclaimer

This is a community project and is not affiliated with or endorsed by Splunk or Cisco. Always review generated dashboards before applying them to production organizations.
