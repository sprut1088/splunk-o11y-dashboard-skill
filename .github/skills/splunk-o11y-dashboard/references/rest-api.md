# REST API Generation Rules

## Contents

- [Core rule](#core-rule)
- [Endpoint verification gate](#endpoint-verification-gate)
- [Realm and API endpoint](#realm-and-api-endpoint)
- [Authentication and secret handling](#authentication-and-secret-handling)
- [Token rules](#token-rules)
- [Secret handling](#secret-handling)
- [Credential environment runtime-evidence gate](#credential-environment-runtime-evidence-gate)
- [Read versus write access](#read-versus-write-access)
- [Dashboard resource hierarchy and operation order](#dashboard-resource-hierarchy-and-operation-order)
- [Read before write](#read-before-write)
- [Core resource endpoints](#core-resource-endpoints)
- [Creation order](#creation-order)
- [Update behavior](#update-behavior)
- [Update semantics verification gate](#update-semantics-verification-gate)
- [Delete behavior](#delete-behavior)
- [Failure and orphan handling](#failure-and-orphan-handling)
- [REST validation and publish safety](#rest-validation-and-publish-safety)
- [Uncertain write outcome gate](#uncertain-write-outcome-gate)
- [Concurrency and lost-update evidence gate](#concurrency-and-lost-update-evidence-gate)

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

## Endpoint verification gate

Every REST endpoint the skill mentions must be independently verified from authoritative Splunk documentation before it is presented as an actionable API call. Verification must cover the exact HTTP method and the exact path.

This gate applies equally to:

- write endpoints
- read-only endpoints
- existence checks
- duplicate checks
- lookup or search endpoints
- validation or preflight endpoints
- helper or auxiliary API calls

Never infer an endpoint from:

- resource naming conventions
- another resource's API shape
- common REST patterns
- guessed singular or plural resource names
- previously seen but unverified API behavior

User assertions do not validate an endpoint.

Assign `VERIFIED_DOCS` to an endpoint only when authoritative Splunk documentation supports that exact method and path. Verifying an endpoint for one resource does not verify the equivalent endpoint for another resource.

If a read-only check is desirable but its exact endpoint cannot be verified, state it without naming a path, for example:

```text
A read-only existence check is recommended, but the exact API endpoint remains UNVERIFIED.
```

An unverified endpoint, including an auxiliary one, must not appear in:

- generated commands
- proposed publication sequences
- troubleshooting instructions
- preflight steps
- future-action recommendations

### Endpoint evidence in final recommendations

Every exact endpoint that appears anywhere in the final answer must have explicit authoritative support for that exact method, path, and query behavior before it is presented as actionable. This includes endpoints in:

- recommended next operations
- duplicate checks
- existence checks
- read-only preflight steps
- future approval sequences
- troubleshooting instructions
- example commands

The verification must be established in the same response: state the exact method and path as `VERIFIED_DOCS` together with its authoritative source before naming it in any recommendation. An endpoint that was not explicitly verified in the response must not be named, even if it seems obvious.

Do not treat an endpoint as verified because another operation on the same resource, or a related resource, was verified. For example:

- verifying `POST /dashboard` does not verify `GET /dashboard`
- verifying `GET /dashboardgroup/{id}` does not verify `GET /dashboard`
- verifying a collection path does not verify its query parameters, filtering, or search behavior

Do not infer query behavior, such as searching by name, from resource naming conventions.

If an exact endpoint was not independently verified, do not name it. Say instead:

```text
A read-only duplicate/existence check is recommended, but the exact API operation remains UNVERIFIED.
```

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

When a user supplies a credential literal in the conversation:

- never reproduce it in commands, payloads, files, diagnostics, summaries, or examples
- never encode, escape, split, or otherwise transform it to bypass these rules
- never create `.env` or any other file containing it
- never stage, commit, or recommend committing it
- use symbolic environment references only, such as `${SPLUNK_ACCESS_TOKEN}` or `$env:SPLUNK_ACCESS_TOKEN`
- a private repository does not make secret storage safe

### Credential environment runtime-evidence gate

Environment inspection must be boolean/existence-only. Never print, echo, dump, or compare credential values, and never enumerate all environment variables to find credentials.

Report the credential environment state only from the observed outcome of a non-revealing existence check. Distinguish three outcomes:

1. The check completed successfully and the variable exists: report `<VARIABLE> is configured`.
2. The check completed successfully and the variable does not exist: report `<VARIABLE> is not configured`.
3. The check failed, could not run, or its result could not be observed: report `Credential environment state: UNVERIFIED`.

A check has completed successfully only when the command ran without error and its existence result was observed. Never convert any of the following into "not configured":

- a tool or command failure
- a non-zero or abnormal exit status
- missing or truncated stdout
- a shell or parser error
- a timeout
- a permission error
- an unavailable execution environment

Do not claim that no credential exists, that no authenticated session exists, that the token is absent, or that runtime access is unavailable because no token is configured, unless successful evidence establishes that statement. If the state is `UNVERIFIED`, say that runtime access was not attempted rather than that it is unavailable.

The existence of a credential environment variable is not authentication validation. It must never be reported as `VERIFIED_LIVE` or `RUNTIME_VALIDATED`, and it must never be treated as authorization to read or write Splunk resources.

#### Credential-evidence scope

An environment-variable existence check proves only the state of the exact variable checked. Do not extend its result beyond that variable.

Treat these as separate facts. Each needs its own evidence:

1. Specific credential-variable state, such as whether `SPLUNK_ACCESS_TOKEN` is set.
2. Authenticated-session state, such as whether an authenticated connector, session, CLI profile, credential store, or runtime integration is available.
3. Live API validation state, such as whether an authenticated read-only Splunk API call actually succeeded in this run.

A successful `<VARIABLE> is not configured` result must never be turned into a broader conclusion such as:

- no authenticated connection exists
- no authenticated session exists
- no Splunk authentication exists
- live access is unavailable
- runtime authentication is impossible

Do not infer the absence of other authentication mechanisms, connectors, sessions, credential stores, CLI profiles, or runtime integrations unless each was independently checked. If a mechanism was not inspected, its state remains `UNVERIFIED`.

When no authenticated live operation was established during the run, use wording such as:

```text
No authenticated Splunk runtime connection was established in this run.
```

or:

```text
Live telemetry discovery was not attempted because no verified runtime authentication path was established for this run.
```

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

These paths are structural candidates, not verified endpoints. Apply the [Endpoint verification gate](#endpoint-verification-gate) to each exact method and path before presenting it.

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

### Update semantics verification gate

Verifying that an update endpoint and HTTP method exist is not sufficient to verify update semantics.

Before generating any update payload or update sequence, independently verify from authoritative Splunk documentation, for that exact resource and operation:

- whether the request is a full replacement or a partial update
- which fields are required
- whether omitted fields are preserved, cleared, reset to defaults, or rejected
- whether existing fields must be re-supplied
- whether immutable or server-managed fields must be excluded

Never infer complete-representation semantics merely because the method is `PUT`.

Never infer partial-update semantics merely because the method is `PATCH`.

Report endpoint verification and update-semantics verification separately. A `PUT`, `POST`, or `PATCH` endpoint can be `VERIFIED_DOCS` for its method and path while its payload and update semantics remain `UNVERIFIED`.

If full-versus-partial semantics cannot be established:

- mark the update payload semantics `UNVERIFIED`
- do not generate an executable update payload
- do not recommend retrieving, merging, and sending a complete object
- do not state that a full or merged representation should be sent
- do not present the update as ready for future execution, including in publication sequences or approval plans

State it this way instead:

```text
The update endpoint is VERIFIED_DOCS, but replacement/merge semantics remain UNVERIFIED; no update payload or execution sequence is generated.
```

Do not delete and recreate an existing resource as a workaround for unresolved update semantics.

Only when complete-replacement semantics are authoritatively verified may the skill retrieve the existing object, merge the requested changes, and send the complete representation.

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

When any create, update, or delete outcome is uncertain, apply the [Uncertain write outcome gate](#uncertain-write-outcome-gate).

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

Checking the prior result is necessary but not sufficient. A retry is allowed only when the [Uncertain write outcome gate](#uncertain-write-outcome-gate) is satisfied.

## Uncertain write outcome gate

Apply this gate when a create, update, or delete request was sent previously but its final server-side result is uncertain.

### Uncertain outcome state

1. Preserve the operation result as `UNVERIFIED`.
2. Distinguish these states, which are not equivalent:
   - no response ID was received
   - no resource ID is known to the client
   - no resource exists server-side
3. If no ID was returned, say:

   ```text
   No confirmed resource ID is available from the prior attempt.
   ```

   Do not say:

   ```text
   No ID exists.
   ```

4. A timeout, connection failure, client-side exception, interrupted response, missing response body, or other ambiguous failure does not prove that the server rejected the write.
5. Never assume an uncertain POST definitely failed server-side.
6. Never assume an uncertain POST definitely succeeded server-side.
7. Never retry an uncertain create merely because retrying would be operationally convenient.

### Negative lookup evidence

A read, search, or list result that returns zero candidates may resolve an uncertain write only when authoritative evidence establishes that the lookup is sufficient to prove absence for the relevant scenario.

Before treating zero results as proof that the resource does not exist, verify that:

- the lookup covers the correct resource population
- required pagination was fully exhausted
- the caller has sufficient visibility and permissions
- the API's consistency and visibility semantics are sufficient for a recent prior write
- the search key can identify the target resource reliably enough for the decision

If any of these remain unresolved:

- keep resource existence `UNVERIFIED`
- do not classify the resource as absent
- do not propose a new POST as ready for approval
- do not say the resource was "very likely not created" as justification for retry
- do not convert the result into CREATE

A zero-result name search can be useful evidence, but it is not automatically proof of absence.

### Retry rule

A new create request after an uncertain prior create may be proposed only after the prior resource-existence state has been safely resolved to absent with sufficient evidence.

If absence cannot be established, state:

```text
Prior create outcome remains UNVERIFIED; retry is blocked to avoid duplicate creation.
```

A proposed retry, when allowed, still requires separate explicit user approval under the existing publish gates.

### User-supplied resource IDs

For a user-supplied resource ID reported as successfully created:

- preserve the ID
- do not delete it merely to restart
- do not claim its current configuration matches the intended configuration until verified
- reuse it for publication only after its identity and configuration are sufficiently established when that matters to the operation

Do not turn "preserve this known ID" into "reuse without verification" while configuration match remains `UNVERIFIED`.

A user-supplied ID is a user-supplied runtime fact, not `VERIFIED_DOCS` or `VERIFIED_LIVE`.

### Dashboard and other resource recovery

Apply the same uncertain-result principle to dashboards, dashboard groups, charts, and other resources.

A name search returning no candidates must not automatically authorize CREATE when the search cannot establish absence sufficiently.

Keep CREATE / UPDATE / NO CHANGE unresolved until the evidence supports exactly one of those states.

This gate does not relax any other rule in this reference. The endpoint verification gate, update semantics verification gate, delete safeguards, credential safeguards, approval gates, and partial-failure resource preservation all continue to apply.

## Concurrency and lost-update evidence gate

Apply this gate whenever an update to an existing resource is considered, and whenever documentation is reviewed for ETag, If-Match, If-Unmodified-Since, version, revision, generation, conditional update, optimistic concurrency, compare-and-swap, conflict status, or another write-precondition mechanism.

### Mechanism evidence states

Distinguish these three states. They are not equivalent:

1. Mechanism `VERIFIED_DOCS`: authoritative Splunk documentation explicitly establishes the exact mechanism, header or field, request behavior, response behavior, and conflict outcome for that exact resource and operation.
2. Mechanism not found: the documentation reviewed in this run did not describe such a mechanism.
3. Mechanism proven absent: authoritative evidence explicitly establishes that no such mechanism exists for that resource and operation.

Failure to find a concurrency mechanism in the reviewed documentation does not prove that no such mechanism exists.

If no mechanism is authoritatively verified, classify it as:

```text
Concurrency protection: UNVERIFIED
```

Never convert `UNVERIFIED` into `absent`. Never say:

```text
UNVERIFIED, so treat it as absent.
```

Use wording such as:

```text
No concurrency-protection mechanism was verified from the authoritative documentation reviewed in this run.
```

While concurrency protection is `UNVERIFIED`:

- do not rely on ETag, If-Match, version, revision, conflict status, or any other conditional-write behavior
- do not invent or guess such headers, fields, or status codes, and do not infer them from generic HTTP or REST conventions
- do not claim such mechanisms do not exist unless authoritative evidence explicitly establishes their absence

A documented read-only field such as a last-updated timestamp can help detect a change between two reads. It is not a write precondition unless documentation explicitly establishes that it can be used as one.

### Read-to-write race wording

When a fresh read and a later update are not protected by a `VERIFIED_DOCS` conditional-write mechanism:

- state that a read-to-write race remains
- do not claim categorically that the race "cannot be closed" unless that impossibility is itself established by authoritative evidence

Use wording such as:

```text
No VERIFIED_DOCS mechanism available in this run closes the read-to-write race.
```

or:

```text
Write-time conflict protection remains UNVERIFIED, so the generated workflow cannot claim lost-update prevention.
```

### Historical reads

- Prior resource identity or configuration may be recorded as user-supplied runtime facts or as historical `VERIFIED_LIVE` evidence for the time of that read.
- Current state remains `UNVERIFIED` until it is freshly read.
- Historical `VERIFIED_LIVE` state never automatically becomes current write-time `VERIFIED_LIVE` state.
- A known resource ID or matching name does not prove unchanged identity or configuration.

### Safe future-write behavior

If concurrency protection remains `UNVERIFIED`:

1. Require a fresh read of the exact target resource, using a `VERIFIED_DOCS` read operation, before preparing any update.
2. Compare current state with both the prior state and the intended state.
3. Surface intervening changes. If current state differs from the prior state outside the requested change, report a concurrent modification and keep the write blocked until it is resolved.
4. Preserve unrelated current changes. Do not automatically restore the prior state.
5. Verify the update endpoint and payload semantics under the [Update semantics verification gate](#update-semantics-verification-gate).
6. Do not present stale snapshots as update payloads, and do not recommend a blind read-merge-write from a prior read.
7. Do not claim lost-update safety.
8. Clearly expose the residual race before any future write.
9. Require separate explicit approval before any future write.

If the workflow allows proceeding despite residual concurrency risk, it must explicitly state that:

- lost-update prevention is NOT verified
- the residual read-to-write race remains
- proceeding does not make the operation concurrency-safe
- post-write verification can detect some conflicts but does not prevent them

Explicit user acceptance of risk is not evidence that concurrency protection exists, and it does not change `Concurrency protection: UNVERIFIED`.

This gate does not relax any other rule in this reference. The endpoint verification gate, update semantics verification gate, uncertain write outcome gate, read and credential safeguards, approval gates, and destructive-operation safeguards all continue to apply.