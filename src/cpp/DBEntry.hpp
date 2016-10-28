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
#ifndef QUEENS_DBENTRY_HPP
#define QUEENS_DBENTRY_HPP

#include <ostream>

#include "endian.hpp"
#include "Symmetry.hpp"

namespace queens {
  using namespace endian;

 /**
  * Thin wrapper class for accessing a database entry. It enables a more
  * comfortable access to the binary entry layout, which comprises two
  * 64-bit words stored in network byte order (big endian):
  *
  *
  *    Bits    Width   Description
  *  ------------------------------------------------------------------
  * uint64_t  m_spec:
  *  [Pre-Placement]
  *    63-60     4     wa  - West
  *    59-55     5     wb
  *    54-50     5     na  - North
  *    49-45     5     nb
  *    44-40     5     ea  - East
  *    39-35     5     eb
  *    34-30     5     sa  - South
  *    29-25     5     sb
  *    24-23     2     sym - Symmetry: 3-None, 2-Point, 1-Rotate
  *    22-20     3     CRC-3 over 63-23 (Generator: 0xB)
  *  [Solution Timestamp]
  *    19-18     2     year-2015
  *    17-14     4     month
  *    13- 9     5     day
  *     8- 4     5     hour
  *     3- 0     4     min/4
  *
  * uint64_t  m_sol;
  *  [Solver]
  *    63-52    12     solver ID
  *  [Solution]
  *    51-48     4     cnt%13
  *    47-44     4     cnt%15
  *    43- 0    44     cnt - Solution Count
  *
  * A fresh DBEntry can be constructed from a pre-placement.
  * Its [Solution Timestamp], [Solver] and [Solution] fields will all be
  * zero in this case. Otherwise, a DBEntry just provides the interpretation
  * for the two adjacent underlying 64-bit words of a memory-mapped database.
  * The corresponding objects are not really constructed but rather obtained
  * by reinterpreting the pointer to the backing memory, e.g. through an
  * reinterprete_cast<DBEntry*>(ptr).
  */
  class DBEntry {
    uint64be_t  m_spec;
    uint64be_t  m_sol;

    //- Construction / Destruction -------------------------------------------
  public:
    DBEntry() : m_spec(0), m_sol(0) {}
    DBEntry(int8_t const *pre2, Symmetry  sym) : m_sol(0) {
      m_spec = encodeSpec(pre2, sym);
    }
    ~DBEntry() {}

  public:
    DBEntry& operator=(DBEntry const& o) {
      m_spec = o.m_spec;
      m_sol  = o.m_sol;
      return *this;
    }
    bool operator==(DBEntry const& o) const {
      return (m_spec == o.m_spec) && (m_sol == o.m_sol);
    }
    bool operator!=(DBEntry const& o) const {
      return !(*this == o);
    }

    //- Data Accessors -------------------------------------------------------
  private:
    friend std::ostream& operator<<(std::ostream &out, DBEntry const &entry);

    static bool taken(uint64_t _spec) { return time(_spec) != 0; }
    static bool solved(uint64_t _sol) { return _sol        != 0; }

    static uint64_t spec (uint64_t _spec) { return (_spec >> 20)&UINT64_C(0xFFFFFFFFFFF); }
    static Symmetry sym  (uint64_t _spec) { return (_spec >> 23)&3; }
    static bool     valid(uint64_t _spec) { return  crc3(_spec >> 20) == 0; }
    static unsigned queens(uint64_t _spec);

    static unsigned year (uint64_t _spec) { return ((_spec >> 18)&3) + 2015; }
    static unsigned month(uint64_t _spec) { return (_spec >> 14)&15; }
    static unsigned day  (uint64_t _spec) { return (_spec >>  9)&31; }
    static unsigned hour (uint64_t _spec) { return (_spec >>  4)&31; }
    static unsigned min  (uint64_t _spec) { return (_spec&15)*4; }
    static unsigned time (uint64_t _spec) { return _spec & UINT64_C(0xFFFFF); }

    static unsigned solver (uint64_t _sol) { return (_sol >> 52)&2047; }
    static unsigned mod13  (uint64_t _sol) { return (unsigned)((_sol >> 48)&15); }
    static unsigned mod15  (uint64_t _sol) { return (unsigned)((_sol >> 44)&15); }
    static uint64_t count  (uint64_t _sol) { return _sol & UINT64_C(0xFFFFFFFFFFF); }
    static bool     wrapped(uint64_t _sol) {
      uint64_t const  cnt = count(_sol);
      return (cnt%13 != mod13(_sol)) || (cnt%15 != mod15(_sol));
    }

  public:
    bool taken()  const { return  taken(m_spec); }
    bool solved() const { return  solved(m_sol); }

    uint64_t spec () const { return  spec (m_spec); }
    Symmetry sym  () const { return  sym  (m_spec); }
    bool     valid() const { return  valid(m_spec); }
    unsigned queens()const { return  queens(m_spec);}
    unsigned year () const { return  year (m_spec); }
    unsigned month() const { return  month(m_spec); }
    unsigned day  () const { return  day  (m_spec); }
    unsigned hour () const { return  hour (m_spec); }
    unsigned min  () const { return  min  (m_spec); }
    unsigned time () const { return  time (m_spec); }

    unsigned solver  ()  const { return  solver (m_sol); }
    unsigned mod13   ()  const { return  mod13  (m_sol); }
    unsigned mod15   ()  const { return  mod15  (m_sol); }
    uint64_t count   ()  const { return  count  (m_sol); }
    bool     wrapped ()  const { return  wrapped(m_sol); }

  public:
    char const *check() const;
    uint64_t real_count() const { return  count() << (sym().weight()); }

  private:
    void timestamp();

  public:
    void take()   { timestamp(); }
    void untake() { m_spec &= ~UINT64_C(0xFFFFF); }
    void unsolve(){ untake(); m_sol = 0; }

    /**
     * Sets the solution and timestamp fields of this DBEntry
     * unless m13 > 12 or m15 > 14, in which case false is returned
     * without any further action.
     */
    bool solve(unsigned  solver, uint64_t  cnt, unsigned  m15, unsigned  m13);

  private:
    static uint64_t encodeSpec(int8_t const *pre2, Symmetry  sym);
    static unsigned crc3(uint64_t  val);

  }; // class DBEntry

  std::ostream& operator<<(std::ostream &out, DBEntry const &entry);

} // namespace queens

#endif
