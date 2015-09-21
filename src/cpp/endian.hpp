/*****************************************************************************
 * This file is part of the Queens@TUD solver suite
 * for enumerating and counting the solutions of an N-Queens Puzzle.
 *
 * Copyright (C) 2008-2015
 *      Thomas B. Preusser <thomas.preusser@utexas.edu>
 *****************************************************************************
 * This design is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Modifications to this work must be clearly identified and must leave
 * the original copyright statement and contact information intact. This
 * license notice may not be removed.
 *
 * This design is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this design.  If not, see <http://www.gnu.org/licenses/>.
 ****************************************************************************/
#ifndef ENDIAN_HPP
#define ENDIAN_HPP

#include <cstdint>
#include <endian.h>

namespace endian {
  template<typename Rep, class Swap> class xint_t {
    Rep  val;

  public:
    xint_t()                : val(0) {}
    xint_t(Rep   const &v)  : val(Swap()(v)) {}
    xint_t(xint_t const &o) : val(o.val) {}
    ~xint_t() {}

  public:
    operator Rep() const { return  Swap()(val); }
    xint_t &operator=(Rep const &v) {
      val = Swap()(v);
      return *this;
    }
    xint_t &operator=(xint_t const &o) {
      val = o.val;
      return *this;
    }

    // Optimized bit-wise Operations
  public:
    Rep operator&(Rep const &o) {
      return  Swap()(val) & o;
    }
    Rep operator|(Rep const &o) {
      return  Swap()(val) | o;
    }
    Rep operator^(Rep const &o) {
      return  Swap()(val) ^ o;
    }
    xint_t operator&(xint_t const &o) {
      return  val & o.val;
    }
    xint_t operator|(xint_t const &o) {
      return  val | o.val;
    }
    xint_t operator^(xint_t const &o) {
      return  val ^ o.val;
    }
    xint_t &operator&=(xint_t const &o) {
      val &= o.val;
      return *this;
    }
    xint_t &operator|=(xint_t const &o) {
      val |= o.val;
      return *this;
    }
    xint_t &operator^=(xint_t const &o) {
      val ^= o.val;
      return *this;
    }

    // Arithmetic Operations: do *not* overuse
  public:
    Rep operator+(Rep const &o) {
      return  Swap()(val) + o;
    }
    Rep operator-(Rep const &o) {
      return  Swap()(val) - o;
    }
    Rep operator*(Rep const &o) {
      return  Swap()(val) * o;
    }
    Rep operator/(Rep const &o) {
      return  Swap()(val) / o;
    }
    xint_t &operator+=(Rep const &o) {
      val = Swap()(Swap()(val) + o);
      return *this;
    }
    xint_t &operator-=(Rep const &o) {
      val = Swap()(Swap()(val) - o);
      return *this;
    }
    xint_t &operator*=(Rep const &o) {
      val = Swap()(Swap()(val) * o);
      return *this;
    }
    xint_t &operator/=(Rep const &o) {
      val = Swap()(Swap()(val) / o);
      return *this;
    }
  };
  template<typename T> struct Swap16le { T operator()(T const &x) const { return  htole16(x); } };
  template<typename T> struct Swap16be { T operator()(T const &x) const { return  htobe16(x); } };
  template<typename T> struct Swap32le { T operator()(T const &x) const { return  htole32(x); } };
  template<typename T> struct Swap32be { T operator()(T const &x) const { return  htobe32(x); } };
  template<typename T> struct Swap64le { T operator()(T const &x) const { return  htole64(x); } };
  template<typename T> struct Swap64be { T operator()(T const &x) const { return  htobe64(x); } };
  typedef xint_t<int16_t,  Swap16le<int16_t>>  int16le_t;
  typedef xint_t<int16_t,  Swap16be<int16_t>>  int16be_t;
  typedef xint_t<int32_t,  Swap32le<int32_t>>  int32le_t;
  typedef xint_t<int32_t,  Swap32be<int32_t>>  int32be_t;
  typedef xint_t<int64_t,  Swap64le<int64_t>>  int64le_t;
  typedef xint_t<int64_t,  Swap64be<int64_t>>  int64be_t;
  typedef xint_t<uint16_t, Swap16le<uint16_t>>  uint16le_t;
  typedef xint_t<uint16_t, Swap16be<uint16_t>>  uint16be_t;
  typedef xint_t<uint32_t, Swap32le<uint32_t>>  uint32le_t;
  typedef xint_t<uint32_t, Swap32be<uint32_t>>  uint32be_t;
  typedef xint_t<uint64_t, Swap64le<uint64_t>>  uint64le_t;
  typedef xint_t<uint64_t, Swap64be<uint64_t>>  uint64be_t;
}
#endif
