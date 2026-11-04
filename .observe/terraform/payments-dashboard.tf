terraform {
  required_providers {
    signalfx = {
      source  = "splunk-terraform/signalfx"
      version = "~> 9.3.0"
    }
  }
}

resource "signalfx_dashboard_group" "payments" {
  name = "Payments"
}

resource "signalfx_single_value_chart" "payments_request_rate" {
  name        = "Health: Request Rate"
  description = "Current HTTP server request rate in requests per second."

  program_text = <<-SIGNALFLOW
    histogram("http.server.request.duration").rate().publish(label="Requests / second")
  SIGNALFLOW
}

resource "signalfx_single_value_chart" "payments_error_rate" {
  name        = "Health: HTTP 5xx Error Rate"
  description = "Percentage of HTTP server requests with 5xx response codes."

  program_text = <<-SIGNALFLOW
    total = histogram("http.server.request.duration").rate()
    errors = histogram(
      "http.server.request.duration",
      filter=filter("http.response.status_code", "5*")
    ).rate()
    (errors / total * 100).publish(label="HTTP 5xx (%)")
  SIGNALFLOW
}

resource "signalfx_single_value_chart" "payments_p95_latency" {
  name        = "Health: p95 Latency"
  description = "Current 95th percentile HTTP server request duration."

  program_text = <<-SIGNALFLOW
    histogram("http.server.request.duration").percentile(95).publish(label="p95")
  SIGNALFLOW

  viz_options {
    label      = "p95"
    value_unit = "Millisecond"
  }
}

resource "signalfx_single_value_chart" "payments_p99_latency" {
  name        = "Health: p99 Latency"
  description = "Current 99th percentile HTTP server request duration."

  program_text = <<-SIGNALFLOW
    histogram("http.server.request.duration").percentile(99).publish(label="p99")
  SIGNALFLOW

  viz_options {
    label      = "p99"
    value_unit = "Millisecond"
  }
}

resource "signalfx_time_chart" "payments_request_rate_trend" {
  name        = "Request Rate"
  description = "HTTP server requests per second over time."

  program_text = <<-SIGNALFLOW
    histogram("http.server.request.duration").rate().publish(label="Requests / second")
  SIGNALFLOW
}

resource "signalfx_time_chart" "payments_error_rate_trend" {
  name        = "HTTP 5xx Error Rate"
  description = "HTTP 5xx responses as a percentage of all server requests."

  program_text = <<-SIGNALFLOW
    total = histogram("http.server.request.duration").rate()
    errors = histogram(
      "http.server.request.duration",
      filter=filter("http.response.status_code", "5*")
    ).rate()
    (errors / total * 100).publish(label="HTTP 5xx (%)")
  SIGNALFLOW
}

resource "signalfx_time_chart" "payments_latency_percentiles" {
  name        = "Request Latency Percentiles"
  description = "HTTP server request duration p50, p95, and p99 in milliseconds."

  program_text = <<-SIGNALFLOW
    histogram("http.server.request.duration").percentile(50).publish(label="p50")
    histogram("http.server.request.duration").percentile(95).publish(label="p95")
    histogram("http.server.request.duration").percentile(99).publish(label="p99")
  SIGNALFLOW

  viz_options {
    label      = "p50"
    value_unit = "Millisecond"
  }

  viz_options {
    label      = "p95"
    value_unit = "Millisecond"
  }

  viz_options {
    label      = "p99"
    value_unit = "Millisecond"
  }
}

resource "signalfx_list_chart" "payments_top_endpoints" {
  name        = "Top Endpoints by Request Rate"
  description = "The 10 busiest HTTP routes by request rate."
  sort_by     = "-value"

  program_text = <<-SIGNALFLOW
    histogram("http.server.request.duration").rate(by="http.route").top(10).publish(label="Requests / second")
  SIGNALFLOW
}

resource "signalfx_list_chart" "payments_dependency_latency" {
  name        = "Dependency Latency"
  description = "The 10 downstream HTTP dependencies with the highest p95 request latency."
  sort_by     = "-value"

  program_text = <<-SIGNALFLOW
    histogram("http.client.request.duration").percentile(95, by="server.address").top(10).publish(label="Dependency p95")
  SIGNALFLOW

  viz_options {
    label      = "Dependency p95"
    value_unit = "Millisecond"
  }
}

resource "signalfx_dashboard" "payments" {
  name            = "Payments Service Overview"
  description     = "Operational health, traffic, latency, endpoints, and downstream dependency latency for the payments service."
  dashboard_group = signalfx_dashboard_group.payments.id
  time_range      = "-1h"

  variable {
    property         = "service.name"
    alias            = "Service"
    values           = ["payments"]
    values_suggested = ["payments"]
  }

  variable {
    property = "deployment.environment.name"
    alias    = "Environment"
  }

  chart {
    chart_id = signalfx_single_value_chart.payments_request_rate.id
    width    = 3
    height   = 2
    row      = 0
    column   = 0
  }

  chart {
    chart_id = signalfx_single_value_chart.payments_error_rate.id
    width    = 3
    height   = 2
    row      = 0
    column   = 3
  }

  chart {
    chart_id = signalfx_single_value_chart.payments_p95_latency.id
    width    = 3
    height   = 2
    row      = 0
    column   = 6
  }

  chart {
    chart_id = signalfx_single_value_chart.payments_p99_latency.id
    width    = 3
    height   = 2
    row      = 0
    column   = 9
  }

  chart {
    chart_id = signalfx_time_chart.payments_request_rate_trend.id
    width    = 6
    height   = 3
    row      = 2
    column   = 0
  }

  chart {
    chart_id = signalfx_time_chart.payments_error_rate_trend.id
    width    = 6
    height   = 3
    row      = 2
    column   = 6
  }

  chart {
    chart_id = signalfx_time_chart.payments_latency_percentiles.id
    width    = 12
    height   = 3
    row      = 5
    column   = 0
  }

  chart {
    chart_id = signalfx_list_chart.payments_top_endpoints.id
    width    = 6
    height   = 3
    row      = 8
    column   = 0
  }

  chart {
    chart_id = signalfx_list_chart.payments_dependency_latency.id
    width    = 6
    height   = 3
    row      = 8
    column   = 6
  }
}