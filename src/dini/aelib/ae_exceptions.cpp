#include "ae_exceptions.hpp"

#include <typeinfo>

std::string AeException::toString() const {
  return  typeid(*this).name();
}
