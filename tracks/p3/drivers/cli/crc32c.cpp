#include <cstddef>
#include <cstdint>

namespace scratchbird {
namespace core {

uint32_t crc32cCompute(const uint8_t* data, size_t length, uint32_t initial) {
    uint32_t crc = ~initial;
    for (size_t i = 0; i < length; ++i) {
        crc ^= data[i];
        for (int bit = 0; bit < 8; ++bit) {
            if (crc & 1u) {
                crc = (crc >> 1u) ^ 0x82F63B78u;
            } else {
                crc >>= 1u;
            }
        }
    }
    return ~crc;
}

} // namespace core
} // namespace scratchbird
