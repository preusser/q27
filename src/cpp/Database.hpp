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
#ifndef QUEENS_DATABASE_HPP
#define QUEENS_DATABASE_HPP

#include "DBEntry.hpp"

#include <boost/iostreams/device/mapped_file.hpp>

namespace queens {

  class DBConstRange {
    DBEntry const *m_beg;
    DBEntry const *m_end;

  public:
    DBConstRange(DBEntry const *const  beg, DBEntry const *const  end)
      : m_beg(beg), m_end(end) {}
    ~DBConstRange() {}

  public:
    size_t         size()  const { return  m_end - m_beg; }
    DBEntry const *begin() const { return  m_beg; }
    DBEntry const *end()   const { return  m_end; }

    // The search bounds requires a sorted DBRange.
    DBEntry const *lub(uint64_t  spec) const;
    DBEntry const *glb(uint64_t  spec) const;
  };

  class DBRange : public DBConstRange {

  public:
    DBRange(DBEntry *const  beg, DBEntry *const  end)
      : DBConstRange(beg, end) {}
    ~DBRange() {}

  public:
    DBEntry *begin() const { return  const_cast<DBEntry*>(DBConstRange::begin()); }
    DBEntry *end()   const { return  const_cast<DBEntry*>(DBConstRange::end()); }

    // The search bounds requires a sorted DBRange.
    DBEntry *lub(uint64_t  spec) { return  const_cast<DBEntry*>(DBConstRange::lub(spec)); }
    DBEntry *glb(uint64_t  spec) { return  const_cast<DBEntry*>(DBConstRange::glb(spec)); }
  };

  class Database : private boost::iostreams::mapped_file {
  public:
    Database(char const *file, boost::iostreams::mapped_file::mapmode  mode)
      : boost::iostreams::mapped_file(file, mode) {}
    ~Database() {}

  public:
    size_t size() const {
      return  boost::iostreams::mapped_file::size()/sizeof(DBEntry);
    }
    DBConstRange roRange() const {
      DBEntry const *const  beg = reinterpret_cast<DBEntry const*>(boost::iostreams::mapped_file::const_data());
      return DBConstRange(beg, beg+size());
    }
    DBRange rwRange() {
      DBEntry *const  beg = reinterpret_cast<DBEntry*>(boost::iostreams::mapped_file::data());
      return  DBRange(beg, beg == nullptr? nullptr : beg+size());
    }
  };
}
#endif
