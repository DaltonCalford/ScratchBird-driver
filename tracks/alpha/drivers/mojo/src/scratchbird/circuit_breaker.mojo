# ScratchBird Mojo Driver - Circuit Breaker
# Copyright (c) 2025-2026 Dalton Calford

from time import time
from threading import Lock

alias CircuitState = Int
alias STATE_CLOSED = 0
alias STATE_OPEN = 1
alias STATE_HALF_OPEN = 2

@value
struct CircuitBreakerConfig:
    var failure_threshold: Int
    var recovery_timeout_ms: Int
    var success_threshold: Int
    var half_open_max_requests: Int
    
    fn __init__(inout self):
        self.failure_threshold = 5
        self.recovery_timeout_ms = 30000
        self.success_threshold = 3
        self.half_open_max_requests = 10

struct CircuitBreakerError:
    var message: String
    
    fn __init__(inout self, msg: String = "Circuit breaker is OPEN"):
        self.message = msg

class CircuitBreaker:
    var config: CircuitBreakerConfig
    var name: String
    var state: CircuitState
    var failure_count: Int
    var success_count: Int
    var half_open_requests: Int
    var last_failure_time: Float64
    var lock: Lock
    
    fn __init__(inout self, config: CircuitBreakerConfig = CircuitBreakerConfig(), name: String = "default"):
        self.config = config
        self.name = name
        self.state = STATE_CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.half_open_requests = 0
        self.last_failure_time = 0
        self.lock = Lock()
    
    fn get_state(self) -> CircuitState:
        with self.lock:
            return self.state
    
    fn allow_request(inout self) -> Bool:
        with self.lock:
            if self.state == STATE_CLOSED:
                return True
            elif self.state == STATE_OPEN:
                if self.last_failure_time > 0 and (time() - self.last_failure_time) * 1000 >= self.config.recovery_timeout_ms:
                    self.state = STATE_HALF_OPEN
                    self.failure_count = 0
                    self.success_count = 0
                    self.half_open_requests = 0
                    return self._allow_half_open()
                return False
            else:  # STATE_HALF_OPEN
                return self._allow_half_open()
        return False
    
    fn _allow_half_open(inout self) -> Bool:
        if self.half_open_requests < self.config.half_open_max_requests:
            self.half_open_requests += 1
            return True
        return False
    
    fn record_success(inout self):
        with self.lock:
            if self.state == STATE_CLOSED:
                self.failure_count = 0
            elif self.state == STATE_HALF_OPEN:
                self.half_open_requests -= 1
                self.success_count += 1
                if self.success_count >= self.config.success_threshold:
                    self.state = STATE_CLOSED
                    self.failure_count = 0
                    self.success_count = 0
    
    fn record_failure(inout self):
        with self.lock:
            if self.state == STATE_CLOSED:
                self.failure_count += 1
                if self.failure_count >= self.config.failure_threshold:
                    self.state = STATE_OPEN
                    self.last_failure_time = time()
            elif self.state == STATE_HALF_OPEN:
                self.half_open_requests -= 1
                self.state = STATE_OPEN
                self.last_failure_time = time()
            elif self.state == STATE_OPEN:
                self.last_failure_time = time()
    
    fn reset(inout self):
        with self.lock:
            self.state = STATE_CLOSED
            self.failure_count = 0
            self.success_count = 0
            self.half_open_requests = 0
            self.last_failure_time = 0
