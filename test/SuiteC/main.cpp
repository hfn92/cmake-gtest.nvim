#include <gtest/gtest.h>
#include <iostream>

using namespace ::testing;
TEST(LocalTest, Good) { EXPECT_TRUE(true); }

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
