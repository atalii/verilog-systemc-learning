#include "Vmultiplexer.h"

using namespace sc_core;

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vmultiplexer mult{"main"};

  sc_signal<bool> x1, x2, s, f;

  mult.x1(x1);
  mult.x2(x2);
  mult.s(s);
  mult.f(f);

  x1.write(1);
  x2.write(0);
  s.write(1);

  sc_start();
  printf("%b\n", f.read());
  return 0;
}
