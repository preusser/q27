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
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <map>

#include <string.h>

#include "Database.hpp"
#include "range/RangeParser.hpp"
#include "range/IR.hpp"

using namespace queens;
using namespace queens::range;

namespace {

  char const *prog = "q27db";

  // Usage Output
  void usage() {
    std::cout << prog << " <queens.db>\tstats\n"
      "\t\t\tfreq\n"
      "\t\t\tslice <output.db> [taken|stale <timeout_min>]\n"
      "\t\t\tuntake\n"
      "\t\t\tmerge <contrib.db> <secondary.db>\n"
      "\t\t\tprint <range> ...\n"
	      << std::endl;
    exit(1);
  }

  int stats(Database &dbx, int const  argc, char const *const  argv[]) {
    DBConstRange const  db(dbx.roRange());
    unsigned     const  total = db.size();

    std::cout << "Scanning " << total << " entries ..." << std::endl;

    // Entry Statistics
    unsigned  invalid = 0;
    unsigned  taken   = 0;
    unsigned  solved  = 0;
    unsigned  wrapped = 0;
    unsigned  gapped  = 0;
    DBEntry const *gapStart = nullptr;

    // Solution Count Totals
    uint64_t  count    = 0L; // fundamental solutions
    unsigned  mod13    = 0;
    unsigned  mod15    = 0;
    uint64_t  countAll = 0L; // all solutions
    unsigned  mod13All = 0;
    unsigned  mod15All = 0;

    for(DBEntry const&  e : db) {
      // Statistics
      if(!e.valid())  invalid++;

      if(!e.solved()) {
	if(e.taken())  taken++;

	if(gapStart == nullptr)  gapStart = &e;
      }
      else {
	solved++;
	if(e.wrapped())  wrapped++;
	uint64_t const  cnt = e.count();
	unsigned const  m13 = e.mod13();
	unsigned const  m15 = e.mod15();
	count += cnt;
	mod13  = (mod13 + m13)%13;
	mod15  = (mod15 + m15)%15;

	unsigned const  w = e.sym().weight();
	countAll += w*cnt;
	mod13All  = (mod13All + w*m13)%13;
	mod15All  = (mod15All + w*m15)%15;

	if(gapStart != nullptr) {
	  gapped  += &e - gapStart;
	  gapStart = nullptr;
	}
      }
    }

    if(invalid)  std::cout << "! INVALID: " << invalid << '\n';
    if(wrapped)  std::cout << "! WRAPPED: " << wrapped << '\n';
    if(gapped)   std::cout << "Entries in unsolved gaps: " << gapped << '\n';
    std::cout << "\nTaken:\t" << std::setw(9) << taken
	      << "\nSolved:\t"  << std::setw(9)<< solved << " / " << total
	      << " (" << std::setprecision(3) << (100.0*solved/total) << "%)"
                 "\nFundamental Solutions: " << std::setw(16) << count
	      << " [" << std::setw(2) << mod13 << ':' << std::setw(2) << mod15 << "] O"
	      << ((count%13 == mod13) && (count%15 == mod15)? "K" : "VERFLOW")
              << "\nTotal       Solutions: " << std::setw(16) << countAll
	      << " [" << std::setw(2) << mod13All << ':' << std::setw(2) << mod15All << "] O"
	      << ((countAll%13 == mod13All) && (countAll%15 == mod15All)? "K" : "VERFLOW")
	      << std::endl;

    return  invalid||wrapped;

  } // stats()

  int freq(Database &dbx, int const  argc, char const *const  argv[]) {
    DBConstRange const  db(dbx.roRange());
    std::map<unsigned, unsigned>  hist;
    for(DBEntry const &e : db) {
      if(e.solved())  hist[e.time()]++;
    }
    unsigned  cumm = 0;
    unsigned  date = 0;
    std::cout << std::setfill('0');
    for(auto const &e : hist) {
      unsigned const  k = e.first;
      unsigned const  v = e.second;
      cumm += v;
      std::cout << k << '\t' << v << '\t' << cumm;
      if((k>>9) != date) {
	date = k >> 9;
	std::cout << '\t' << 2015+(date>>9) << '-'
		  << std::setw(2) << (0xF&(date>>5)) << '-'
		  << std::setw(2) << (date & 0x1F);
      }
      std::cout << '\n';
    }
    std::cout << std::flush;
    return  0;

  } // freq()

  int slice(Database &dbx, int const  argc, char const *const  argv[]) {
    DBConstRange const  db(dbx.roRange());
    if(argc >= 2) {
      std::ofstream   out(argv[0]);
      char const *cmd = argv[1];

      // Slice out taken Entries
      if(strcmp(cmd, "taken") == 0) {
	for(DBEntry const &e : db) {
	  if(e.taken() && !e.solved()) {
	    out.write((char const*)&e, sizeof(DBEntry));
	  }
	}
	return  0;
      }

      // Slice out stale Entries
      if((strcmp(cmd, "stale") == 0) && (argc == 3)) {
	unsigned  timeout;
	if(sscanf(argv[2], "%u", &timeout) == 1) {
	  unsigned  cutoff; {
	    struct tm  ptm;
	    time_t  rawtime = time(NULL) - 60*timeout;
	    gmtime_r(&rawtime, &ptm);
	    cutoff = ((((((((ptm.tm_year-115)&3 << 4) | (ptm.tm_mon+1)) << 5) | ptm.tm_mday) << 5) |  ptm.tm_hour) << 4) | (ptm.tm_min/4);
	  }
	  for(DBEntry const &e : db) {
	    if(e.taken() && !e.solved() && (e.time() < cutoff)) {
	      out.write((char const*)&e, sizeof(DBEntry));
	    }
	  }
	  return  0;
	}
      }
    }
    usage();
    return  1;
  }

  int untake(Database &dbx, int const  argc, char const *const  argv[]) {
    DBRange  db(dbx.rwRange());
    uint64_t  cnt = 0L;
    for(DBEntry &e : db) {
      if(e.taken() && !e.solved()) {
	e.untake();
	cnt++;
      }
    }
    std::cout << cnt << " entries untaken." << std::endl;
    return  0;

  }  // untake()

  int unsolve(Database &dbx, int const  argc, char const *const  argv[]) {
    if((argc != 1) || (strcmp(*argv, "-f") != 0)) {
      std::cerr << "Refusing to unsolve database without explicit '-f' switch." << std::endl;
      return  1;
    }
    DBRange  db(dbx.rwRange());
    uint64_t  cnt = 0L;
    for(DBEntry &e : db) {
      if(e.taken() || e.solved()) {
        e.unsolve();
        cnt++;
      }
    }
    std::cout << cnt << " entries unsolved." << std::endl;
    return  0;

  }  // unsolve()

  int merge(Database &dbx, int const  argc, char const *const  argv[]) {
    DBRange  db(dbx.rwRange());
    if(argc == 2) {
      Database     const  mergex(argv[0], boost::iostreams::mapped_file::readonly);
      DBConstRange const  merge (mergex.roRange());
      std::ofstream       dups  (argv[1], std::ofstream::out|std::ofstream::app);

      unsigned  merged    = 0;
      unsigned  identical = 0;
      unsigned  confirmed = 0;
      unsigned  conflicts = 0;
      unsigned  notfound  = 0;

      for(DBEntry const &e : merge) {
	if(e.solved()) {
	  DBEntry *const  target = db.glb(e.spec());
	  if((target == nullptr) || (target->spec() != e.spec()))  notfound++;
	  else { // We have the exact corresponding entry

	    if(!target->solved()) {             // New contribution: merge
	      *target = e;
	      merged++;
	    }
	    else if(*target == e) {             // Identical entries
	      identical++;
	    }
	    else {                              // Secondary solution: check
	      if(target->count() == e.count())  confirmed++;
	      else {
		std::cerr << "Conflict:\n\t" << *target << "\n\t" << e << std::endl;
		conflicts++;
	      }
	      dups.write((char const*)&e, sizeof(DBEntry));
	    }

	  }
	}
      }
      if(notfound||identical) {
	std::cout << "Ignored Entries:\n";
	if(notfound)   std::cout << '\t' << std::setw(9) << notfound  << " NOT found\n";
	if(identical)  std::cout << '\t' << std::setw(9) << identical << " identical\n";
	std::cout << std::endl;
      }
      if(confirmed||conflicts) {
	std::cout << "Duplicate Solutions:\n";
	if(confirmed)  std::cout << '\t' << std::setw(9) << confirmed << " confirmed\n";
	if(conflicts)  std::cout << '\t' << std::setw(9) << conflicts << " CONFLICTS\n";
	std::cout << std::endl;
      }
      std::cout << "New Contributions:\n\t" << std::setw(9) << merged << " Entries\n"
		<< std::endl;

      return  conflicts == 0L;
    }
    usage();
    return  1;

  } // merge()

  int print(Database &dbx, int const  argc, char const *const  argv[]) {
    if(argc > 0) {
      DBConstRange         range(dbx.roRange());
      DBEntry const *const beg = range.begin();

      { // Parse range restrictions
	RangeParser  parser;
	for(int  i = 0; i < argc; i++) {
	  try {
	    range = parser.parse(argv[i])->resolve(range);
	  }
	  catch(ParseException const &e) {
	    std::cerr << "Exception parsing the range specification:\n"
		      << "\t'" << argv[0] << "' @" << e.position() << ": " << e.message()
		      << std::endl;
	    return  1;
	  }
	}
      }
      { // Output Count
	unsigned const  n = range.size();
	std::cout << n << " Entr" << (n==1? "y" : "ies") << std::endl;
      }
      // Output Entries
      for(DBEntry const &e : range) {
	std::cout << '@' << std::setw(10) << (&e-beg) << ": " << e << std::endl;
      }
      return  0;
    }
    usage();
    return  1;

  } // print()

  int queens(Database &dbx, int const  argc, char const *const  argv[]) {
    unsigned  len = 0;
    unsigned  prv = 0;
    for(DBEntry const &e : dbx.roRange()) {
      unsigned const  q = e.queens();
      if(q == prv)  len++;
      else {
	if(len > 1)  std::cout << ' ' << len;
	std::cout << std::endl << q;
	len = 1;
	prv = q;
      }
    }
    if(len > 1)  std::cout << ' ' << len;
    std::cout << std::endl;
    return  0;
  } // queens()

  struct {
    char const *cmd;
    int(*fct)(Database&, int, char const*const*);
    boost::iostreams::mapped_file::mapmode  mode;
  } const  COMMANDS[] = {
    {"freq",   freq,   boost::iostreams::mapped_file::readonly},
    {"print",  print,  boost::iostreams::mapped_file::readonly},
    {"slice",  slice,  boost::iostreams::mapped_file::readonly},
    {"stats",  stats,  boost::iostreams::mapped_file::readonly},
    {"queens", queens, boost::iostreams::mapped_file::readonly},
    {"untake", untake, boost::iostreams::mapped_file::readwrite},
    {"unsolve",unsolve,boost::iostreams::mapped_file::readwrite},
    {"merge",  merge,  boost::iostreams::mapped_file::readwrite}
  };

} // anonymous namespace

int main(int const  argc, char const *const  argv[]) {
  prog = *argv;
  if(argc >= 3) {
    char const *const  cmd = argv[2];

    for(auto const &c : COMMANDS) {
      if(strcmp(cmd, c.cmd) == 0) {
	Database  db(argv[1], c.mode);
	return  c.fct(db, argc-3, argv+3);
      }
    }
    std::cerr << "Unknown command: " << cmd << "\n\n";
  }
  usage();
  return  1;

} // main()
