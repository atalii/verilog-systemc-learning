#include <optional>

#include "Vcache.h"

using namespace sc_core;

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vcache bank{"main"};

  sc_signal<bool> read, write, hit;
  sc_signal<uint32_t> in_val, out_val, in_addr;
  sc_clock clock;

  bank.read(read);
  bank.write(write);
  bank.hit(hit);
  bank.in_val(in_val);
  bank.out_val(out_val);
  bank.in_addr(in_addr);
  bank.clock(clock);

  auto put = [&](uint32_t addr, uint32_t val) {
    read.write(false);
    write.write(true);
    in_addr.write(addr);
    in_val.write(val);

    do {
      sc_start(1, SC_NS);
    } while (!hit.read());
  };

  auto get = [&](uint32_t addr) -> std::optional<uint32_t> {
    read.write(true);
    write.write(false);
    in_addr.write(addr);
    sc_start(1, SC_NS);

    return hit.read() ? std::optional{out_val.read()} : std::nullopt;
  };

  // Address '0' is cached by default, so this'll work even without eviction
  // logic!
  put(0, 1);
  assert(get(0) == std::optional{1});

  put(1, 1);
  assert(get(1) == std::optional{1});

  put(1, 2);
  assert(get(1) == std::optional{2});

  put(2, 0);
  assert(get(2) == std::optional{0});

  put(2, 1);
  assert(get(2) == std::optional{1});

  put(3, 10);
  assert(get(3) == std::optional{10});
  assert(get(1) == std::optional{2} || get(2) == std::optional{1});

  return 0;
}
