#include "ae_lib.hpp"

#include <iostream>


using namespace ae;

std::weak_ptr<AeLib::AeLibImpl>  AeLib::the_impl;

AeLib::AeLib() {
  std::shared_ptr<AeLib::AeLibImpl>  impl = the_impl.lock();
  if(!impl)  the_impl = (impl = std::make_shared<AeLib::AeLibImpl>());
  std::swap(impl, this->m_impl);
}

AeLib::AeLibImpl::AeLibImpl()
  // Install aborting signal handlers
  : oldSigInt (signal(SIGINT,  AeLib::AeLibImpl::abort)),
    oldSigAbrt(signal(SIGABRT, AeLib::AeLibImpl::abort)),
    oldSigTerm(signal(SIGTERM, AeLib::AeLibImpl::abort)) {

  // Perform Initialization
  ae_init();
}
AeLib::AeLibImpl::~AeLibImpl() {
  // Regular Termination
  ae_deinit();

  // Reset signal handlers
  signal(SIGINT,  oldSigInt);
  signal(SIGABRT, oldSigAbrt);
  signal(SIGTERM, oldSigTerm);
}

void AeLib::AeLibImpl::abort(int const  signum) {
  std::cerr << "Abort." << std::endl;
  if(ae_DeviceCount > 0)  ae_deinit();
  exit(signum);
}

unsigned  AeLib::AeLibImpl::deviceCount() const { return  ae_DeviceCount; }
AeDevice& AeLib::AeLibImpl::device(unsigned const  idx) {
  return *ae_DevicesFound[idx];
}
