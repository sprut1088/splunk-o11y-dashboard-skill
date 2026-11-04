# Dashboard Output Contract

## Contents

- [Core rule](#core-rule)
- [Default response structure](#default-response-structure)
- [1. Dashboard summary](#1-dashboard-summary)
- [2. Telemetry preflight](#2-telemetry-preflight)
- [3. Dashboard design](#3-dashboard-design)
- [4. Generated output](#4-generated-output)
- [5. Validation result](#5-validation-result)
- [6. Assumptions and unresolved items](#6-assumptions-and-unresolved-items)
- [7. Publish or apply status](#7-publish-or-apply-status)
- [Code quality](#code-quality)

Use this reference whenever presenting generated dashboard-as-code output to the user.

## Core rule

Present dashboard output in a consistent structure so the user can understand:

1. What will be created.
2. Which telemetry was verified.
3. Which assumptions remain.
4. Which code or payload was generated.
5. What validation was performed.
6. Whether any publish or apply action is still pending.

Do not return only raw Terraform or JSON when important validation or assumptions need to be communicated.

## Default response structure

Use this structure unless the user explicitly asks for code only.

### 1. Dashboard summary

State:

- dashboard name
- intended audience
- dashboard experience
- output method
- mode
- target realm when known
- dashboard group when known

### 2. Telemetry preflight

Summarize telemetry validation.

Include counts or a concise list for:

- `VERIFIED_LIVE`
- `VERIFIED_INVENTORY`
- `VERIFIED_DOCS`
- `UNVERIFIED`

Identify blocking gaps.

Do not claim full validation while required telemetry remains unverified.

### 3. Dashboard design

Summarize the planned dashboard structure.

Include:

- shared variables
- fixed filters
- major dashboard sections
- panel titles
- visualization types
- operational question answered by each panel

Keep this concise when the user primarily wants generated code.

### 4. Generated output

For Terraform, provide complete usable Terraform rather than disconnected fragments unless the user requests a fragment.

For REST, provide the verified request method, endpoint pattern, headers, and payload required for the requested operation.

Do not include real secrets.

### 5. Validation result

Report the appropriate validation status.

For SignalFlow, use:

- `RUNTIME_VALIDATED`
- `STATICALLY_VALIDATED`
- `UNVERIFIED`

For Terraform, use:

- `GENERATED`
- `STATICALLY_VALIDATED`
- `PLAN_VALIDATED`
- `APPLIED`

For REST, use:

- `GENERATED`
- `STATICALLY_VALIDATED`
- `RUNTIME_VALIDATED`
- `PUBLISHED`

Do not promote a result to a higher validation level than was actually achieved.

### 6. Assumptions and unresolved items

List only assumptions that materially affect correctness, deployment, telemetry, or behavior.

Do not create a large assumptions section for obvious defaults.

Examples of material unresolved items include:

- unverified metric
- unverified dimension
- unknown realm
- unresolved dashboard group
- unsupported visualization
- unknown existing dashboard ID
- provider-version compatibility issue

### 7. Publish or apply status

In Generate or Validate mode, clearly state that no write operation was performed.

In Publish mode, show the planned changes and require explicit confirmation before executing them.

After a successful write operation, state exactly which resources were created or updated.

Do not say a dashboard was published when only code or payloads were generated.

## Code quality

Generated code should be:

- complete enough for the requested task
- readable
- consistently named
- suitable for source control
- free of hard-coded secrets
- free of invented telemetry
- free of unsupported provider or API fields

Avoid placeholders in final deployable code unless a required value genuinely cannot be resolved.

When a placeholder is unavoidable, make it explicit and explain what must replace it.