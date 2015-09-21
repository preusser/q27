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
#ifndef QUEENS_DATABASE_HPP
#define QUEENS_DATABASE_HPP

#include "DBEntry.hpp"

#include <boost/iostreams/device/mapped_file.hpp>

namespace queens {
  class Database {
    boost::iostreams::mapped_file  db;
    DBEntry *const  m_beg;
    DBEntry *const  m_end;

    DBEntry *m_ptr;

  public:
    Database(char const *file)
      : db(file),
	m_beg(reinterpret_cast<DBEntry*>(db.data())),
	m_end(m_beg + db.size()/sizeof(DBEntry)),
	m_ptr(m_beg) {}
    ~Database() {}

  public:
    size_t         size()  const { return  m_end - m_beg; }
    DBEntry const *begin() const { return  m_beg; }
    DBEntry const *end()   const { return  m_end; }
    DBEntry *begin() { return  m_beg; }
    DBEntry *end()   { return  m_end; }

  public:
    DBEntry       *takeCase();
    void           untakeStaleCases(unsigned  timeout_min);

    // These search functions requires the Database to be ordered.
    DBEntry const *findCase(uint64_t  spec) const;
    DBEntry       *findCase(uint64_t  spec);
  };
}
#endif
