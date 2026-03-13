/*
 * ScratchBird C++ Client
 * Leak Detector Implementation
 * Copyright (c) 2025-2026 Dalton Calford
 */
#include <scratchbird/client/leak_detector.h>
#include <algorithm>
#include <iostream>
#include <sstream>
#include <unordered_map>

namespace scratchbird {
namespace client {

// CheckoutInfo implementation
CheckoutInfo::CheckoutInfo(bool capture_stack_trace, const std::map<std::string, std::string>& metadata)
    : checkout_time(std::chrono::steady_clock::now())
    , thread_id(std::this_thread::get_id())
    , stack_trace(capture_stack_trace ? "Stack trace captured" : "")
    , metadata(metadata)
{
}

std::chrono::milliseconds CheckoutInfo::GetHeldDuration() const {
    auto now = std::chrono::steady_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(now - checkout_time);
}

// LeakDetectionGuard implementation
LeakDetectionGuard::LeakDetectionGuard(LeakDetector* detector, const std::string& connection_id)
    : detector_(detector)
    , connection_id_(connection_id)
    , released_(false)
{
}

LeakDetectionGuard::~LeakDetectionGuard() {
    Release();
}

void LeakDetectionGuard::Release() {
    if (!released_.exchange(true)) {
        detector_->Checkin(connection_id_);
    }
}

// LeakDetector implementation
LeakDetector::LeakDetector(const sb_leak_detection_config& config)
    : config_(config)
    , running_(false)
    , stop_requested_(false)
{
}

LeakDetector::~LeakDetector() {
    Stop();
}

void LeakDetector::Start() {
    bool expected = false;
    if (running_.compare_exchange_strong(expected, true)) {
        stop_requested_ = false;
        worker_thread_ = std::thread(&LeakDetector::MonitorLoop, this);
    }
}

void LeakDetector::Stop() {
    bool expected = true;
    if (running_.compare_exchange_strong(expected, false)) {
        stop_requested_ = true;
        if (worker_thread_.joinable()) {
            worker_thread_.join();
        }
    }
}

std::unique_ptr<LeakDetectionGuard> LeakDetector::Checkout(const std::string& connection_id) {
    return Checkout(connection_id, {});
}

std::unique_ptr<LeakDetectionGuard> LeakDetector::Checkout(
    const std::string& connection_id,
    const std::map<std::string, std::string>& metadata) {
    
    std::lock_guard<std::mutex> lock(mutex_);
    checkouts_[connection_id] = std::make_unique<CheckoutInfo>(config_.capture_stack_trace, metadata);
    
    return std::make_unique<LeakDetectionGuard>(this, connection_id);
}

void LeakDetector::Checkin(const std::string& connection_id) {
    std::unique_ptr<CheckoutInfo> info;
    
    {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = checkouts_.find(connection_id);
        if (it != checkouts_.end()) {
            info = std::move(it->second);
            checkouts_.erase(it);
        }
    }
    
    if (info) {
        auto held_ms = static_cast<uint32_t>(info->GetHeldDuration().count());
        if (held_ms > config_.threshold_ms) {
            std::cout << "Connection " << connection_id << " held for " 
                      << held_ms << " ms (threshold: " << config_.threshold_ms 
                      << " ms) - returned\n";
        }
    }
}

size_t LeakDetector::GetActiveCount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return checkouts_.size();
}

LeakDetector::LeakStats LeakDetector::GetStats() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    size_t potential_leaks = 0;
    auto now = std::chrono::steady_clock::now();
    
    for (const auto& pair : checkouts_) {
        auto held_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            now - pair.second->checkout_time).count();
        if (held_ms > config_.threshold_ms) {
            potential_leaks++;
        }
    }
    
    return {checkouts_.size(), potential_leaks};
}

void LeakDetector::MonitorLoop() {
    while (!stop_requested_) {
        uint32_t remaining_ms = config_.check_interval_ms;
        while (!stop_requested_ && remaining_ms > 0) {
            const uint32_t slice = std::min<uint32_t>(remaining_ms, 100u);
            std::this_thread::sleep_for(std::chrono::milliseconds(slice));
            remaining_ms -= slice;
        }

        if (!stop_requested_) {
            CheckLeaks();
        }
    }
}

void LeakDetector::CheckLeaks() {
    std::lock_guard<std::mutex> lock(mutex_);
    auto now = std::chrono::steady_clock::now();
    
    for (const auto& pair : checkouts_) {
        auto held_ms = static_cast<uint32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(
            now - pair.second->checkout_time).count());
        
        if (held_ms > config_.threshold_ms) {
            LogLeak(pair.first, *pair.second, held_ms);
        }
    }
}

void LeakDetector::LogLeak(const std::string& conn_id, const CheckoutInfo& info, uint32_t held_ms) {
    std::stringstream ss;
    ss << "POSSIBLE CONNECTION LEAK: conn=" << conn_id 
       << ", held=" << held_ms << " ms"
       << ", threshold=" << config_.threshold_ms << " ms";
    
    switch (config_.log_level) {
        case sb_leak_log_level::SB_LEAK_LOG_DEBUG:
            break;
        case sb_leak_log_level::SB_LEAK_LOG_WARN:
            std::cout << "WARNING: " << ss.str() << "\n";
            break;
        case sb_leak_log_level::SB_LEAK_LOG_ERROR:
            std::cerr << "ERROR: " << ss.str() << "\n";
            break;
    }
}

} // namespace client
} // namespace scratchbird

// C API Implementation
namespace scratchbird {
extern "C" {

namespace {
using DetectorType = scratchbird::client::LeakDetector;
using GuardType = scratchbird::client::LeakDetectionGuard;

std::mutex g_c_api_guard_mutex;
std::unordered_map<DetectorType*,
                   std::unordered_map<std::string, std::unique_ptr<GuardType>>> g_c_api_guards;
}

sb_leak_detector* sb_leak_detector_create(const struct sb_leak_detection_config* config) {
    auto* detector = new scratchbird::client::LeakDetector(
        config ? *config : scratchbird::sb_leak_detection_config_default()
    );
    return reinterpret_cast<sb_leak_detector*>(detector);
}

void sb_leak_detector_destroy(sb_leak_detector* detector) {
    if (detector) {
        auto* typed = reinterpret_cast<scratchbird::client::LeakDetector*>(detector);
        {
            std::lock_guard<std::mutex> lock(g_c_api_guard_mutex);
            g_c_api_guards.erase(typed);
        }
        delete typed;
    }
}

void sb_leak_detector_start(sb_leak_detector* detector) {
    if (detector) {
        reinterpret_cast<scratchbird::client::LeakDetector*>(detector)->Start();
    }
}

void sb_leak_detector_stop(sb_leak_detector* detector) {
    if (detector) {
        reinterpret_cast<scratchbird::client::LeakDetector*>(detector)->Stop();
    }
}

void sb_leak_detector_checkout(sb_leak_detector* detector, const char* conn_id) {
    if (detector && conn_id) {
        auto* typed = reinterpret_cast<scratchbird::client::LeakDetector*>(detector);
        auto guard = typed->Checkout(conn_id);
        std::lock_guard<std::mutex> lock(g_c_api_guard_mutex);
        g_c_api_guards[typed][conn_id] = std::move(guard);
    }
}

void sb_leak_detector_checkout_with_metadata(sb_leak_detector* detector, const char* conn_id,
                                              const char** keys, const char** values, size_t count) {
    if (detector && conn_id) {
        auto* typed = reinterpret_cast<scratchbird::client::LeakDetector*>(detector);
        std::map<std::string, std::string> metadata;
        for (size_t i = 0; i < count; i++) {
            if (keys[i] && values[i]) {
                metadata[keys[i]] = values[i];
            }
        }
        auto guard = typed->Checkout(conn_id, metadata);
        std::lock_guard<std::mutex> lock(g_c_api_guard_mutex);
        g_c_api_guards[typed][conn_id] = std::move(guard);
    }
}

void sb_leak_detector_checkin(sb_leak_detector* detector, const char* conn_id) {
    if (detector && conn_id) {
        auto* typed = reinterpret_cast<scratchbird::client::LeakDetector*>(detector);
        std::unique_ptr<GuardType> guard;
        {
            std::lock_guard<std::mutex> lock(g_c_api_guard_mutex);
            auto detector_it = g_c_api_guards.find(typed);
            if (detector_it != g_c_api_guards.end()) {
                auto conn_it = detector_it->second.find(conn_id);
                if (conn_it != detector_it->second.end()) {
                    guard = std::move(conn_it->second);
                    detector_it->second.erase(conn_it);
                }
            }
        }
        if (guard) {
            guard->Release();
            return;
        }
        typed->Checkin(conn_id);
    }
}

size_t sb_leak_detector_get_active_count(sb_leak_detector* detector) {
    if (detector) {
        return reinterpret_cast<scratchbird::client::LeakDetector*>(detector)->GetActiveCount();
    }
    return 0;
}

} // extern "C"
} // namespace scratchbird
