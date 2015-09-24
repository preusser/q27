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
package me.preusser.q27;

import  java.util.AbstractList;
import  java.util.List;
import  java.util.Formatter;

import  java.time.LocalDateTime;

import  java.io.DataOutput;
import  java.io.PrintWriter;

import  java.nio.ByteBuffer;
import  java.nio.LongBuffer;


public class MappedDatabase implements Database {

  private final LongBuffer  db;
  private int  ptr;

  private final IDMap<Object>  solvers;

  private final DataOutput   dupStream;
  private final PrintWriter  solverLog;

  public MappedDatabase(final ByteBuffer   db,
			final DataOutput   dupStream,
			final PrintWriter  solverLog) {
    final LongBuffer  ldb = db.asLongBuffer();
    if((ldb.limit()&1) == 0) {
      this.db         = ldb;
      this.solvers    = new IDMap<>(1<<12);
      this.dupStream  = dupStream;
      this.solverLog  = solverLog;
      return;
    }
    throw  new IllegalArgumentException("Truncated Buffer");
  }

  public List<? extends MappedEntry> asList() {
    return  new AbstractList<MappedEntry>() {
      public int size() {
	return  db.limit()>>1;
      }

      public MappedEntry get(int  idx) {
	idx <<= 1;
	return  new MappedEntry(db.get(idx)>>>20, idx);
      }
    };
  }

  @Override
  public MappedEntry fetchUnsolved() {
    final LongBuffer  db = this.db;

    int   ptr;
    long  cs;
    synchronized(db) {
      ptr = this.ptr;
      while(true) {
	if(ptr >= db.limit())  return  null;
	cs = db.get(ptr);
	if((((int)cs << 12) == 0) && (db.get(ptr+1) == 0L)) break;
	ptr += 2;
      }
      db.put(ptr, cs | timestamp(LocalDateTime.now()));
      this.ptr = ptr + 2;
    }
    return  new MappedEntry(cs>>>20, ptr);

  } // fetchUnsolved

  public void untakeStale(final int  timeout_min) {
    final int  cutoff = timestamp(LocalDateTime.now().minusMinutes(timeout_min));

    final LongBuffer  db = this.db;
    synchronized(db) {
      int  ptr = this.ptr;
      while(ptr > 0) {
	final long  solv = db.get(--ptr);
	final long  spec = db.get(--ptr);
	if((solv == 0) && ((((int)spec << 12) >>> 12) < cutoff)) {
	  db.put(ptr, (spec>>20)<<20);
	  this.ptr = ptr;
	}
      }
    }

  } // untakeStale

  private static int timestamp(final LocalDateTime  time) {
    return ((((((((((time.getYear()-2015)&3)) << 4) |
		 time.getMonthValue()) << 5) | time.getDayOfMonth()) << 5) |
	     time.getHour()) << 4) |(time.getMinute()/4);
  }

  private final class MappedEntry extends Entry {

    private final int  idx;

    public MappedEntry(final long  spec, final int  idx) {
      super(spec);
      this.idx = idx;
    }

    @Override
    public int hashCode() {
      return  idx;
    }

    @Override
    public boolean equals(final Object  o) {
      if(o instanceof MappedEntry) {
	final MappedEntry  oe = (MappedEntry)o;
	if(this.idx == oe.idx) {
	  if(MappedDatabase.this == oe.owner())  return  true;
	}
      }
      return  false;
    }

    private MappedDatabase owner() { return  MappedDatabase.this; }

    @Override
    public String toString() {
      final long  spec;
      final long  solv; {
	final LongBuffer  db = MappedDatabase.this.db;
	synchronized(db) {
	  spec = db.get(idx);
	  solv = db.get(idx+1);
	}
      }
      final StringBuilder  bld = new StringBuilder();
      final Formatter      fmt = new Formatter(bld);
      final int  time = ((int)spec << 12) >>> 12;

      fmt.format("0x%010X: ", spec >>> 25);
      if(time != 0) {
	fmt.format("%04d-%02d-%02d %02d:%02d ",
		   ((time >> 18)&3) + 2015,
		   (time >> 14) & 0x0F,
		   (time >>  9) & 0x1F,
		   (time >>  4) & 0x1F,
		   (time & 0xF)<<2);
      }
      if(solv == 0L)  bld.append(time == 0? "?" : "TAKEN");
      else {
	fmt.format("SOLVED by [%d]: %15d [%2d,%2d]",
		   (int)(solv >> 52), (solv << 20) >>> 20,
		   (int)(solv >> 48) & 0xF, (int)(solv >> 44));
      }
      return  bld.toString();
    }

    @Override
    public boolean solve(final Object  solver, long  res) {
      if((res < (1L<<52)) && (solver != null)) {
	{
	  final IDMap<Object>  solvers = MappedDatabase.this.solvers;
	  final int  sid;
	  synchronized(solvers) {
	    if(solvers.containsKey(solver))  sid = solvers.get(solver);
	    else {
	      sid = solvers.map(solver);
	      final LocalDateTime  now = LocalDateTime.now();
	      solverLog.printf("%04d-%02d-%02d %02d:%02d SOLVER #%4d: %s\n",
			       now.getYear(), now.getMonthValue(), now.getDayOfMonth(),
			       now.getHour(), now.getMinute(),
			       sid, solver);
	    }
	  }
	  res |= (long)sid << 52;
	}
	final long  spec = (getSpec() << 20) | timestamp(LocalDateTime.now());
	final LongBuffer  db   = MappedDatabase.this.db;
	final int         idx  = this.idx;
	synchronized(db) {
	  if(((db.get(idx)^spec)>>20) == 0L) {
	    if(db.get(idx+1) == 0L) {
	      db.put(idx,  spec);
	      db.put(idx+1, res);
	    }
	    else {
	      final DataOutput  dupStream = MappedDatabase.this.dupStream;
	      if(dupStream != null) {
		try {
		  dupStream.writeLong(spec);
		  dupStream.writeLong(res);
		}
		catch(final Exception  e) {
		  System.err.printf("Duplicate result: %010X: %013X by %s\n", spec>>>25, res, solver);
		}
	      }
	    }
	    return  true;
	  }
	}
      }
      System.err.printf("Result report error: %010X: %013X by %s\n", getSpec()>>>5, res, solver);
      return  false;

    } // solve()

  } // class MappedEntry

} // class MappedDatabase
