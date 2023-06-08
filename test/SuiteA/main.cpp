#include "gtest/gtest.h"
#include <chrono>
#include <gtest/gtest.h>
#include <iostream>
#include <thread>

using namespace ::testing;

TEST(TestA, Good) {
  EXPECT_TRUE(true);
  EXPECT_TRUE(true);
}

TEST(TestA, NotSoGood) {
  EXPECT_TRUE(true);
  EXPECT_TRUE(false);
}

namespace TestInNs {
TEST(TestB, Good) {}
} // namespace TestInNs

TEST(TestB, DISABLED_Inactive) {}

class Fixture : public testing::Test {};

TEST_F(Fixture, A) {}
TEST_F(Fixture, B) {}

// Parameterized tests

class FooTest : public testing::TestWithParam<int> {};

INSTANTIATE_TEST_SUITE_P(MeenyMinyMoe, FooTest, testing::Range(0, 3, 1));

TEST_P(FooTest, HasBlahBlah) {
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
}

TEST_P(FooTest, HasBlahBlah2) {
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
}

// Typed Tests

template <typename T> class MyFixture : public ::testing::Test {
public:
  static T shared_;
  T value_;
};

using MyTypes = ::testing::Types<char, int, unsigned int>;
TYPED_TEST_SUITE(MyFixture, MyTypes);

TYPED_TEST(MyFixture, Example) {}
TYPED_TEST(MyFixture, Example2) {}

// Type Parameterized tests

template <typename T> class FooTestTP : public testing::Test {};
TYPED_TEST_SUITE_P(FooTestTP);

TYPED_TEST_P(FooTestTP, DoesBlah) {}
TYPED_TEST_P(FooTestTP, HasPropertyA) {}
REGISTER_TYPED_TEST_SUITE_P(FooTestTP, DoesBlah, HasPropertyA);
INSTANTIATE_TYPED_TEST_SUITE_P(My, FooTestTP, MyTypes);

int main(int argc, char **argv) {
  for (size_t i = 1; i < argc; i++) {
    std::string s(argv[i]);
    std::cout << s << std::endl;
  }
  // auto l = argc;
  // std::string s(argv[0]);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
  return 0;
}
