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
#ifndef UINT128_T_HPP
#define UINT128_T_HPP

#include <cstdint>


class uint128_t {
  uint64_t  hi;
  uint64_t  lo;

public:
  uint128_t() : hi(UINT64_C(0)), lo(UINT64_C(0)) {}
  uint128_t(int const v) : hi(UINT64_C(0)), lo(v) {}
  uint128_t(uint64_t const v) : hi(UINT64_C(0)), lo(v) {}
  ~uint128_t() {}

public:
  explicit operator uint64_t() const { return  lo; }

  uint128_t& operator>>=(unsigned  s) {
    s &= 0x7F;
    if(s < 64) {
      lo = (hi << (64-s))|(lo >> s);
      hi = hi >> s;
    }
    else {
      lo = hi >> (s-64);
      hi = 0;
    }
    return *this;
  }
  uint128_t operator>>(unsigned  s) const {
    uint128_t  res(*this);
    res >>= s;
    return  res;
  }

  uint128_t& operator<<=(unsigned  s) {
    s &= 0x7F;
    if(s < 64) {
      hi = (hi << s)|(lo >> (64-s));
      lo = lo << s;
    }
    else {
      hi = lo << (s-64);
      lo = 0;
    }
    return *this;
  }
  uint128_t operator<<(unsigned  s) const {
    uint128_t  res(*this);
    res <<= s;
    return  res;
  }

  uint128_t& operator^=(uint128_t const& o) {
    hi ^= o.hi;
    lo ^= o.lo;
    return *this;
  }
  uint128_t operator&(uint128_t const& o) const {
    uint128_t  res(*this);
    res.hi &= o.hi;
    res.lo &= o.lo;
    return  res;
  }
  uint128_t operator|(uint128_t const& o) const {
    uint128_t  res(*this);
    res.hi |= o.hi;
    res.lo |= o.lo;
    return  res;
  }
  uint128_t operator~() const {
    uint128_t  res;
    res.hi = ~hi;
    res.lo = ~lo;
    return  res;
  }
  uint128_t operator-() const {
    uint128_t  res(*this);
    res.lo = -lo;
    res.hi = lo? ~hi : -hi;
    return  res;
  }
  bool operator!=(uint128_t const& o) const {
    return (hi != o.hi) || (lo != o.lo);
  }
};
#endif
