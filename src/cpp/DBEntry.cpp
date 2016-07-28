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
#include "DBEntry.hpp"

#include <iomanip>
#include <ctime>
#include <cassert>

using queens::DBEntry;

char const *DBEntry::check() const {
  if(!valid())   return "CRC Error";
  if(wrapped())  return "Residue Error";
  return  0;
}

unsigned DBEntry::queens(uint64_t _spec) {
  unsigned  res = 0;
  for(_spec >>= 25; _spec != 0; _spec >>= 5) {
    if((_spec & 0x1F) > 1)  res++;
  }
  return  res;
}

void DBEntry::timestamp() {
  time_t rawtime;
  ::time(&rawtime);
  struct tm *ptm = gmtime(&rawtime);

  m_spec =
    (m_spec & ~UINT64_C(0xFFFFF)) |
    ((((((((((ptm->tm_year-115)&3 << 4) | (ptm->tm_mon+1)) << 5) | ptm->tm_mday) << 5) |  ptm->tm_hour) << 4) | (ptm->tm_min/4)) & 0xFFFFF);
}

bool DBEntry::solve(unsigned  solver, uint64_t  cnt, unsigned  m15, unsigned  m13) {
  if((14 < m15) || (12 < m13))  return  false;
  timestamp();
  m_sol =
    (((uint64_t)solver)<<52)|
    (((uint64_t)m13)<<48)|
    (((uint64_t)m15)<<44)|
    (cnt&UINT64_C(0xFFFFFFFFFFF));

  return  true;
}

uint64_t DBEntry::encodeSpec(int8_t const *const  pre2, Symmetry  sym) {
  uint64_t  spec = 0;
  for(unsigned  i = 0; i < 8; i++)  spec = (spec<<5)|pre2[i];
  spec = (spec<<2)|sym;
  assert(spec < UINT64_C(0x20000000000));
  return ((spec<<3)|crc3(spec))<<20;
}
unsigned DBEntry::crc3(uint64_t  val) {
  // Precomputed CRC for Generator 0xB
  static uint8_t const  FSC[256] = {
    0x00, 0x60, 0xC0, 0xA0, 0xE0, 0x80, 0x20, 0x40,
    0xA0, 0xC0, 0x60, 0x00, 0x40, 0x20, 0x80, 0xE0,
    0x20, 0x40, 0xE0, 0x80, 0xC0, 0xA0, 0x00, 0x60,
    0x80, 0xE0, 0x40, 0x20, 0x60, 0x00, 0xA0, 0xC0,
    0x40, 0x20, 0x80, 0xE0, 0xA0, 0xC0, 0x60, 0x00,
    0xE0, 0x80, 0x20, 0x40, 0x00, 0x60, 0xC0, 0xA0,
    0x60, 0x00, 0xA0, 0xC0, 0x80, 0xE0, 0x40, 0x20,
    0xC0, 0xA0, 0x00, 0x60, 0x20, 0x40, 0xE0, 0x80,
    0x80, 0xE0, 0x40, 0x20, 0x60, 0x00, 0xA0, 0xC0,
    0x20, 0x40, 0xE0, 0x80, 0xC0, 0xA0, 0x00, 0x60,
    0xA0, 0xC0, 0x60, 0x00, 0x40, 0x20, 0x80, 0xE0,
    0x00, 0x60, 0xC0, 0xA0, 0xE0, 0x80, 0x20, 0x40,
    0xC0, 0xA0, 0x00, 0x60, 0x20, 0x40, 0xE0, 0x80,
    0x60, 0x00, 0xA0, 0xC0, 0x80, 0xE0, 0x40, 0x20,
    0xE0, 0x80, 0x20, 0x40, 0x00, 0x60, 0xC0, 0xA0,
    0x40, 0x20, 0x80, 0xE0, 0xA0, 0xC0, 0x60, 0x00,
    0x60, 0x00, 0xA0, 0xC0, 0x80, 0xE0, 0x40, 0x20,
    0xC0, 0xA0, 0x00, 0x60, 0x20, 0x40, 0xE0, 0x80,
    0x40, 0x20, 0x80, 0xE0, 0xA0, 0xC0, 0x60, 0x00,
    0xE0, 0x80, 0x20, 0x40, 0x00, 0x60, 0xC0, 0xA0,
    0x20, 0x40, 0xE0, 0x80, 0xC0, 0xA0, 0x00, 0x60,
    0x80, 0xE0, 0x40, 0x20, 0x60, 0x00, 0xA0, 0xC0,
    0x00, 0x60, 0xC0, 0xA0, 0xE0, 0x80, 0x20, 0x40,
    0xA0, 0xC0, 0x60, 0x00, 0x40, 0x20, 0x80, 0xE0,
    0xE0, 0x80, 0x20, 0x40, 0x00, 0x60, 0xC0, 0xA0,
    0x40, 0x20, 0x80, 0xE0, 0xA0, 0xC0, 0x60, 0x00,
    0xC0, 0xA0, 0x00, 0x60, 0x20, 0x40, 0xE0, 0x80,
    0x60, 0x00, 0xA0, 0xC0, 0x80, 0xE0, 0x40, 0x20,
    0xA0, 0xC0, 0x60, 0x00, 0x40, 0x20, 0x80, 0xE0,
    0x00, 0x60, 0xC0, 0xA0, 0xE0, 0x80, 0x20, 0x40,
    0x80, 0xE0, 0x40, 0x20, 0x60, 0x00, 0xA0, 0xC0,
    0x20, 0x40, 0xE0, 0x80, 0xC0, 0xA0, 0x00, 0x60
  };
  unsigned  crc = 0;
  for(unsigned  i = 0; i < 8; i++) {
    crc = FSC[(val>>56)^crc];
    val <<= 8;
  }
  return  crc>>5;
}

std::ostream& queens::operator<<(std::ostream &out, DBEntry const&  entry) {
  uint64_t const  spec = entry.m_spec;
  uint64_t const  sol  = entry.m_sol;

  { // Pre-Placement
    uint64_t  pre = spec>>1;
    for(int  i = 0; i < 4; i++) {
      out << '(' << std::setw(2) << (unsigned)(pre>>59);
      pre <<= 5;
      out << ',' << std::setw(2) << (unsigned)(pre>>59) << ')';
      pre <<= 5;
    }
  }
  // Solution
  out << '\t';
  if(sol) {
    out << std::setfill('0')
      // Date
	<< DBEntry::year(spec) << '-' << std::setw(2) << DBEntry::month(spec) << '-' << std::setw(2) << DBEntry::day(spec) << ' '
      // Time
	<< std::setw(2) << DBEntry::hour(spec) << ':' << std::setw(2) << DBEntry::min(spec) << std::setfill(' ')
      // Solution
	<< "\t#" << std::setw(4) << DBEntry::solver(sol) << '\t' << std::setw(14) << DBEntry::count(sol);
  }
  else {
    out << "<todo>";
  }

  if(!DBEntry::valid(spec)) {
    out << "\tINVALID";
  }
  if(DBEntry::wrapped(sol)) {
    unsigned const  m13 = DBEntry::mod13(sol);
    unsigned const  m15 = DBEntry::mod15(sol);
    uint64_t cand = DBEntry::count(sol);
    while((cand%13 != m13) || (cand%15 != m15))  cand += UINT64_C(1)<<44;
    out << "\tWRAPPED[%13=" << std::setw(2) << m13 << ", %15=" << std::setw(2) << m15 << " -> " << cand << ']';
  }
  return  out;

} // operator<<
