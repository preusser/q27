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
      "\t\t\tprint <range>\n"
	      << std::endl;
    exit(1);
  }

  int stats(DBConstRange const &db) {
    unsigned const  total = db.size();

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

      /*
      // Printing
      if(print) {
	uint64be_t const  pre = e.spec() >> 5;
	uint8_t const *pp = ((uint8_t const*)&pre) + 3;
	std::cout << std::hex << std::setfill('0');
	for(unsigned i = 0; i < 5; i++) {
	  std::cout << "0x" << std::setw(2) << (unsigned)pp[i] << ' ';
	}
	std::cout << std::dec << std::setfill(' ') << std::setw(10) << e.count() << std::endl;
      }
      */
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

  int freq(DBConstRange const &db) {
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
		  << std::setw(2) << 1+(0xF&(date>>5)) << '-'
		  << std::setw(2) << (date & 0x1F);
      }
      std::cout << '\n';
    }
    std::cout << std::flush;
    return  0;

  } // freq()

  int slice(DBConstRange const &db, int const  argc, char const *const  argv[]) {
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

  int untake(Database &db) {
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

  int merge(Database &db, int const  argc, char const *const  argv[]) {
    if(argc == 2) {
      Database const  merge(argv[0]);
      std::ofstream   dups (argv[1], std::ofstream::out|std::ofstream::app);

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

  int print(DBConstRange const &db, int const  argc, char const *const  argv[]) {
    if(argc == 1) {
      try {
	std::shared_ptr<SRange>  range(RangeParser::parse(argv[0]));
	for(DBEntry const &e : range->resolve(db)) {
	  std::cout << '@' << std::setw(10) << (&e-db.begin()) << ": " << e << std::endl;
	}
	return  0;
      }
      catch(ParseException const &e) {
	std::cerr << "Exception parsing the range specification:\n"
		  << "\t'" << argv[0] << "' @" << e.position() << ": " << e.message()
		  << std::endl;
      }
      return  1;
    }
    usage();
    return  1;

  } // print()

} // anonymous namespace

int main(int const  argc, char const *const  argv[]) {
  prog = *argv;
  if(argc >= 3) {
    Database           db(argv[1]);
    char const *const  cmd = argv[2];

    if     (strcmp(cmd, "stats" ) == 0)  return  stats(db);
    else if(strcmp(cmd, "freq"  ) == 0)  return  freq(db);
    else if(strcmp(cmd, "slice" ) == 0)  return  slice(db, argc-3, argv+3);
    else if(strcmp(cmd, "untake") == 0)  return  untake(db);
    else if(strcmp(cmd, "merge" ) == 0)  return  merge(db, argc-3, argv+3);
    else if(strcmp(cmd, "print" ) == 0)  return  print(db, argc-3, argv+3);
    else {
      std::cerr << "Unknown command: " << cmd << "\n\n";
    }
  }
  usage();
  return  1;

} // main()
