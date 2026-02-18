#pragma once

#include <cstdint>

namespace scratchbird {
namespace server {

enum class IPCMethod : uint8_t {
    AUTO = 0,
    UNIX_SOCKET = 1,
    NAMED_PIPE = 2,
    TCP_LOCALHOST = 3
};

} // namespace server
} // namespace scratchbird
