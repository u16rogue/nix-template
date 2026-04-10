#include <print>
#include <span>

int main(const int argc, const char* const* argv) noexcept {
    if (argc <= 1) {
        return 1;
    }

    const std::span<const char* const> args = std::span(argv + 1, static_cast<std::size_t>(argc) - 1);

    std::print("hello, world.");

    return 0;
}
