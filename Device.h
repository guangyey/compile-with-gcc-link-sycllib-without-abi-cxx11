#include <sycl/sycl.hpp>

template <typename T>
using dpcpp_info_t = typename T::return_type;

struct DeviceProp {
  dpcpp_info_t<sycl::info::device::name> device_name;
  dpcpp_info_t<sycl::info::platform::name> platform_name;
  dpcpp_info_t<sycl::info::device::vendor> vendor;
  dpcpp_info_t<sycl::info::device::driver_version> driver_version;
  dpcpp_info_t<sycl::info::device::version> version;
  dpcpp_info_t<sycl::info::device::max_compute_units> max_compute_units;
};

int dpcppGetDeviceCount();
DeviceProp& dpcppGetDeviceProperties(int device);
std::string& dpcppGetDeviceName(int device);
