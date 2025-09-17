#include "Vcacheline.h"

using namespace sc_core;

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vcacheline line{"main"};

  sc_signal<bool> read, write, clock, force_write, hit;
  sc_signal<uint32_t> in_val, out_val, in_addr;

  line.read(read);
  line.write(write);
  line.clock(clock);
  line.force_write(force_write);
  line.hit(hit);
  line.in_val(in_val);
  line.out_val(out_val);
  line.in_addr(in_addr);

  return 0;
}
