#include <iostream>

bool is_cxx11_abi() {
#ifdef _GLIBCXX_USE_CXX11_ABI
  return (_GLIBCXX_USE_CXX11_ABI != 0);
#else
  return true;
#endif
}
