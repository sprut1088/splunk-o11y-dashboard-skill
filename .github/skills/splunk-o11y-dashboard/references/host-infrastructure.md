# Host Infrastructure Dashboard Guidance

Use this reference when generating dashboards for Linux hosts, Windows hosts, virtual machines, or generic host infrastructure telemetry.

## Contents

- [Evidence priority](#evidence-priority)
- [Host identity](#host-identity)
- [Utilization metrics](#utilization-metrics)
- [Cumulative disk and network counters](#cumulative-disk-and-network-counters)
- [Host availability and reporting](#host-availability-and-reporting)
- [Memory](#memory)
- [Swap and paging](#swap-and-paging)
- [Filesystems](#filesystems)
- [Host dashboard variables](#host-dashboard-variables)
- [Pre-generation gate](#pre-generation-gate)

## Evidence priority

Use this order:

1. live Splunk Observability Cloud telemetry and metadata
2. user-supplied metric and dimension inventory
3. current Splunk documentation for the deployed collector or integration
4. Splunk Distribution of the OpenTelemetry Collector configuration and SignalFx exporter behavior
5. OpenTelemetry receiver documentation
6. `UNVERIFIED`

Receiver support alone does not prove that a metric reaches Splunk Observability Cloud.

Verify the final metric name, type, unit, dimensions, translation behavior, exclusions, and aggregation semantics before generating SignalFlow.

## Host identity

Prefer a verified host identity such as `host.name`.

Do not assume host names are globally unique.

Preserve host-level grouping for per-host health and resource charts.

Do not collapse multiple hosts into one aggregate unless the requested panel intentionally represents fleet-level data and the aggregation is semantically valid.

## Utilization metrics

Do not sum utilization percentages across:

- hosts
- CPU cores
- filesystems
- disks
- network interfaces

Before averaging CPU utilization across CPU series, verify that the resulting aggregation represents host-level utilization for the selected metric.

Do not assume that averaging per-core percentages is always equivalent to the platform's host utilization calculation.

The same rule applies to memory, filesystem, disk, and network utilization.

## Cumulative disk and network counters

Treat these metrics conservatively when they are verified as cumulative counters:

- `system.disk.io`
- `system.disk.operations`
- `system.network.io`
- paging or swap counters
- any similar cumulative host counter

A cumulative counter's default Delta behavior represents change over an interval.

Delta does not by itself establish a per-second unit.

Do not generate:

- bytes/s
- operations/s
- packets/s
- pages/s
- throughput
- IOPS

from a cumulative host counter unless authoritative evidence verifies the exact Splunk SignalFlow transformation that produces the requested per-second quantity for that metric.

Do not use `rollup='rate'` merely because Rate/sec exists for ordinary counter metrics or because an example uses it.

Do not assume Rate/sec semantics documented for a Counter also apply to a Cumulative Counter.

Do not automatically use `rateofchange()`, `delta()`, division by chart resolution, or another derivative calculation.

First verify the metric pipeline, metric type presented to SignalFlow, rollup behavior, operation order, and resulting unit.

If this exact transformation cannot be verified:

- keep the throughput or operations-per-second panel in the dashboard design
- mark it `UNVERIFIED`
- omit its SignalFlow
- omit its deployable Terraform chart
- never relabel Delta values as `/s`

Correct omission is preferable to a plausible but unsupported rate calculation.

## Host availability and reporting

Do not equate "currently reporting telemetry" with host availability.

A count of hosts currently emitting a metric may be described as reporting hosts only when its semantics are verified.

Do not label it:

- availability
- uptime
- healthy hosts
- hosts up

unless the required heartbeat, freshness window, expected-host inventory, and availability definition are verified.

If those inputs are missing, keep true host availability `UNVERIFIED`.

## Memory

Do not substitute free memory for available memory.

Verify platform-specific memory semantics before generating:

- memory available
- memory free
- memory used
- memory utilization

Linux and Windows memory definitions may differ.

An optional Linux metric does not prove equivalent Windows telemetry.

## Swap and paging

Do not infer swap usage or swap activity from metric names alone.

Verify:

- platform support
- exporter exclusions
- metric type
- source unit
- transformed unit
- cumulative versus interval semantics

If any of these are unresolved, mark the requested swap or paging panel `UNVERIFIED`.

## Filesystems

Preserve filesystem identity dimensions such as device and mount point when verified.

Do not sum filesystem-utilization percentages.

Do not assume a host-wide filesystem percentage is equivalent to the worst filesystem or to an arithmetic mean of filesystem percentages.

## Host dashboard variables

Generate dashboard variables only for exact verified properties.

Common candidates may include:

- `host.name`
- `os.type`
- `cloud.provider`
- `cloud.region`
- `cloud.availability_zone`

Their presence still depends on the configured resource detectors and target telemetry.

Do not invent an environment property.

Do not generate a cloud variable merely because the field exists in an OpenTelemetry semantic convention; verify that it reaches the selected Splunk metrics.

## Pre-generation gate

Before generating each host panel verify:

- final metric name
- metric type
- unit
- host identity dimension
- required filter dimensions and values
- cross-series aggregation
- counter or gauge semantics
- any rate or delta transformation
- final display unit

If any correctness-critical item is unresolved, mark the panel `UNVERIFIED` and omit deployable Terraform for that panel.
