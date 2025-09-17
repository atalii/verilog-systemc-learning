#include <optional>

#include "Vcacheline.h"

using namespace sc_core;

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vcacheline line{"main"};

  sc_signal<bool> read, write, force_write, hit;
  sc_signal<uint32_t> in_val, out_val, in_addr;
  sc_clock clock;

  line.read(read);
  line.write(write);
  line.force_write(force_write);
  line.hit(hit);
  line.in_val(in_val);
  line.out_val(out_val);
  line.in_addr(in_addr);
  line.clock(clock);

  auto put = [&](uint32_t addr, uint32_t val, bool force = false) {
    read.write(false);
    write.write(true);
    force_write.write(force);
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

  put(1, 1);
  assert(get(1) == std::nullopt);

  put(1, 1, true);
  assert(get(1) == std::optional{1});
  assert(get(2) == std::nullopt);
  put(1, 2);
  assert(get(1) == std::optional{2});
  assert(get(1) == std::optional{2});

  return 0;
}
