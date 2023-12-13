#include "Device.h"

#include <vector>
#include <mutex>
#include <deque>

static std::once_flag init_device_flag;
static std::once_flag init_prop_flag;
static std::deque<std::once_flag> device_prop_flags;
static std::vector<DeviceProp> device_properties;

struct DevicePool {
  std::vector<std::unique_ptr<sycl::device>> devices;
  std::vector<std::unique_ptr<sycl::context>> contexts;
  std::mutex mutex;
} gDevPool;

static void enumDevices(std::vector<std::unique_ptr<sycl::device>>& devices) {
  auto platform_list = sycl::platform::get_platforms();
  for (const auto& platform : platform_list) {
    if (platform.get_backend() != sycl::backend::ext_oneapi_level_zero) {
      continue;
    }
    auto device_list = platform.get_devices();
    for (const auto& device : device_list) {
      if (device.is_gpu()) {
        devices.push_back(std::make_unique<sycl::device>(device));
      }
    }
  }
}

static void initGlobalDevicePoolState() {
  enumDevices(gDevPool.devices);

  auto device_count = gDevPool.devices.size();
  if (device_count <= 0) {
    std::cout << "XPU device count is zero!" << std::endl;
    return;
  }
  gDevPool.contexts.resize(1);
  gDevPool.contexts[0] = std::make_unique<sycl::context>(
      gDevPool.devices[0]->get_platform().ext_oneapi_get_default_context());
}

static void initDevicePoolCallOnce() {
  std::call_once(init_device_flag, initGlobalDevicePoolState);
}

int dpcppGetDeviceCount() {
  initDevicePoolCallOnce();
  std::lock_guard<std::mutex> lock(gDevPool.mutex);
  return static_cast<int>(gDevPool.devices.size());
}

sycl::device& dpcppGetRawDevice(int device) {
  initDevicePoolCallOnce();
  std::lock_guard<std::mutex> lock(gDevPool.mutex);
  if (device > static_cast<int>(gDevPool.devices.size())) {
    throw std::runtime_error(std::string("device is out of range"));
  }
  return *gDevPool.devices[device];
}

static void initDevicePropState() {
  auto device_count = dpcppGetDeviceCount();
  device_prop_flags.resize(device_count);
  device_properties.resize(device_count); 
}

static void initDeviceProperties(int device) {
  DeviceProp device_prop;
  auto& raw_device = dpcppGetRawDevice(device);

  device_prop.device_name = raw_device.get_info<sycl::info::device::name>();
  device_prop.platform_name = raw_device.get_platform().get_info<sycl::info::platform::name()>();
  device_prop.vendor = raw_device.get_info<sycl::info::device::vendor>();
  device_prop.driver_version = raw_device.get_info<sycl::info::device::driver_version>();
  device_prop.version = raw_device.get_info<sycl::info::device::version>();
  device_prop.max_compute_units = raw_device.get_info<sycl::info::device::max_compute_units>();

  device_properties[device] = device_prop;
}

static void initDevicePropCallOnce(int device) {
  std::call_once(init_prop_flag, initDevicePropState);
  std::call_once(device_prop_flags[device], initDeviceProperties, device);
}

DeviceProp& dpcppGetDeviceProperties(int device) {
  initDevicePropCallOnce(device);
  auto device_count = dpcppGetDeviceCount();
  if (device > device_count) {
    throw std::runtime_error(std::string("device is out of range"));
  }
  return device_properties[device];
}

std::string& dpcppGetDeviceName(int device) {
  return dpcppGetDeviceProperties(device).device_name;
}
