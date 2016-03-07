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

    //- Number ---------------------------------------------------------------
    class SNumber : public SVal {
      int const  m_pos;

    public:
      SNumber(int const  pos) : m_pos(pos) {}
      ~SNumber();

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
      static std::shared_ptr<SPredicate> const  TRUE;
      static std::shared_ptr<SPredicate> const  TAKEN;
      static std::shared_ptr<SPredicate> const  SOLVED;
      static std::shared_ptr<SPredicate> const  WRAPPED;
      static std::shared_ptr<SPredicate> const  VALID;
      static std::shared_ptr<SPredicate>
      createInverted(std::shared_ptr<SPredicate> const &target);

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

      //+ Static Factories
    public:
      static std::shared_ptr<SAddress> create(uint64_t  spec, unsigned  wild);
      static std::shared_ptr<SAddress> createFirst(std::shared_ptr<SPredicate> const &p);
      static std::shared_ptr<SAddress> createLast (std::shared_ptr<SPredicate> const &p);
      static std::shared_ptr<SAddress> createOffset(std::shared_ptr<SAddress> const &base, int  ofs);

    }; // class SAddress

    class SRange : public SVal {
    protected:
      SRange() {}
    public:
      ~SRange() {}

    public:
      virtual DBConstRange resolve(DBConstRange const &db) const = 0;

      //+ Static Factories
    public:
      static std::shared_ptr<SRange> create(std::shared_ptr<SAddress> const &beg, std::shared_ptr<SAddress> const &end);
      static std::shared_ptr<SRange> createSpan(std::shared_ptr<SAddress> const &base, int  span);
      static std::shared_ptr<SRange> createBiSpan(std::shared_ptr<SAddress> const &base, int  span);
    }; // class SRange

  } // namespace queens::range

} // namespace queens

#endif
