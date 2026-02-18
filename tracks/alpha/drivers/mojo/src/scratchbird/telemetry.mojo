# ScratchBird Mojo Driver - OpenTelemetry Telemetry
# Copyright (c) 2025-2026 Dalton Calford

from time import time
from threading import Lock
from collections import Dict, Optional
import random
import string


@value
struct TelemetryConfig:
    var enable_tracing: Bool
    var enable_metrics: Bool
    var enable_slow_query_log: Bool
    var slow_query_threshold_ms: Int
    var sanitize_queries: Bool
    var sample_rate: Float64
    
    fn __init__(inout self):
        self.enable_tracing = True
        self.enable_metrics = True
        self.enable_slow_query_log = True
        self.slow_query_threshold_ms = 1000
        self.sanitize_queries = True
        self.sample_rate = 1.0


struct SpanContext:
    var trace_id: String
    var span_id: String
    var parent_span_id: Optional[String]
    var span_name: String
    var start_time: Float64
    var attributes: Dict[String, String]
    
    fn __init__(inout self, name: String):
        self.trace_id = Self._generate_id(16)
        self.span_id = Self._generate_id(8)
        self.parent_span_id = None
        self.span_name = name
        self.start_time = time()
        self.attributes = Dict[String, String]()
    
    fn __init__(inout self, name: String, parent: SpanContext):
        self.trace_id = parent.trace_id
        self.span_id = Self._generate_id(8)
        self.parent_span_id = parent.span_id
        self.span_name = name
        self.start_time = time()
        self.attributes = Dict[String, String]()
    
    fn with_attribute(inout self, key: String, value: String) -> Self:
        self.attributes[key] = value
        return self
    
    fn elapsed_ms(self) -> Int:
        return int((time() - self.start_time) * 1000)
    
    @staticmethod
    fn _generate_id(length: Int) -> String:
        var chars = String("0123456789abcdef")
        var result = String()
        for _ in range(length * 2):
            result += chars[int(random.random() * 16)]
        return result


struct LatencyHistogram:
    var ms_0_10: Int
    var ms_10_100: Int
    var ms_100_1000: Int
    var ms_1000_10000: Int
    var ms_over_10000: Int
    var _lock: Lock
    
    fn __init__(inout self):
        self.ms_0_10 = 0
        self.ms_10_100 = 0
        self.ms_100_1000 = 0
        self.ms_1000_10000 = 0
        self.ms_over_10000 = 0
        self._lock = Lock()
    
    fn record(inout self, duration_ms: Int):
        with self._lock:
            if duration_ms <= 10:
                self.ms_0_10 += 1
            elif duration_ms <= 100:
                self.ms_10_100 += 1
            elif duration_ms <= 1000:
                self.ms_100_1000 += 1
            elif duration_ms <= 10000:
                self.ms_1000_10000 += 1
            else:
                self.ms_over_10000 += 1
    
    fn to_string(self) -> String:
        return String("{" + 
            "ms_0_10: " + str(self.ms_0_10) + 
            ", ms_10_100: " + str(self.ms_10_100) +
            ", ms_100_1000: " + str(self.ms_100_1000) +
            ", ms_1000_10000: " + str(self.ms_1000_10000) +
            ", ms_over_10000: " + str(self.ms_over_10000) + "}")


struct OperationMetrics:
    var count: Int
    var total_time_ms: Int
    var avg_time_ms: Int
    var error_count: Int
    var _lock: Lock
    
    fn __init__(inout self):
        self.count = 0
        self.total_time_ms = 0
        self.avg_time_ms = 0
        self.error_count = 0
        self._lock = Lock()
    
    fn record(inout self, duration_ms: Int, success: Bool):
        with self._lock:
            self.count += 1
            self.total_time_ms += duration_ms
            self.avg_time_ms = self.total_time_ms // self.count
            if not success:
                self.error_count += 1


struct SlowQueryLog:
    var trace_id: String
    var span_name: String
    var duration_ms: Int
    var timestamp: Float64
    var attributes: Dict[String, String]
    
    fn __init__(inout self, trace_id: String, span_name: String, duration_ms: Int, attrs: Dict[String, String]):
        self.trace_id = trace_id
        self.span_name = span_name
        self.duration_ms = duration_ms
        self.timestamp = time()
        self.attributes = attrs


class TelemetryCollector:
    var config: TelemetryConfig
    var _spans: DynamicVector[SpanContext]
    var _spans_lock: Lock
    var _total_queries: Int
    var _successful_queries: Int
    var _failed_queries: Int
    var _total_query_time_ms: Int
    var _metrics_lock: Lock
    var _histogram: LatencyHistogram
    var _operation_metrics: Dict[String, OperationMetrics]
    var _op_metrics_lock: Lock
    var _slow_queries: DynamicVector[SlowQueryLog]
    var _slow_queries_lock: Lock
    
    fn __init__(inout self, config: TelemetryConfig = TelemetryConfig()):
        self.config = config
        self._spans = DynamicVector[SpanContext]()
        self._spans_lock = Lock()
        self._total_queries = 0
        self._successful_queries = 0
        self._failed_queries = 0
        self._total_query_time_ms = 0
        self._metrics_lock = Lock()
        self._histogram = LatencyHistogram()
        self._operation_metrics = Dict[String, OperationMetrics]()
        self._op_metrics_lock = Lock()
        self._slow_queries = DynamicVector[SlowQueryLog]()
        self._slow_queries_lock = Lock()
    
    fn start_span(inout self, name: String) -> Optional[SpanContext]:
        if not self.config.enable_tracing:
            return None
        
        # Sample rate check
        if random.random_float64() > self.config.sample_rate:
            return None
        
        var span = SpanContext(name)
        
        with self._spans_lock:
            self._spans.append(span)
            if len(self._spans) > 1000:
                # Remove oldest - shift elements
                pass
        
        return span
    
    fn end_span(inout self, span: Optional[SpanContext], success: Bool = True):
        if not span or not self.config.enable_tracing:
            return
        
        var duration_ms = span.value().elapsed_ms()
        self._record_query_metrics(span.value().span_name, duration_ms, success)
        
        if self.config.enable_slow_query_log and duration_ms > self.config.slow_query_threshold_ms:
            self._record_slow_query(span.value(), duration_ms)
    
    fn _record_query_metrics(inout self, operation: String, duration_ms: Int, success: Bool):
        if not self.config.enable_metrics:
            return
        
        with self._metrics_lock:
            self._total_queries += 1
            if success:
                self._successful_queries += 1
            else:
                self._failed_queries += 1
            self._total_query_time_ms += duration_ms
        
        self._histogram.record(duration_ms)
        
        # Per-operation metrics
        with self._op_metrics_lock:
            if operation not in self._operation_metrics:
                self._operation_metrics[operation] = OperationMetrics()
            self._operation_metrics[operation].record(duration_ms, success)
    
    fn _record_slow_query(inout self, span: SpanContext, duration_ms: Int):
        var log = SlowQueryLog(span.trace_id, span.span_name, duration_ms, span.attributes)
        
        with self._slow_queries_lock:
            self._slow_queries.append(log)
            if len(self._slow_queries) > 100:
                # Remove oldest
                pass
    
    fn get_metrics(inout self) -> Dict[String, String]:
        var result = Dict[String, String]()
        
        with self._metrics_lock:
            result["total_queries"] = str(self._total_queries)
            result["successful_queries"] = str(self._successful_queries)
            result["failed_queries"] = str(self._failed_queries)
            result["total_query_time_ms"] = str(self._total_query_time_ms)
        
        result["latency_histogram"] = self._histogram.to_string()
        return result
    
    fn get_slow_queries(inout self) -> DynamicVector[SlowQueryLog]:
        with self._slow_queries_lock:
            return self._slow_queries
    
    @staticmethod
    fn sanitize_query(sql: String) -> String:
        # Simple sanitization - replace quoted strings
        # In a full implementation, use proper regex
        return sql  # Placeholder
    
    fn export_prometheus_metrics(inout self) -> String:
        var m = self.get_metrics()
        var result = String()
        
        result += "# HELP scratchbird_queries_total Total number of queries\n"
        result += "# TYPE scratchbird_queries_total counter\n"
        result += "scratchbird_queries_total " + m["total_queries"] + "\n"
        result += "# HELP scratchbird_query_duration_ms Query duration histogram\n"
        result += "# TYPE scratchbird_query_duration_ms histogram\n"
        result += "scratchbird_query_duration_ms_bucket{le=\"10\"} " + str(self._histogram.ms_0_10) + "\n"
        result += "scratchbird_query_duration_ms_bucket{le=\"100\"} " + str(self._histogram.ms_0_10 + self._histogram.ms_10_100) + "\n"
        result += "scratchbird_query_duration_ms_bucket{le=\"1000\"} " + str(self._histogram.ms_0_10 + self._histogram.ms_10_100 + self._histogram.ms_100_1000) + "\n"
        
        return result


struct TelemetrySpanGuard:
    var collector: Pointer[TelemetryCollector]
    var span: SpanContext
    var success: Bool
    
    fn __init__(inout self, collector: Pointer[TelemetryCollector], span: SpanContext):
        self.collector = collector
        self.span = span
        self.success = True
    
    fn mark_failed(inout self):
        self.success = False
    
    fn finish(inout self):
        self.collector.load().end_span(self.span, self.success)
