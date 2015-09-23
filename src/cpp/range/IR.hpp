#ifndef QUEENS_IR_HPP
#define QUEENS_IR_HPP

#include <cstdint>
#include <memory>

namespace queens {
  class DBEntry;
  class Database;

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
    protected:
      SAddress() {}
    public:
      ~SAddress() {}

      //+ Functional Interface
    public:
      virtual void makeLower() {}
      virtual void makeUpper() {}
      virtual DBEntry const *operator()(Database const &db) const = 0;

      //+ Static Singletons and Factories
    public:
      static SAddress *create(uint64_t  spec, unsigned  wild);
      static SAddress *createFirst(SPredicate const *p);
      static SAddress *createLast(SPredicate const *p);

    }; // class SAddress

    class Range {
      DBEntry const *const  m_beg;
      DBEntry const *const  m_end;

    public:
      Range(DBEntry const *beg, DBEntry const *end) : m_beg(beg), m_end(end) {}
      ~Range() {}

    public:
      DBEntry const *begin() const { return  m_beg; }
      DBEntry const *end()   const { return  m_end; }

    }; // class Range

    class SRange : public SVal {
      std::unique_ptr<SAddress const>  m_beg;
      std::unique_ptr<SAddress const>  m_end;

    public:
      SRange(SAddress const *beg, SAddress const *end) : m_beg(beg), m_end(end) {}
      ~SRange();

    public:
      Range resolve(Database const &db) const;

    }; // class SRange

  } // namespace queens::range

} // namespace queens

#endif
