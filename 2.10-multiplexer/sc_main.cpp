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

  sc_start();

  auto test = [&](auto a, auto b, auto c, auto d) {
	  x1.write(a);
	  x2.write(b);
	  s.write(c);

	  sc_start(1, SC_NS);
	  assert(f.read() == d);
  };

  test(0, 0, 0, 0);
  test(0, 0, 1, 0);
  test(0, 1, 0, 0);
  test(0, 1, 1, 1);
  test(1, 0, 0, 1);
  test(1, 0, 1, 0);
  test(1, 1, 0, 1);
  test(1, 1, 1, 1);

  return 0;
}
