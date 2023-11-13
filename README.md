# compile-with-gcc-link-sycllib-without-abi-cxx11
This file checks the ABI compatibility issue. In this demo, we build cpp files with the gcc compiler and link sycl lib with compilation option `-D_GLIBCXX_USE_CXX11_ABI=0`.
Because we will upstream our XPU runtime to stock PyTorch. We need to build the runtime cpp files with the gcc compiler and guarantee the ABI compatibility with stock PyTorch that is built with `-D_GLIBCXX_USE_CXX11_ABI=0`.
Nowadays there are some `std::string` used in sycl API as a return type, like `sycl_device.get_info<sycl::info::device::name>()`.

# how to run this demo
```bash
cd compile-with-gcc-link-sycllib-without-abi-cxx11/
cmake .
make
./demo
```

# Results
* With compiler 2024.0.0 (20231017) and [`-D_GLIBCXX_USE_CXX11_ABI=0`](https://github.com/guangyey/compile-with-gcc-link-sycllib-without-abi-cxx11/blob/8d7a3bf4b47ba6948d3816b5fab5b8fbfaa8bbb4/CMakeLists.txt#L29C2-L29C61)
```bash
cmake .
make
[ 33%] Linking CXX executable demo
/usr/bin/ld: CMakeFiles/demo.dir/Device.cpp.o: in function `sycl::_V1::exception::exception(std::error_code, std::string const&, int, std::shared_ptr<sycl::_V1::context>)':
Device.cpp:(.text._ZN4sycl3_V19exceptionC2ESt10error_codeRKSsiSt10shared_ptrINS0_7contextEE[_ZN4sycl3_V19exceptionC2ESt10error_codeRKSsiSt10shared_ptrINS0_7contextEE]+0xc0): undefined reference to `sycl::_V1::exception::exception(std::error_code, std::shared_ptr<sycl::_V1::context>, std::string const&)'
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/demo.dir/build.make:114: demo] Error 1
make[1]: *** [CMakeFiles/Makefile2:83: CMakeFiles/demo.dir/all] Error 2
make: *** [Makefile:91: all] Error 2
```
* With compiler 2024.0.0 (20231017) and [change `-D_GLIBCXX_USE_CXX11_ABI=1`](https://github.com/guangyey/compile-with-gcc-link-sycllib-without-abi-cxx11/blob/8d7a3bf4b47ba6948d3816b5fab5b8fbfaa8bbb4/CMakeLists.txt#L29C2-L29C61)
```bash
cmake .
make
[ 33%] Building CXX object CMakeFiles/demo.dir/Device.cpp.o
[ 66%] Building CXX object CMakeFiles/demo.dir/demo.cpp.o
[100%] Linking CXX executable demo
[100%] Built target demo
./demo
device_count: 2
hello world!
is_cxx11_abi: 1
0th device name is Intel(R) Arc(TM) A770 Graphics
1th device name is Intel(R) UHD Graphics 770
```
* **We expect this demo can build pass and run pass when using [`-D_GLIBCXX_USE_CXX11_ABI=0`](https://github.com/guangyey/compile-with-gcc-link-sycllib-without-abi-cxx11/blob/8d7a3bf4b47ba6948d3816b5fab5b8fbfaa8bbb4/CMakeLists.txt#L29C2-L29C61)**
* We accept the changes in API parameter type from `std::string` to `char*`, like [sycl::info::device::name](https://github.com/guangyey/compile-with-gcc-link-sycllib-without-abi-cxx11/blob/8d7a3bf4b47ba6948d3816b5fab5b8fbfaa8bbb4/Device.cpp#L75)
