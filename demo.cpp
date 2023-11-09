#include <sycl/sycl.hpp>
#include "abi_check.h"
#include "Device.h"

#include <iostream>

int main(){
  std::cout << "device_count: " << dpcppGetDeviceCount() << std::endl;
  std::cout << "hello world!" << std::endl;
  std::cout << "is_cxx11_abi: " << is_cxx11_abi() << std::endl;
  for (auto i = 0 ; i < dpcppGetDeviceCount() ; i++) {
    // std::cout << i << "th device name is " << dpcppGetDeviceName(i) << std::endl;
    std::cout << i << "th device name is " << dpcppGetDeviceProperties(i).device_name << std::endl;
  }
}
