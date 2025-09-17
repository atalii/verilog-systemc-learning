#include <optional>

#include "Vcacheline.h"

using namespace sc_core;

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vcacheline line{"main"};

  sc_signal<bool> read, write, hit;
  sc_signal<uint32_t> in_val, out_val, in_addr;
  sc_clock clock;

  line.read(read);
  line.write(write);
  line.hit(hit);
  line.in_val(in_val);
  line.out_val(out_val);
  line.in_addr(in_addr);
  line.clock(clock);

  auto put = [&](uint32_t addr, uint32_t val) {
    read.write(false);
    write.write(true);
    in_addr.write(addr);
    in_val.write(val);

    sc_start(1, SC_NS);
  };

  auto get = [&](uint32_t addr) -> std::optional<uint32_t> {
    read.write(true);
    write.write(false);
    in_addr.write(addr);
    sc_start(1, SC_NS);

    return hit.read() ? std::optional{out_val.read()} : std::nullopt;
  };

  // Just some test values.

  // On our first access, the line will be ready to evict the (0, 0) (addr, val)
  // pair inside, so it'll store our 1.
  put(1, 1);
  assert(get(1) == std::optional{1});

  // This will succeed as well.
  put(1, 2);
  assert(get(1) == std::optional{2});

  // This will fail and set the clock counter to 0.
  put(2, 0);
  assert(get(2) == std::nullopt);

  // But trying again will succeed!
  put(2, 0);
  assert(get(2) == std::optional{0});

  return 0;
}
