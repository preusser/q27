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
// If TRACE is defined the search tree expansion is traced to std::cerr.
#undef TRACE
//#define TRACE

#include <cstdint>
#include <cassert>
#include <memory>
#include <iostream>
#include <iomanip>
#include <fstream>

#include <string.h>

#include "Board.hpp"
#include "DBEntry.hpp"

using namespace queens;


namespace {

  class Action {
  protected:
    Action() {}
  public:
    virtual ~Action() {}

  public:
    void operator()(Board const &brd, Symmetry  sym) {
      this->process(brd, sym);
    }

  protected:
    virtual void process(Board const &brd, Symmetry  sym) = 0;
    virtual void dump(std::ostream &out) const = 0;
    friend std::ostream& operator<<(std::ostream &out, Action const &act);
  };

  class Explorer : public Action {
    uint64_t         pre[4];
    uint64_t *const  cnt;

  public:
    Explorer(bool const &full) : cnt(full? new uint64_t[4] : 0) {
      for(Symmetry  s : Symmetry::RANGE)  pre[s] = 0;
    }
    ~Explorer() {}

  protected:
    void process(Board const &brd, Symmetry  sym) {
      pre[sym]++;
      if(cnt) {
	unsigned const  N = brd.N;
	cnt[sym] += countCompletions(brd.getBV() >> 2,
				     ((((brd.getBH()>>2)|(~0<<(N-4)))+1)<<(brd.N-5))-1,
				     brd.getBU()>>4,
				     (brd.getBD()>>4)<<(N-5));
      }
    } // process()

    void dump(std::ostream &out) const {
      uint64_t  total_pre;
      uint64_t  total_cnt;

      out << "Symmetry     Seeds";
      total_pre = 0;
      if(cnt) {
	out << "          Boards";
	total_cnt = 0;
      }
      out << "\n-----\n";

      for(Symmetry  s : Symmetry::RANGE) {
	out << (char const*)s << '\t' << std::right << std::setw(10) << pre[s];
	total_pre += pre[s];
	if(cnt) {
	  unsigned const  w = s.weight();
	  out << '\t' << std::right << std::setw(10) << cnt[s] << '*' << w;
	  total_cnt += w*cnt[s];
	}
	out << '\n';
      }
      out << "-----\nTOTAL\t" << std::right << std::setw(10) << total_pre;
      if(cnt)  out << '\t' << std::right << std::setw(12) << total_cnt;
      out << '\n';
    }

  private:
    static uint64_t countCompletions(uint64_t  bv,
				     uint64_t  bh,
				     uint64_t  bu,
				     uint64_t  bd) {

      // Placement Complete?
      if(bh+1 == 0)  return  1;

      // -> at least one more queen to place
      while((bv&1) != 0) { // Column is covered by pre-placement
	bv >>= 1;
	bu <<= 1;
	bd >>= 1;
      }
      bv >>= 1;

      // Column needs to be placed
      uint64_t  cnt = 0;
      for(uint64_t  slots = ~(bh|bu|bd); slots != 0;) {
	uint64_t const  slot = slots & -slots;
	cnt   += countCompletions(bv, bh|slot, (bu|slot) << 1, (bd|slot) >> 1);
	slots ^= slot;
      }
      return  cnt;

    } // countCompletions()
  };

  class DBCreator : public Action {

    std::fstream  out;
    uint64_t      cnt;

  public:
    DBCreator(char const *const  filename) : out(filename, std::ofstream::out), cnt(0) {}
    ~DBCreator() {
      out.close();
    }

  protected:
    void process(Board const &brd, Symmetry  sym) {
      int8_t  PRE2[8];
      brd.coronal(PRE2, 2);
      DBEntry const  entry(PRE2, sym);
      out.write((char const*)&entry, sizeof(entry));
      cnt++;
    } // process()

    void dump(std::ostream &out) const {
      out << "Wrote " << cnt << " Entries." << std::endl;
    }
  }; // class DBCreator

  std::ostream& operator<<(std::ostream &out, Action const &act) {
    act.dump(out);
    return  out;
  }

  Action* parseAction(char const *const  arg) {
    if(strncmp(arg, "-db:", 4) == 0) {
      return  new DBCreator(arg+4);
    }
    return  new Explorer(strcmp(arg, "-x") == 0);
  } // parseAction
}

int main(int const  argc, char const* const argv[]) {
  unsigned const  N = argc < 2? 0 : (unsigned)strtoul(argv[argc-1], 0, 0);

  // Check Arguments
  if((N < 5) || (32 < N)) {
    std::cerr << argv[0] <<
      " [-x|-db:<file>] <board dimension from 5..32>\n\n"
      "\t-x\tExplore pre-placements and count solutions.\n"
      "\t-db\tGenerate a Database of the pre-placements.\n"
	      << std::endl;
    return  1;
  }
  std::cout << N << "-Queens Puzzle\n" << std::endl;
  std::unique_ptr<Action>  act(parseAction(argv[1]));

 /**
  * The number of valid pre-placements in two adjacent columns (rows) is
  * 2*(N-2) + (N-2)*(N-3) for the outmost and inner positions in the the
  * first column, respectively. Thus, the total is (N-2)*(N-1).
  */
  struct pres_t {
    char unsigned  a;
    char unsigned  b;
  };
  std::unique_ptr<pres_t[]>  pres(new pres_t[(N-2)*(N-1)]);

  { // Compute all valid two-column pre-placements in order:
    // (a0, b0) < (a1, b1) if a0<a1 || (a0==a1 && b0<b1)
    unsigned  idx = 0;
    for(unsigned  a = 0; a < N; a++) {
      for(unsigned  b = 0; b < N; b++) {
	if(abs(a-b) <= 1)  continue;
	pres[idx].a = a;
	pres[idx].b = b;
	idx++;
      }
    }
    assert(idx == (N-2)*(N-1)); // Wrong number of pre-placements
  }
  std::cout << "First side bound: ("
	    << (unsigned)pres[(N/2)*(N-3)  ].a << ", " << (unsigned)pres[(N/2)*(N-3)  ].b << ") / ("
	    << (unsigned)pres[(N/2)*(N-3)+1].a << ", " << (unsigned)pres[(N/2)*(N-3)+1].b << ')'
	    << std::endl;

  // Generate coronal Placements
  Board  board(N);
  for(unsigned  w = 0; w <= (N/2)*(N-3); w++) {
    unsigned const  wa = pres[w].a;
    unsigned const  wb = pres[w].b;
#ifdef TRACE
    std::cerr << '(' << wa << ", " << wb << ')' << std::endl;
#else
    std::cout << "\rProgress: " << w << '/' << ((N/2)*(N-3)) << std::flush;
#endif

    Board::Placement  pwa(board.place(0, wa));
    Board::Placement  pwb(board.place(1, wb));
    assert(pwa && pwb);  // NO conflicts on first side possible

    for(unsigned  n = w; n < (N-2)*(N-1)-w; n++) {
      unsigned const  na = pres[n].a;
      unsigned const  nb = pres[n].b;
#ifdef TRACE
      std::cerr << '(' << wa << ", " << wb << ')'
		<< '(' << na << ", " << nb << ')' << std::endl;
#endif

      Board::Placement  pna(board.place(na, N-1)); if(!pna)  continue;
      Board::Placement  pnb(board.place(nb, N-2)); if(!pnb)  continue;

      for(unsigned  e = w; e < (N-2)*(N-1)-w; e++) {
	unsigned const  ea = pres[e].a;
	unsigned const  eb = pres[e].b;
#ifdef TRACE
	std::cerr << '(' << wa << ", " << wb << ')'
		  << '(' << na << ", " << nb << ')'
		  << '(' << ea << ", " << eb << ')' << std::endl;
#endif

	Board::Placement  pea(board.place(N-1, N-1-ea)); if(!pea)  continue;
	Board::Placement  peb(board.place(N-2, N-1-eb)); if(!peb)  continue;

	for(unsigned  s = w; s < (N-2)*(N-1)-w; s++) {
	  unsigned const  sa = pres[s].a;
	  unsigned const  sb = pres[s].b;
#ifdef TRACE
	  std::cerr << '(' << wa << ", " << wb << ')'
		    << '(' << na << ", " << nb << ')'
		    << '(' << ea << ", " << eb << ')'
		    << '(' << sa << ", " << sb << ')' << std::endl;
#endif

	  Board::Placement  psa(board.place(N-1-sa, 0)); if(!psa)  continue;
	  Board::Placement  psb(board.place(N-1-sb, 1)); if(!psb)  continue;

	  // We have a successful complete pre-placement with
	  //   w <= n, e, s < (N-2)*(N-1)-w
	  //
	  // Thus, the placement is definitely a canonical minimum unless
	  // one or more of n, e, s are equal to w or (N-2)*(N-1)-1-w.

	  { // Check for minimum if n, e, s = (N-2)*(N-1)-1-w
	    unsigned const  ww = (N-2)*(N-1)-1-w;
	    if(s == ww) {
	      // check if flip about the up diagonal is smaller
	      if(n < (N-2)*(N-1)-1-e) {
		//print('S', wa, wb, na, nb, ea, eb, sa, sb);
		continue;
	      }
	    }
	    if(e == ww) {
	      // check if flip about the vertical center is smaller
	      if(n > (N-2)*(N-1)-1-n) {
		//print('E', wa, wb, na, nb, ea, eb, sa, sb);
		continue;
	      }
	    }
	    if(n == ww) {
	      // check if flip about the down diagonal is smaller
	      if(e > (N-2)*(N-1)-1-s) {
		//print('N', wa, wb, na, nb, ea, eb, sa, sb);
		continue;
	      }
	    }
	  }

	  // Check for minimum if n, e, s = w
	  if(s == w) {
	    // right rotation is smaller unless  w = n = e = s
	    if((n != w) || (e != w)) {
	      //print('s', wa, wb, na, nb, ea, eb, sa, sb);
	      continue;
	    }
	    (*act)(board, Symmetry::ROTATE);
	    continue;
	  }
	  if(e == w) {
	    // check if 180°-rotation is smaller
	    if(n >= s) {
	      if(n > s) {
		//print('e', wa, wb, na, nb, ea, eb, sa, sb);
		continue;
	      }
	      (*act)(board, Symmetry::POINT);
	      continue;
	    }
	  }
	  // n = w is okay

	  //print('o', wa, wb, na, nb, ea, eb, sa, sb);
	  (*act)(board, Symmetry::NONE);

	} // s
      } // e
    } // n
  } // w

  std::cout << "\n\n" << *act << std::endl;
}
