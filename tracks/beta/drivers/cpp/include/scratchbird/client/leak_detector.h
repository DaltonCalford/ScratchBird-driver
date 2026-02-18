/*
 * ScratchBird C++ Client
 * Connection Leak Detector
 * Copyright (c) 2025-2026 Dalton Calford
 */
#ifndef SB_CLIENT_LEAK_DETECTOR_H
#define SB_CLIENT_LEAK_DETECTOR_H

#include <scratchbird/client/scratchbird_client.h>
#include <atomic>
#include <chrono>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

namespace scratchbird {

enum class sb_leak_log_level {
    SB_LEAK_LOG_DEBUG,
    SB_LEAK_LOG_WARN,
    SB_LEAK_LOG_ERROR
};

struct sb_leak_detection_config {
    uint32_t threshold_ms;          // Default: 30000 (30 seconds)
    bool capture_stack_trace;       // Default: false
    uint32_t check_interval_ms;     // Default: 10000 (10 seconds)
    sb_leak_log_level log_level;    // Default: SB_LEAK_LOG_WARN
};

static inline struct sb_leak_detection_config sb_leak_detection_config_default() {
    return {30000, false, 10000, sb_leak_log_level::SB_LEAK_LOG_WARN};
}

// Opaque leak detector handle
typedef struct sb_leak_detector sb_leak_detector;

#ifdef __cplusplus
extern "C" {
#endif

// Create/destroy leak detector
sb_leak_detector* sb_leak_detector_create(const struct sb_leak_detection_config* config);
void sb_leak_detector_destroy(sb_leak_detector* detector);

// Start/stop monitoring
void sb_leak_detector_start(sb_leak_detector* detector);
void sb_leak_detector_stop(sb_leak_detector* detector);

// Checkout/checkin
void sb_leak_detector_checkout(sb_leak_detector* detector, const char* conn_id);
void sb_leak_detector_checkout_with_metadata(sb_leak_detector* detector, const char* conn_id, 
                                              const char** keys, const char** values, size_t count);
void sb_leak_detector_checkin(sb_leak_detector* detector, const char* conn_id);

// Statistics
size_t sb_leak_detector_get_active_count(sb_leak_detector* detector);

#ifdef __cplusplus
}
#endif

// C++ API
#ifdef __cplusplus

namespace client {

class LeakDetector;

class LeakDetectionGuard {
public:
    LeakDetectionGuard(LeakDetector* detector, const std::string& connection_id);
    ~LeakDetectionGuard();
    
    void Release();
    
private:
    LeakDetector* detector_;
    std::string connection_id_;
    std::atomic<bool> released_;
};

class CheckoutInfo {
public:
    CheckoutInfo(bool capture_stack_trace, const std::map<std::string, std::string>& metadata);
    
    std::chrono::milliseconds GetHeldDuration() const;
    
    const std::chrono::steady_clock::time_point checkout_time;
    const std::thread::id thread_id;
    const std::string stack_trace;
    const std::map<std::string, std::string> metadata;
};

class LeakDetector {
public:
    explicit LeakDetector(const sb_leak_detection_config& config = sb_leak_detection_config_default());
    ~LeakDetector();
    
    // Non-copyable
    LeakDetector(const LeakDetector&) = delete;
    LeakDetector& operator=(const LeakDetector&) = delete;
    
    void Start();
    void Stop();
    
    // Checkout with RAII guard
    std::unique_ptr<LeakDetectionGuard> Checkout(const std::string& connection_id);
    std::unique_ptr<LeakDetectionGuard> Checkout(const std::string& connection_id,
                                                  const std::map<std::string, std::string>& metadata);
    void Checkin(const std::string& connection_id);
    
    // Statistics
    size_t GetActiveCount() const;
    struct LeakStats {
        size_t active_checkouts;
        size_t potential_leaks;
    };
    LeakStats GetStats() const;
    
private:
    void MonitorLoop();
    void CheckLeaks();
    void LogLeak(const std::string& conn_id, const CheckoutInfo& info, uint32_t held_ms);
    
    sb_leak_detection_config config_;
    std::map<std::string, std::unique_ptr<CheckoutInfo>> checkouts_;
    mutable std::mutex mutex_;
    std::thread worker_thread_;
    std::atomic<bool> running_;
    std::atomic<bool> stop_requested_;
};

} // namespace client
} // namespace scratchbird

#endif // __cplusplus

#endif // SB_CLIENT_LEAK_DETECTOR_H
