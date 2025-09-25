#include <gtest/gtest.h>
#include <optional>

#include "Vcache.h"

using namespace sc_core;

class CacheTest : public testing::Test {
private:
  static sc_signal<bool> read, write, hit;
  static sc_signal<uint32_t> in_val, out_val, in_addr;
  static sc_clock clock;
  static Vcache bank;

protected:
  CacheTest() = default;

  static void SetUpTestSuite() {
    bank.read(read);
    bank.write(write);
    bank.hit(hit);
    bank.in_val(in_val);
    bank.out_val(out_val);
    bank.in_addr(in_addr);
    bank.clock(clock);
  }

public:
  void put(uint32_t addr, uint32_t val) {
    read.write(false);
    write.write(true);
    in_addr.write(addr);
    in_val.write(val);

    do {
      sc_start(1, SC_NS);
    } while (!hit.read());
  }

  std::optional<uint32_t> get(uint32_t addr) {
    read.write(true);
    write.write(false);
    in_addr.write(addr);
    sc_start(1, SC_NS);

    return hit.read() ? std::optional{out_val.read()} : std::nullopt;
  }
};

sc_signal<bool> CacheTest::read, CacheTest::write, CacheTest::hit;
sc_signal<uint32_t> CacheTest::in_val, CacheTest::out_val, CacheTest::in_addr;
sc_clock CacheTest::clock;
Vcache CacheTest::bank{"bank"};

// Arbitrarily check through the first 1024 addresses.
//
// XXX: GTest runs tests in the order they find them, which happens to put
// this first. Since we also don't run tests in parallel at any point, this is
// okay. If there's a better way to ensure that this invariant is held at
// object construction, it would be good to use here.
//
// Note that we can't just use one copy of the class per instance (i.e., the
// class needs to have static member variables) because SystemC doesn't allow
// us to run multiple simulations or restart an existing simulation from
// within the process.
TEST_F(CacheTest, startsEmpty) {
  for (uint32_t addr = 0; addr < 1024; addr++)
    ASSERT_FALSE(get(addr));
}

TEST_F(CacheTest, endToEnd) {
  assert(get(0) == std::nullopt);
  put(0, 0);
  assert(get(0) == std::optional{0});

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

  assert(get(100) == std::nullopt);
}

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  testing::InitGoogleTest();
  return RUN_ALL_TESTS();
}