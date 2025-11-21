#include <gtest/gtest.h>
#include <optional>

#include "Vcache.h"
#include "Vbus.h"

using namespace sc_core;

struct BusTest : public testing::Test {
  static sc_clock clock;
  BusTest() = default;
  static void SetUpTestSuite() {
  }

};

struct CacheTest : public testing::Test {
  static sc_signal<bool> read, write, hit;
  static sc_signal<uint32_t> in_val, out_val, in_addr;
  static sc_clock clock;
  static Vcache bank;
  static sc_signal<uint32_t> messages[4];
  static sc_signal<bool> bus_write[4];
  static sc_signal<uint32_t> message;
  static sc_signal<bool> sent[4];
  static Vbus bus;


  CacheTest() = default;

  static void SetUpTestSuite() {
    bus.clock(clock);
    bus.message(message);
    for (size_t i = 0; i < 4; i++) {
      bus.write[i](bus_write[i]);
      bus.messages[i](messages[i]);
      bus.sent[i](sent[i]);
    }
    
    bank.read(CacheTest::read);
    bank.write(CacheTest::write);
    bank.hit(CacheTest::hit);
    bank.in_val(CacheTest::in_val);
    bank.out_val(CacheTest::out_val);
    bank.in_addr(CacheTest::in_addr);
    bank.clock(CacheTest::clock);

  }

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

  void sendSync(size_t client, uint32_t val) {
    messages[client].write(val);
    bus_write[client].write(1);
    do {
      sc_start(1, SC_NS);
    } while (!sent[client].read());

    bus_write[client].write(0);
  }
};

sc_signal<bool> CacheTest::read, CacheTest::write, CacheTest::hit;
sc_signal<uint32_t> CacheTest::in_val, CacheTest::out_val, CacheTest::in_addr;
sc_clock CacheTest::clock;
Vcache CacheTest::bank{"bank"};

sc_signal<uint32_t> CacheTest::messages[4];
sc_signal<bool> CacheTest::bus_write[4];
sc_signal<uint32_t> CacheTest::message;
sc_signal<bool> CacheTest::sent[4];
Vbus CacheTest::bus{"bus_test"};

// Arbitrarily check through the first 1024 addresses.
//
// XXX: GTest runs tests in the order they find them, which happens to put
// this second. Since we also don't run tests in parallel at any point, this is
// okay. If there's a better way to ensure that this invariant is held at object
// construction, it would be good to use here.
//
// Note that we can't just use one copy of the class per instance (i.e., the
// class needs to have static member variables) because SystemC doesn't allow
// us to run multiple simulations or restart an existing simulation from
// within the process.
TEST_F(CacheTest, startsEmpty) {
  for (uint32_t addr = 0; addr < 1024; addr++)
    ASSERT_FALSE(get(addr));
}

TEST_F(CacheTest, busFunctioning) {
  sendSync(0, 1);
}

TEST_F(CacheTest, endToEnd) {
  ASSERT_EQ(get(0), std::nullopt);
  put(0, 0);
  ASSERT_EQ(get(0), std::optional{0});

  put(0, 1);
  ASSERT_EQ(get(0), std::optional{1});

  put(1, 1);
  ASSERT_EQ(get(1), std::optional{1});

  put(1, 2);
  ASSERT_EQ(get(1), std::optional{2});

  put(2, 0);
  ASSERT_EQ(get(2), std::optional{0});

  put(2, 1);
  ASSERT_EQ(get(2), std::optional{1});

  put(3, 10);
  ASSERT_EQ(get(3), std::optional{10});
  ASSERT_TRUE(get(1) == std::optional{2} || get(2) == std::optional{1});

  ASSERT_EQ(get(100), std::nullopt);
}

TEST_F(CacheTest, sets_function_as_expected) {
  // We have no offset, so our index is the LSB.
  put(0b000, 0x11);
  put(0b010, 0x12);
  put(0b100, 0x13);

  // We'll have filled the first set, so this will miss by CLOCK.
  ASSERT_EQ(get(0b000), std::nullopt);

  // Inserting to the second set won't perturb the first.
  put(0b001, 0x21);
  ASSERT_EQ(get(0b001), std::optional{0x21});
  ASSERT_EQ(get(0b010), std::optional{0x12});
  ASSERT_EQ(get(0b100), std::optional{0x13});
}

int sc_main(int argc, char **argv) {
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);

  testing::InitGoogleTest();
  return RUN_ALL_TESTS();
}