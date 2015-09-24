/*****************************************************************************
 * This file is part of the Queens@TUD solver suite
 * for enumerating and counting the solutions of an N-Queens Puzzle.
 *
 * Copyright (C) 2008-2015
 *      Thomas B. Preusser <thomas.preusser@utexas.edu>
 *****************************************************************************
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 ****************************************************************************/
#include "IR.hpp"

#include "../Database.hpp"

using queens::DBConstRange;
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
    uint64_t const  m_spec;
    uint64_t const  m_mask;

  public:
    RawAddress(uint64_t  spec, unsigned  wild)
      : m_spec(spec<<5), m_mask((UINT64_C(1) << 5*(wild+1))-1) {}
    ~RawAddress() {}

  public:
    DBEntry const *operator()(DBConstRange const &db, AddrType  type) const {
      switch(type) {
      case AddrType::LOWER:
	return  db.lub(m_spec & ~m_mask);
      case AddrType::UPPER:
	return  db.glb(m_spec |  m_mask);
      }
      return  nullptr;
    }
  };
  return  new RawAddress(spec, wild);
}

SAddress *SAddress::createFirst(SPredicate const *p) {
  class First : public SAddress {
    std::unique_ptr<SPredicate const>  m_pred;

  public:
    First(SPredicate const *pred) : m_pred(pred) {}
    ~First() {}

  public:
    DBEntry const *operator()(DBConstRange const &db, AddrType  type) const {
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
    DBEntry const *operator()(DBConstRange const &db, AddrType  type) const {
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

DBConstRange SRange::resolve(DBConstRange const &db) const {
  DBEntry const *beg = (*m_beg)(db, SAddress::AddrType::LOWER);
  DBEntry const *end = (*m_end)(db, SAddress::AddrType::UPPER);
  return  DBConstRange(beg, beg > end? beg : end == db.end()? end : end+1);
}
