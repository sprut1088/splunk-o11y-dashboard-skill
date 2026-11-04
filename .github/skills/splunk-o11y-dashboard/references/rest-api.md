# REST API Generation Rules

## Contents

- [Core rule](#core-rule)
- [Realm and API endpoint](#realm-and-api-endpoint)
- [Authentication and secret handling](#authentication-and-secret-handling)
- [Token rules](#token-rules)
- [Secret handling](#secret-handling)
- [Read versus write access](#read-versus-write-access)
- [Dashboard resource hierarchy and operation order](#dashboard-resource-hierarchy-and-operation-order)
- [Read before write](#read-before-write)
- [Core resource endpoints](#core-resource-endpoints)
- [Creation order](#creation-order)
- [Update behavior](#update-behavior)
- [Delete behavior](#delete-behavior)
- [Failure and orphan handling](#failure-and-orphan-handling)
- [REST validation and publish safety](#rest-validation-and-publish-safety)

Use this reference whenever generating, reviewing, validating, or executing Splunk Observability Cloud REST API operations for dashboards.

## Core rule

Use the REST API path when:

- the user explicitly requests REST API output
- Terraform cannot represent a required supported dashboard capability
- an existing dashboard needs API-based inspection or discovery
- runtime validation requires supported read-only API access

Prefer Terraform for dashboard-as-code generation unless REST API is explicitly requested or technically required.

Do not invent:

- API endpoints
- HTTP methods
- request fields
- response fields
- dashboard object types
- chart object types
- resource identifiers
- authentication headers
- unsupported payload properties

Verify the current Splunk Observability Cloud API documentation before generating an unfamiliar API operation.

## Realm and API endpoint

Splunk Observability Cloud API endpoints are realm-specific.

Prefer the current endpoint form:

```text
https://api.<REALM>.observability.splunkcloud.com
```

For example:

```text
https://api.eu0.observability.splunkcloud.com
```

Do not assume `us0`.

Determine the target realm from:

1. Existing project or environment configuration.
2. User-provided realm information.
3. Connected Splunk Observability Cloud environment metadata.
4. An explicit user prompt when the realm is genuinely required and cannot otherwise be determined.

Do not fabricate a realm.

Legacy `signalfx.com` API endpoints might still be supported, but prefer the current `observability.splunkcloud.com` endpoint family for newly generated examples unless compatibility requirements dictate otherwise.

Do not confuse API endpoints with ingest endpoints.

Dashboard management uses the API service endpoint, not the telemetry ingest endpoint.

## Authentication and secret handling

Authenticate Splunk Observability Cloud API requests using the `X-SF-TOKEN` request header.

Example structural request:

```bash
curl \
  -H "X-SF-TOKEN: ${SPLUNK_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.<REALM>.observability.splunkcloud.com/..."
```

Treat the endpoint path in this example as a placeholder.

Do not generate an API path until the required operation and endpoint have been verified.

### Token rules

Splunk Observability Cloud supports different access-token types and authorization scopes.

Before performing an API operation:

1. Determine whether authentication is available.
2. Use the least-privileged token appropriate for the operation.
3. Verify that the token has the required authorization for the requested action.
4. Do not assume that a token capable of reading telemetry can create or modify dashboards.
5. Do not change token permissions merely to make an API call succeed.
6. Do not create or rotate tokens unless the user explicitly requests that separate administrative action.

### Secret handling

Never:

- place a real access token directly in generated source code
- write a token into a dashboard JSON payload
- commit a token to Git
- include a token in `SKILL.md` or reference files
- echo a token into logs or user-visible validation output
- expose a token when displaying an example request

Prefer environment variables or an existing approved secret-management mechanism.

For example:

```powershell
$env:SPLUNK_REALM = "eu0"
$env:SPLUNK_ACCESS_TOKEN = "<set securely outside source control>"
```

The placeholder is instructional only.

Do not ask the user to paste a production access token into source-controlled files.

### Read versus write access

Treat read operations and write operations differently.

Read-only discovery can be used to:

- inspect existing supported resources
- validate resource identifiers
- discover dashboard metadata
- confirm telemetry required for dashboard generation

Write operations can create, update, or delete Splunk Observability Cloud resources.

Do not perform a write operation merely because authentication is available.

Before any create, update, or delete operation:

1. Validate the target realm.
2. Validate the target resource.
3. Validate the request payload.
4. Explain the intended change.
5. Require explicit user confirmation.

Never treat successful authentication as authorization to publish a dashboard.

## Dashboard resource hierarchy and operation order

Treat dashboard groups, charts, and dashboards as separate Splunk Observability Cloud API resources.

Use this logical hierarchy:

1. Dashboard group
2. Charts
3. Dashboard

A dashboard belongs to a dashboard group.

A dashboard references chart resources rather than treating every chart as an unverified inline object.

### Read before write

Before creating or modifying dashboard resources, inspect existing resources whenever API access is available.

Prefer this sequence:

1. Find or retrieve the intended dashboard group.
2. Find or retrieve an existing dashboard with the intended purpose.
3. Inspect referenced charts when necessary.
4. Determine whether the requested resource already exists.
5. Classify the required operation as create, update, or no change.

Do not create duplicate dashboards merely because the requested name is slightly different.

### Core resource endpoints

Use only verified current API endpoints.

Common dashboard-management resource collections include:

```text
/v2/dashboardgroup
/v2/chart
/v2/dashboard
```

For a specific existing object, the API commonly uses the object's ID:

```text
/v2/dashboardgroup/{id}
/v2/chart/{id}
/v2/dashboard/{id}
```

Verify the supported HTTP method and current request schema before generating or executing the operation.

Do not infer that every resource supports every HTTP method merely because another resource does.

### Creation order

When creating a complete dashboard using separate API resources:

1. Resolve or create the target dashboard group.
2. Create required charts and capture their returned IDs.
3. Build the dashboard payload using the verified chart IDs.
4. Create the dashboard in the intended dashboard group.

Do not generate fictitious chart IDs.

Do not create the final dashboard before the required chart IDs and dashboard-group context are known.

### Update behavior

When modifying an existing dashboard:

1. Retrieve the current dashboard first.
2. Preserve existing properties that should remain unchanged.
3. Apply only the requested changes.
4. Validate referenced chart IDs.
5. Use the documented update operation for that resource.

Do not assume that a partial payload behaves like a patch.

If the API operation requires a complete replacement representation, retrieve and merge the existing object before updating it.

### Delete behavior

Treat delete operations as destructive.

Before deleting a chart, dashboard, or dashboard group:

1. Confirm the exact resource ID.
2. Determine whether other resources depend on it when possible.
3. Show the intended deletion.
4. Require explicit user confirmation.

Never automatically delete an existing chart merely because a regenerated dashboard no longer references it.

### Failure and orphan handling

If charts are created successfully but dashboard creation fails:

- record the created chart IDs
- report that the dashboard was not created
- do not silently abandon the newly created charts
- do not automatically delete them without confirmation
- reuse them on retry when they still match the intended dashboard

Prefer recoverable and idempotent behavior over blindly recreating resources.

## REST validation and publish safety

Treat REST payload generation, validation, and execution as separate stages.

### Generate mode

In Generate mode:

1. Generate the request method, endpoint, headers, and payload structure.
2. Use only verified API paths and fields.
3. Use verified chart and dashboard semantics.
4. Do not execute create, update, or delete requests.
5. Clearly identify unresolved IDs, realm values, or schema assumptions.

Generated REST payloads are not automatically considered deployment-ready.

### Validate mode

In Validate mode:

1. Verify the realm and base API endpoint.
2. Verify the HTTP method.
3. Verify the resource path.
4. Verify required headers.
5. Verify the request payload against the current API schema.
6. Verify referenced resource IDs when live read access is available.
7. Verify telemetry and SignalFlow used inside chart definitions.
8. Confirm that no real secrets are embedded in the generated request.

Prefer read-only API calls for discovery and validation.

Do not perform a write operation as part of validation.

### Validation status

Use these statuses:

- `GENERATED`: Request or payload was created but not checked against the target environment.
- `STATICALLY_VALIDATED`: Endpoint, schema, payload structure, telemetry, and semantics were reviewed, but no target-environment API validation occurred.
- `RUNTIME_VALIDATED`: Read-only API calls successfully confirmed the relevant target resources or metadata.
- `PUBLISHED`: The requested write operation completed successfully after explicit user approval.

Do not describe a payload as `PUBLISHED` merely because it is syntactically valid.

### Publish mode

Before executing any create or update request:

1. Identify the target realm.
2. Identify the target dashboard group.
3. Identify resources to be created or changed.
4. Show the planned API operations.
5. Highlight any resources that could be replaced or overwritten.
6. Show unresolved warnings.
7. Require explicit user confirmation.

Only after explicit confirmation may write operations proceed.

### Response handling

After an API operation:

1. Check the HTTP status.
2. Capture returned resource IDs where applicable.
3. Confirm which resources were successfully created or updated.
4. Report failures without masking partial success.
5. Do not claim the dashboard was published if only some required resources succeeded.

If the API returns an error:

- preserve the useful error message
- do not expose secrets
- identify which request failed
- do not retry destructive or write operations blindly
- correct the request only after understanding the failure

### Idempotency and retries

Prefer behavior that avoids duplicate resources.

Before retrying a create operation after an uncertain failure:

1. Check whether the resource was actually created.
2. Reuse the existing resource if it matches the intended configuration.
3. Avoid creating another resource with the same operational purpose.

Do not repeatedly POST the same dashboard or chart without checking the prior result.