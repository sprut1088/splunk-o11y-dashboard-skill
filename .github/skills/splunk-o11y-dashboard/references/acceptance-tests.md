# Acceptance Tests

Use these scenarios to test whether the skill produces correct, safe, and useful Splunk Observability Cloud dashboard-as-code output.

## Test 1 — APM service dashboard

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


## Acceptance Test 2 — Kubernetes / AKS workload dashboard

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