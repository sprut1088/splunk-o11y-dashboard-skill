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