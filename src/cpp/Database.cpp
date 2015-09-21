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
#include "Database.hpp"

using namespace queens;

DBEntry *Database::takeCase() {
  while(m_ptr->taken()) {
    if(m_ptr < m_end)  m_ptr++;
    else  return  nullptr;
  }
  m_ptr->take();
  return  m_ptr++;
}

void Database::untakeStaleCases(unsigned  timeout_min) {
  unsigned  cutoff; {
    struct tm  ptm;
    time_t  rawtime = time(NULL) - 60*timeout_min;
    gmtime_r(&rawtime, &ptm);
    cutoff = ((((((((ptm.tm_year-115)&3 << 4) | (ptm.tm_mon+1)) << 5) | ptm.tm_mday) << 5) |  ptm.tm_hour) << 4) | (ptm.tm_min/4);
  }

  for(DBEntry *ptr = m_ptr; ptr >= m_beg; ptr--) {
    if(ptr->taken() && !ptr->solved() && (ptr->time() < cutoff)) {
      ptr->untake();
      m_ptr = ptr;
    }
  }
}

DBEntry const *Database::findCase(uint64_t  spec) const {
  spec |= UINT64_C(0x1F);
  DBEntry const *lo = m_beg;   if(spec <  lo->spec())  return  nullptr;
  DBEntry const *hi = m_end-1; if(spec >= hi->spec())  return  hi;

  // Invariant: lo->spec() <= spec < hi->spec()
  while(true) {
    size_t const  m = (hi-lo)/2;
    if(m == 0)  return  lo;
    DBEntry const *const  mid = lo+m;
    if(spec < mid->spec())  hi = mid;
    else                    lo = mid;
  }
}

DBEntry *Database::findCase(uint64_t  spec) {
  return  const_cast<DBEntry*>(static_cast<Database const*>(this)->findCase(spec));
}
