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
      static SPredicate *createInverted(std::shared_ptr<SPredicate> target);

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
      static SAddress *createFirst(std::shared_ptr<SPredicate> p);
      static SAddress *createLast(std::shared_ptr<SPredicate> p);

    }; // class SAddress

    class SRange : public SVal {
      std::shared_ptr<SAddress> m_beg;
      std::shared_ptr<SAddress> m_end;

    public:
      SRange(std::shared_ptr<SAddress> beg, std::shared_ptr<SAddress> end) : m_beg(beg), m_end(end) {}
      ~SRange();

    public:
      DBConstRange resolve(DBConstRange const &db) const;

    }; // class SRange

  } // namespace queens::range

} // namespace queens

#endif
