# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

from collections import List
import keepalive
import pipeline
import telemetry


fn _require(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


fn main() raises:
    var keepalive_cfg = keepalive.KeepaliveConfig(100, 1000, 50)
    var tracker = keepalive.KeepaliveTracker(keepalive_cfg)
    tracker.mark_active(10)
    _require(not tracker.needs_validation(500), "keepalive tracker should not validate early")
    _require(tracker.needs_validation(1200), "keepalive tracker should validate after idle budget")

    var manager = keepalive.KeepaliveManager(keepalive_cfg)
    manager.start()
    _ = manager.register("conn_a", 0)
    _ = manager.register("conn_b", 500)
    var due = manager.due_for_validation(1600)
    _require(len(due) == 2 and due[0] == "conn_a" and due[1] == "conn_b", "keepalive manager due set mismatch")
    manager.mark_active("conn_a", 1700)
    _require(manager.validation_count("conn_a") == 1, "keepalive validation counter mismatch")
    manager.unregister("conn_b")
    _require(manager.get_monitored_count() == 1, "keepalive unregister mismatch")
    manager.stop()

    var telemetry_cfg = telemetry.TelemetryConfig()
    telemetry_cfg.slow_query_threshold_ms = 5
    var collector = telemetry.TelemetryCollector(telemetry_cfg)
    var fast_span = collector.start_span("query", 100)
    collector.end_span(fast_span, 102, True)
    var slow_span = collector.start_span("query", 200)
    collector.end_span(slow_span, 220, False)
    _require(len(collector.get_metrics()) >= 4, "telemetry metrics should be populated")
    _require(len(collector.get_slow_queries()) == 1, "telemetry slow-query log should record one span")
    var prometheus = collector.export_prometheus_metrics()
    _require("scratchbird_queries_total" in prometheus, "prometheus export missing query counter")

    var pipeline_cfg = pipeline.PipelineConfig()
    pipeline_cfg.max_in_flight = 3
    pipeline_cfg.auto_flush = False
    pipeline_cfg.auto_flush_threshold = 2
    var query_pipeline = pipeline.QueryPipeline(pipeline_cfg)
    query_pipeline.start("conn_a")
    var params = List[String]()
    params.append("1")
    _require(query_pipeline.queue("SELECT $1", params), "pipeline queue should accept first request")
    _require(query_pipeline.queue("SELECT $1", params), "pipeline queue should accept second request")
    _require(query_pipeline.pending_count() == 2, "pipeline pending count mismatch before flush")
    query_pipeline.flush()
    _require(query_pipeline.pending_count() == 0, "pipeline pending count mismatch after flush")
    _require(query_pipeline.completed_count() == 2, "pipeline completed count mismatch")
    _require(query_pipeline.failed_count() == 0, "pipeline failed count mismatch")
    query_pipeline.stop()

    var builder = pipeline.PipelineBuilder()
    builder.add("SELECT 1")
    builder.add("SELECT 2")
    var batch = builder.build()
    _require(len(batch) == 2, "pipeline builder batch size mismatch")

    print("Mojo lifecycle scaffold tests OK")
