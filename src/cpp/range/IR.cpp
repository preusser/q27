#include "IR.hpp"

#include "../Database.hpp"

using queens::Database;
using queens::DBEntry;
using namespace queens::range;

SPosition::~SPosition() {}
 
//- class SPredicate ---------------------------------------------------------
SPredicate *SPredicate::createTrue() {
  class True : public SPredicate {
  public:
    True() {}
    ~True() {}

  public:
    bool operator()(DBEntry const &e) const { return  true; }
  };
  return  new True();
}
SPredicate *SPredicate::createTaken() {
  class Taken : public SPredicate {
  public:
    Taken() {}
    ~Taken() {}

  public:
    bool operator()(DBEntry const &e) const { return  e.taken() && !e.solved(); }
  };
  return  new Taken();
}
SPredicate *SPredicate::createSolved() {
  class Solved : public SPredicate {
  public:
    Solved() {}
    ~Solved() {}

  public:
    bool operator()(DBEntry const &e) const { return  e.solved(); }
  };
  return  new Solved();
}
SPredicate *SPredicate::createInverted(SPredicate const *target) {
  class Inverted : public SPredicate {
    std::unique_ptr<SPredicate const>  m_target;

  public:
    Inverted(SPredicate const *target) : m_target(target) {}
    ~Inverted() {}

  public:
    bool operator()(DBEntry const &e) const { return !(*m_target)(e); }
  };
  return  new Inverted(target);
}

//- class SAddress -----------------------------------------------------------
SAddress *SAddress::create(uint64_t  spec, unsigned  wild) {
  class RawAddress : public SAddress {
    uint64_t        m_spec;
    unsigned const  m_wild;

  public:
    RawAddress(uint64_t  spec, unsigned  wild) : m_spec(spec), m_wild(wild) {}
    ~RawAddress() {}

  public:
    void makeLower() { m_spec &= ~((1 << 5*m_wild)-1)<<5; }
    void makeUpper() { m_spec |=  ((1 << 5*m_wild)-1)<<5; }
    DBEntry const *operator()(Database const &db) const {
      return  db.findCase(m_spec);
    }
  };
  return  new RawAddress(spec<<5, wild);
}

SAddress *SAddress::createFirst(SPredicate const *p) {
  class First : public SAddress {
    std::unique_ptr<SPredicate const>  m_pred;

  public:
    First(SPredicate const *pred) : m_pred(pred) {}
    ~First() {}

  public:
    DBEntry const *operator()(Database const &db) const {
      for(DBEntry const &e : db) {
	if((*m_pred)(e))  return &e;
      }
      return  db.end();
    }
  };
  return  new First(p);
}

SAddress *SAddress::createLast(SPredicate const *p) {
  class Last : public SAddress {
    std::unique_ptr<SPredicate const>  m_pred;

  public:
    Last(SPredicate const *pred) : m_pred(pred) {}
    ~Last() {}

  public:
    DBEntry const *operator()(Database const &db) const {
      DBEntry const *const  beg = db.begin();
      for(DBEntry const *ptr = db.end(); --ptr >= beg;) {
	if((*m_pred)(*ptr))  return  ptr;
      }
      return  nullptr;
    }
  };
  return  new Last(p);
}

//- class SRange -------------------------------------------------------------
SRange::~SRange() {}

Range SRange::resolve(Database const &db) const {
  DBEntry const *const  beg = (*m_beg)(db);
  if(m_end.get() == nullptr) {
    return  Range(beg, ((beg == nullptr) || (beg == db.end()))? beg : beg+1);
  }
  DBEntry const *const  end = (*m_end)(db);
  return  Range(end == nullptr? nullptr : beg == nullptr? db.begin() : beg,
		end == nullptr? nullptr : end == db.end()? end : end + 1);
}
