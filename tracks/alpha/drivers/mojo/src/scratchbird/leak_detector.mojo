# ScratchBird Mojo Driver - Connection Leak Detector
# Copyright (c) 2025-2026 Dalton Calford

from time import time, sleep
from threading import Lock

alias LeakLogLevel = Int
alias LOG_DEBUG = 0
alias LOG_WARN = 1
alias LOG_ERROR = 2

@value
struct LeakDetectionConfig:
    var threshold_ms: Int
    var capture_stack_trace: Bool
    var check_interval_ms: Int
    var log_level: LeakLogLevel
    
    fn __init__(inout self):
        self.threshold_ms = 30000
        self.capture_stack_trace = False
        self.check_interval_ms = 10000
        self.log_level = LOG_WARN

struct CheckoutInfo:
    var checkout_time: Float64
    var thread_id: Int
    var metadata: Dict[String, String]
    
    fn __init__(inout self, metadata: Dict[String, String]):
        self.checkout_time = time()
        self.thread_id = 0  # Current thread
        self.metadata = metadata
    
    fn held_duration_ms(self) -> Int:
        return int((time() - self.checkout_time) * 1000)

struct LeakDetectionGuard:
    var detector: Pointer[LeakDetector]
    var connection_id: String
    var released: Bool
    
    fn __init__(inout self, detector: Pointer[LeakDetector], conn_id: String):
        self.detector = detector
        self.connection_id = conn_id
        self.released = False
    
    fn __del__(inout self):
        self.release()
    
    fn release(inout self):
        if not self.released:
            self.detector.load().checkin(self.connection_id)
            self.released = True

class LeakDetector:
    var config: LeakDetectionConfig
    var checkouts: Dict[String, CheckoutInfo]
    var lock: Lock
    var running: Bool
    
    fn __init__(inout self, config: LeakDetectionConfig = LeakDetectionConfig()):
        self.config = config
        self.checkouts = Dict[String, CheckoutInfo]()
        self.lock = Lock()
        self.running = False
    
    fn start(inout self):
        self.running = True
    
    fn stop(inout self):
        self.running = False
    
    fn checkout(inout self, conn_id: String, metadata: Dict[String, String]) -> LeakDetectionGuard:
        var info = CheckoutInfo(metadata)
        with self.lock:
            self.checkouts[conn_id] = info
        return LeakDetectionGuard(Pointer.address_of(self), conn_id)
    
    fn checkin(inout self, conn_id: String):
        with self.lock:
            if conn_id in self.checkouts:
                var info = self.checkouts[conn_id]
                del self.checkouts[conn_id]
                if info.held_duration_ms() > self.config.threshold_ms:
                    print("Connection held too long: " + conn_id)
    
    fn get_active_count(self) -> Int:
        with self.lock:
            return len(self.checkouts)
    
    fn check_leaks(inout self):
        with self.lock:
            for conn_id in self.checkouts:
                var info = self.checkouts[conn_id]
                if info.held_duration_ms() > self.config.threshold_ms:
                    self._log_leak(conn_id, info)
    
    fn _log_leak(self, conn_id: String, info: CheckoutInfo):
        print("POSSIBLE CONNECTION LEAK: conn=" + conn_id + ", held=" + str(info.held_duration_ms()) + "ms")
