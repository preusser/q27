#ifndef AELIB_INCLUDED
#define AELIB_INCLUDED

#include <memory>

#include "m_DiniProducts.h"
#include "os_dep.h"

namespace ae {
  typedef m_DiniProducts AeDevice;

  class AeLib {
    class AeLibImpl {
      sighandler_t const  oldSigInt;
      sighandler_t const  oldSigAbrt;
      sighandler_t const  oldSigTerm;

    public:
      AeLibImpl();
      ~AeLibImpl();

    public:
      unsigned  deviceCount() const;
      AeDevice& device(unsigned  idx);

    private:
      static void abort(int const  signum);
    };
    static std::weak_ptr<AeLibImpl>  the_impl;

    std::shared_ptr<AeLibImpl>  m_impl;

  public:
    AeLib();
    ~AeLib() {}

  public:
    unsigned  deviceCount() const   { return  m_impl->deviceCount(); }
    AeDevice& device(unsigned  idx) { return  m_impl->device(idx); }
  };
}
#endif
