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
#ifndef _QUEENS_BOARD_HPP
#define _QUEENS_BOARD_HPP

#include <cstdint>
#include <iostream>

#include <assert.h>

namespace queens {
  class Board {
  public:
    unsigned const  N;

  private:
    signed *const  board;

    uint64_t  bv;
    uint64_t  bh;
    uint64_t  bu;
    uint64_t  bd;

  public:
    Board(unsigned const  dim)
      : N(dim), board(new signed[dim]),
	bv(0), bh(0), bu(0), bd(0) {
      for(unsigned  i = 0; i < dim; board[i++] = -1);
    }
    ~Board() {
      delete [] board;
    }

  private:
    class Cell {
      signed         &col;
      unsigned const  y;

    public:
      Cell(signed &_col, unsigned const _y) : col(_col), y(_y) {}
      ~Cell() {}

    public:
      operator bool() const { return  col == (signed)y; }
      Cell& operator=(bool const  v) {
	if(v) {
	  assert(col == -1);
	  col = (signed)y;
	}
	else {
	  assert(col == (signed)y);
	  col = -1;
	}
	return *this;
      }
    }; // class Cell

  public:
    bool operator()(unsigned  x, unsigned  y) const {
      return  board[x]==(signed)y;
    }
  private:
    Cell operator()(unsigned  x, unsigned  y) {
      return  Cell(board[x], y);
    }

  public:
    class Placement {
      Board &parent;

    public:
      unsigned const  x;
      unsigned const  y;

    private:
      bool  valid;
      bool  owner;

    private:
      friend class Board;
      Placement(Board &_parent, unsigned const _x, unsigned const _y)
	: parent(_parent), x(_x), y(_y) {
	if(parent(x, y)) {
	  // Duplicate Placement
	  valid = true;
	  owner = false;
	  return;
	}

	// Check Validity of new Placement
	uint64_t const  bv = UINT64_C(1)<<x;
	uint64_t const  bh = UINT64_C(1)<<y;
	uint64_t const  bu = UINT64_C(1)<<(parent.N-1-x+y);
	uint64_t const  bd = UINT64_C(1)<<(           x+y);
	if((parent.bv&bv)||(parent.bh&bh)||(parent.bu&bu)||(parent.bd&bd)) {
	  valid = false;
	  owner = false;
	  return;
	}
	parent(x, y) = true;
	parent.bv |= bv;
	parent.bh |= bh;
	parent.bu |= bu;
	parent.bd |= bd;
	valid = true;
	owner = true;
      }
    public:
      ~Placement() {
	if(owner) {
	  parent.bv ^= UINT64_C(1)<<x;
	  parent.bh ^= UINT64_C(1)<<y;
	  parent.bu ^= UINT64_C(1)<<(parent.N-1-x+y);
	  parent.bd ^= UINT64_C(1)<<(           x+y);
	  parent(x, y) = false;
	}
      }

    public:
      operator bool() { return  valid; }

    }; // class Placement

    Placement place(unsigned  x, unsigned  y) {
      return  Placement(*this, x, y);
    }

    uint64_t getBV() const { return  bv; }
    uint64_t getBH() const { return  bh; }
    uint64_t getBU() const { return  bu; }
    uint64_t getBD() const { return  bd; }

    unsigned coronal(int8_t *buf, unsigned  rings) const {
      if(rings > N)  rings = N;

      for(unsigned  x = 0; x < rings; x++) {
	*buf++ = board[x];
      }
      for(unsigned  y = N; y-- > N-rings;) {
	*buf = -1;
	for(unsigned  x = 0; x < N; x++) {
	  if(operator()(x, y)) { *buf = x; break; }
	}
	buf++;
      }
      for(unsigned  x = N; x-- > N-rings;) {
	*buf++ = N-1-board[x];
      }
      for(unsigned  y = 0; y < rings; y++) {
	*buf = -1;
	for(unsigned  x = 0; x < N; x++) {
	  if(operator()(x, y)) { *buf = N-1-x; break; }
	}
	buf++;
      }
      return  N;

    } // coronal

  }; // class Board

  std::ostream& operator<<(std::ostream &out, Board const &brd) {
    unsigned const  N = brd.N;
    for(unsigned  y = N; y-- > 0;) {
      for(unsigned  x = 0; x < N; x++) {
	out << (brd(x, y)? 'Q' : '.');
      }
      out << std::endl;
    }
    return  out;
  }

  std::ostream& operator<<(std::ostream &out, Board::Placement const &p) {
    out << '(' << p.x << ',' << p.y << ')';
    return  out;
  }

} // namespace queens

#endif
