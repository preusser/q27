#ifndef QUEENS_IR_HPP
#define QUEENS_IR_HPP

#include <cstdint>
#include <memory>

#include "../Database.hpp"

namespace queens {
  namespace range {

    // Base Clase for Semantic Values
    class SVal {
    protected:
      SVal() {}
    public:
      virtual ~SVal() {}
    };

    //- Position -------------------------------------------------------------
    class SPosition : public SVal {
      int const  m_pos;

    public:
      SPosition(int const  pos) : m_pos(pos) {}
      ~SPosition();

    public:
      operator int() const { return  m_pos; }
    };

    //- Predicate ------------------------------------------------------------
    class SPredicate : public SVal {
    protected:
      SPredicate() {}
    public:
      ~SPredicate() {}

      //+ Functional Interface
    public:
      virtual bool operator()(DBEntry const &e) const = 0;

      //+ Static Factories
    public:
      static SPredicate *createTrue();
      static SPredicate *createTaken();
      static SPredicate *createSolved();
      static SPredicate *createInverted(SPredicate const *target);

    }; // class SPredicate

    //- Address --------------------------------------------------------------
    class SAddress : public SVal {
    public:
      enum class AddrType { LOWER, UPPER };

    protected:
      SAddress() {}
    public:
      ~SAddress() {}

      //+ Functional Interface
    public:
      virtual DBEntry const *operator()(DBConstRange const &db, AddrType  type) const = 0;

      //+ Static Singletons and Factories
    public:
      static SAddress *create(uint64_t  spec, unsigned  wild);
      static SAddress *createFirst(SPredicate const *p);
      static SAddress *createLast(SPredicate const *p);

    }; // class SAddress

    class SRange : public SVal {
      SAddress const *m_beg;
      SAddress const *m_end;

    public:
      SRange(SAddress const *beg, SAddress const *end) : m_beg(beg), m_end(end) {}
      ~SRange();

    public:
      DBConstRange resolve(DBConstRange const &db) const;

    }; // class SRange

  } // namespace queens::range

} // namespace queens

#endif
