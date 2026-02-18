# ScratchBird Mojo Driver
# Keepalive Manager - Prevents connection timeouts
# Copyright (c) 2025-2026 Dalton Calford

from time import time, sleep
from threading import Thread, Lock

@value
struct KeepaliveConfig:
    var interval_ms: Int
    var max_idle_before_check_ms: Int
    var validation_timeout_ms: Int
    
    fn __init__(inout self):
        self.interval_ms = 120000
        self.max_idle_before_check_ms = 600000
        self.validation_timeout_ms = 5000
    
    fn __init__(inout self, interval: Int, max_idle: Int, timeout: Int):
        self.interval_ms = interval
        self.max_idle_before_check_ms = max_idle
        self.validation_timeout_ms = timeout

struct KeepaliveTracker:
    var config: KeepaliveConfig
    var last_activity: Float64
    var lock: Lock
    
    fn __init__(inout self, config: KeepaliveConfig):
        self.config = config
        self.last_activity = time()
        self.lock = Lock()
    
    fn mark_active(inout self):
        with self.lock:
            self.last_activity = time()
    
    fn needs_validation(self) -> Bool:
        var idle_ms = (time() - self.last_activity) * 1000
        return idle_ms > self.config.max_idle_before_check_ms
    
    fn idle_duration_ms(self) -> Int:
        return int((time() - self.last_activity) * 1000)

alias PingerFn = fn() -> Bool

struct ConnectionInfo:
    var connection: String
    var pinger: PingerFn
    
    fn __init__(inout self, conn: String, pinger: PingerFn):
        self.connection = conn
        self.pinger = pinger

class KeepaliveManager:
    var config: KeepaliveConfig
    var trackers: Dict[String, KeepaliveTracker]
    var connections: Dict[String, ConnectionInfo]
    var running: Bool
    var thread: Optional[Thread]
    
    fn __init__(inout self, config: KeepaliveConfig = KeepaliveConfig()):
        self.config = config
        self.trackers = Dict[String, KeepaliveTracker]()
        self.connections = Dict[String, ConnectionInfo]()
        self.running = False
        self.thread = None
    
    fn start(inout self):
        if self.running:
            return
        self.running = True
        # Start monitoring thread
        self.thread = Thread(target=self._monitor_loop)
    
    fn stop(inout self):
        self.running = False
        if self.thread:
            # Wait for thread
            pass
    
    fn register(inout self, conn_id: String, conn: String, pinger: PingerFn) -> KeepaliveTracker:
        var tracker = KeepaliveTracker(self.config)
        self.trackers[conn_id] = tracker
        self.connections[conn_id] = ConnectionInfo(conn, pinger)
        return tracker
    
    fn unregister(inout self, conn_id: String):
        if conn_id in self.trackers:
            del self.trackers[conn_id]
        if conn_id in self.connections:
            del self.connections[conn_id]
    
    fn get_monitored_count(self) -> Int:
        return len(self.trackers)
    
    fn _monitor_loop(self):
        while self.running:
            sleep(self.config.interval_ms / 1000.0)
            self._check_connections()
    
    fn _check_connections(inout self):
        for conn_id in self.trackers:
            var tracker = self.trackers[conn_id]
            if tracker.needs_validation():
                if conn_id in self.connections:
                    var conn_info = self.connections[conn_id]
                    # Validate connection
                    var is_healthy = conn_info.pinger()
                    if is_healthy:
                        tracker.mark_active()
