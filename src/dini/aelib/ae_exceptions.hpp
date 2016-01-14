#ifndef AE_EXCEPTIONS_HPP_INCLUDED
#define AE_EXCEPTIONS_HPP_INCLUDED

#include <string>

class AeException {
public:
  AeException() {}
  ~AeException() {}

public:
  virtual std::string toString() const;
};

class UnavailableException : public AeException {
};

#endif
