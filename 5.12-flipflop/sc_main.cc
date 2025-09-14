#include "Vflipflop.h"

using namespace sc_core;

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vflipflop f{"main"};

  sc_clock clk{"clk", 10, SC_NS, 0.5, 3, SC_NS, true};
  sc_signal<bool> d, q;
  f.clk(clk);
  f.d(d);
  f.q(q);

  auto test = [&](auto val) {
          d.write(val);
          sc_start(9, SC_NS);
          assert(q.read() == val);
  };

  test(0);
  test(1);
  test(1);
  test(0);

  return 0;
}
