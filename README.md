# compile-with-gcc-link-sycllib-without-abi-cxx11
This file checks the ABI compatibility issue. In this demo, we build cpp files with the gcc compiler and link sycl lib with compilation option `-D_GLIBCXX_USE_CXX11_ABI=0`.
Because we will upstream our XPU runtime to stock PyTorch. We need to build the runtime cpp files with the gcc compiler and guarantee the ABI compatibility with stock PyTorch that is built with `-D_GLIBCXX_USE_CXX11_ABI=0`.
Nowadays there are some `std::string` used in sycl API as a return type, like `sycl_device.get_info<sycl::info::device::name>()`.
