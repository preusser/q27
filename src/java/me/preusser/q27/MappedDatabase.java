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

import  java.lang.ref.SoftReference;

import  java.util.AbstractList;
import  java.util.List;
import  java.util.Formatter;

import  java.time.LocalDateTime;

import  java.io.DataOutput;
import  java.io.PrintWriter;
import  java.io.IOException;

import  java.nio.ByteBuffer;
import  java.nio.LongBuffer;
import  java.nio.channels.FileChannel;


public class MappedDatabase implements Database {

  private static final int  MAPPING_SIZE = 1<<22;

  //+ Underlying Database File
  private final FileChannel                  db;
  private final SoftReference<LongBuffer>[]  mappings;

  private int         ptrIdx;
  private LongBuffer  ptrBuf;
  private int         ptrOfs;

  //+ Auxiliary Outputs
  private final DataOutput   dupStream;
  private final PrintWriter  solverLog;

  //+ Solver IDs
  private final IDMap<Object>  solvers;

  public MappedDatabase(final FileChannel  db,
			final DataOutput   dupStream,
			final PrintWriter  solverLog) throws IOException {

    final long  size = db.size();
    if((size > 0) && (((int)size & 7) == 0)) {
      this.db       = db;
      this.mappings = new SoftReference[(int)((size-1)/MAPPING_SIZE)+1];

      this.ptrIdx = -1;
      this.ptrBuf = LongBuffer.allocate(0);

      this.dupStream  = dupStream;
      this.solverLog  = solverLog;

      this.solvers = new IDMap<>(1<<12);
      return;
    }
    throw  new IllegalArgumentException("Truncated Buffer");
  }

  @Override
  public MappedEntry fetchUnsolved() {
    try {
      final FileChannel  db = this.db;

      synchronized(db) {
	LongBuffer  buf = this.ptrBuf;
	int         ofs = this.ptrOfs;

	while(true) {
	  // Need to go to next mapping
	  if(ofs >= buf.limit()) {
	    final SoftReference<LongBuffer>[]  mappings = this.mappings;

	    final int  nidx = this.ptrIdx+1;
	    if(nidx >= mappings.length)  return  null;
	    final SoftReference<LongBuffer>  ref = mappings[nidx];
	    if((ref == null) || ((buf = ref.get()) == null)) {
	      final long  base = nidx*(long)MAPPING_SIZE;
	      long  len = db.size() - base;
	      if(len > MAPPING_SIZE)  len = MAPPING_SIZE;

	      mappings[this.ptrIdx = nidx] = new SoftReference(
		       this.ptrBuf = buf = db.map(FileChannel.MapMode.READ_WRITE,
						  base, len).asLongBuffer());
	    }
	    ofs = 0;
	  }

	  final long  cs;
	  synchronized(buf) {
	    cs = buf.get(ofs);
	    if((((int)cs << 12) != 0) || (buf.get(ofs+1) != 0L)) {
	      ofs += 2;
	      continue;
	    }

	    // Have fresh case
	    buf.put(ofs, cs | timestamp(LocalDateTime.now()));
	  }
	  this.ptrOfs = ofs + 2;

	  return  new MappedEntry(cs>>>20, buf, ofs);
	}
      }

    }
    catch(final IOException  e) {
      e.printStackTrace();
      return  null;
    }

  } // fetchUnsolved

  private static int timestamp(final LocalDateTime  time) {
    return ((((((((((time.getYear()-2015)&3)) << 4) |
		 time.getMonthValue()) << 5) | time.getDayOfMonth()) << 5) |
	     time.getHour()) << 4) |(time.getMinute()/4);
  }

  private final class MappedEntry extends Entry {

    private final LongBuffer  buf;
    private final int         ofs;

    public MappedEntry(final long  spec,
		       final LongBuffer  buf, final int  ofs) {
      super(spec);
      this.buf = buf;
      this.ofs = ofs;
    }

    @Override
    public int hashCode() {
      return  ofs;
    }

    @Override
    public boolean equals(final Object  o) {
      if(o instanceof MappedEntry) {
	final MappedEntry  oe = (MappedEntry)o;
	if((this.ofs == oe.ofs) && (this.buf == oe.buf))  return  true;
      }
      return  false;
    }

    @Override
    public String toString() {
      final long  spec;
      final long  solv;
      {
	final LongBuffer  buf = this.buf;
	final int         ofs = this.ofs;
	synchronized(buf) {
	  spec = buf.get(ofs);
	  solv = buf.get(ofs+1);
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
	final LongBuffer  buf = this.buf;
	final int         ofs = this.ofs;
	synchronized(buf) {
	  if(((buf.get(ofs)^spec)>>20) == 0L) {
	    if(buf.get(ofs+1) == 0L) {
	      buf.put(ofs,  spec);
	      buf.put(ofs+1, res);
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
