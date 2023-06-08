#include <gtest/gtest.h>
#include <iostream>
#include <limits.h>
#include <stdio.h>
#include <unistd.h>
using namespace ::testing;

TEST(LocalTest, Good) { EXPECT_TRUE(true); }

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  // char cwd[PATH_MAX];
  // if (getcwd(cwd, sizeof(cwd)) != NULL) {
  //   printf("Current working dir: %s\n", cwd);
  // } else {
  //   perror("getcwd() error");
  //   return 1;
  // }
  return RUN_ALL_TESTS();
}
