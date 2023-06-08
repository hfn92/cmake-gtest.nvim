cmake_minimum_required(VERSION 3.5)

project(test LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(GTest REQUIRED)

add_executable(main main.cpp)

add_executable(TestSuiteA SuiteA/main.cpp)
target_link_libraries(TestSuiteA GTest::GTest)

add_subdirectory(SuiteB)

add_executable(TestSuiteB_Outer SuiteB/main.cpp)
target_link_libraries(TestSuiteB_Outer GTest::GTest)


