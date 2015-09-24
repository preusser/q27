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
#ifndef QUEENS_SYMMETRY_HPP
#define QUEENS_SYMMETRY_HPP

namespace queens {
  class Symmetry {
  private:
    static char const *const  NAMES[];

  public:
    static unsigned const  NONE   = 3;
    static unsigned const  POINT  = 2;
    static unsigned const  ROTATE = 1;

  private:
    unsigned  m_val;

  public:
    Symmetry(unsigned  val) : m_val(val) {}
    ~Symmetry() {}
    operator unsigned() const { return  m_val; }
    operator char const*() const {
      return  NAMES[m_val&3];
    }

  public:
    unsigned weight() const { return 1 << m_val; }

  public:
    static class range_t {
    public:
      class range_iter {
	unsigned  m_val;
      public:
	range_iter(unsigned  val) : m_val(val) {}
	~range_iter() {}
      public:
	Symmetry operator*() const { return  m_val; }
	range_iter &operator++() {
	  m_val--;
	  return *this;
	}
	range_iter operator++(int) {
	  range_iter const  old = *this;
	  m_val--;
	  return  old;
	}
	bool operator!=(range_iter const &o) const {
	  return  m_val != o.m_val;
	}
      };
    public:
      static range_iter begin() { return  range_iter(3); }
      static range_iter end()   { return  range_iter(0); }
    }  RANGE;
  };
}

#endif
