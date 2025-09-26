#include <gtest/gtest.h>
#include <optional>

#include "Vcache.h"

using namespace sc_core;

class CacheTest : public testing::Test {
private:
  static sc_signal<bool> ch1_read, ch2_read, ch1_write, ch1_hit, ch2_hit;
  static sc_signal<uint32_t> ch1_in_val, ch1_out_val, ch2_out_val, ch1_in_addr,
      ch2_in_addr;
  static sc_clock clock;
  static Vcache bank;

protected:
  CacheTest() = default;

  static void SetUpTestSuite() {
    bank.ch1_read(ch1_read);
    bank.ch2_read(ch2_read);
    bank.ch1_write(ch1_write);
    bank.ch1_hit(ch1_hit);
    bank.ch2_hit(ch2_hit);
    bank.ch1_in_val(ch1_in_val);
    bank.ch1_out_val(ch1_out_val);
    bank.ch2_out_val(ch2_out_val);
    bank.ch1_in_addr(ch1_in_addr);
    bank.ch2_in_addr(ch2_in_addr);
    bank.clock(clock);
  }

public:
  void ch1_put(uint32_t addr, uint32_t val) {
    ch1_read.write(false);
    ch1_write.write(true);
    ch1_in_addr.write(addr);
    ch1_in_val.write(val);

    do {
      sc_start(1, SC_NS);
    } while (!ch1_hit.read());
  }

  std::optional<uint32_t> ch1_get(uint32_t addr) {
    ch1_read.write(true);
    ch1_write.write(false);
    ch1_in_addr.write(addr);
    sc_start(1, SC_NS);

    return ch1_hit.read() ? std::optional{ch1_out_val.read()} : std::nullopt;
  }

  std::optional<uint32_t> ch2_get(uint32_t addr) {
    ch2_read.write(true);
    ch2_in_addr.write(addr);
    sc_start(1, SC_NS);

    return ch2_hit.read() ? std::optional{ch2_out_val.read()} : std::nullopt;
  }

  std::pair<std::optional<uint32_t>, std::optional<uint32_t>>
  dual_get(const std::pair<uint32_t, uint32_t> &addrs) {
    ch1_read.write(true);
    ch2_read.write(true);
    ch1_write.write(false);

    ch1_in_addr.write(addrs.first);
    ch2_in_addr.write(addrs.second);
    sc_start(1, SC_NS);
    return {
        ch1_hit.read() ? std::optional{ch1_out_val.read()} : std::nullopt,
        ch2_hit.read() ? std::optional{ch2_out_val.read()} : std::nullopt,
    };
  }
};

sc_signal<bool> CacheTest::ch1_read, CacheTest::ch2_read, CacheTest::ch1_write,
    CacheTest::ch1_hit, CacheTest::ch2_hit;
sc_signal<uint32_t> CacheTest::ch1_in_val, CacheTest::ch1_out_val,
    CacheTest::ch2_out_val, CacheTest::ch1_in_addr, CacheTest::ch2_in_addr;
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
    ASSERT_FALSE(ch1_get(addr));
}

TEST_F(CacheTest, endToEnd) {
  assert(ch1_get(0) == std::nullopt);
  ch1_put(0, 0);
  assert(ch1_get(0) == std::optional{0});

  ch1_put(1, 1);
  assert(ch1_get(1) == std::optional{1});

  ch1_put(1, 2);
  assert(ch1_get(1) == std::optional{2});

  ch1_put(2, 0);
  assert(ch1_get(2) == std::optional{0});

  ch1_put(2, 1);
  assert(ch1_get(2) == std::optional{1});

  ch1_put(3, 10);
  assert(ch1_get(3) == std::optional{10});
  assert(ch1_get(1) == std::optional{2} || ch1_get(2) == std::optional{1});

  assert(ch1_get(100) == std::nullopt);
}

TEST_F(CacheTest, ch2ReadUsable) {
  ch1_put(0x20, 0x2f);
  ASSERT_EQ(ch2_get(0x20), std::optional{0x2f});
}

TEST_F(CacheTest, dualChannelRead) {
  ch1_put(0x10, 0x1f);
  ch1_put(0x20, 0x2f);

  auto rq_list = std::pair{0x10, 0x20};
  auto response = dual_get(rq_list);
  std::pair<std::optional<uint32_t>, std::optional<uint32_t>> expected_response =
      std::pair{std::optional{0x1f}, std::optional{0x2f}};
  ASSERT_EQ(response, expected_response);
}

int sc_main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  testing::InitGoogleTest();
  return RUN_ALL_TESTS();
}