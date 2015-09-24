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

import  java.util.LinkedHashMap;
import  java.util.Iterator;
import  java.util.concurrent.atomic.AtomicInteger;

/**
 * A RemoteSolver is a Solver that (a) recodes subproblems from the database
 * representation into plain pre-placements and (b) maintains a log of pending
 * subproblems. The number of outstanding problems may be limited so as to
 * emulate some flow control. A timeout allows to drop old problems from this
 * limit.
 */
public abstract class Solver {

  private final int  limit;   // Limit of Pending Computations
  private final int  timeout; // Timeout of Pending Computations

  // Reduced Case -> (Case, Timeout)
  private final LinkedHashMap<Long, Pending>  pending;
  private final AtomicInteger                 solved;

  private Database  db;

  protected Solver(final int  limit, final int  timeout_min) {
    this.limit   = limit;
    this.timeout = 60000*timeout_min;
    this.pending = new LinkedHashMap<>();
    this.solved  = new AtomicInteger();
  }

  public synchronized void start(final Database  db) throws Exception {
    this.db = db;
  }

  public synchronized void stop() {
    this.db = null;
    notifyAll();
  }

  protected synchronized long fetchCase() throws InterruptedException {
    if(db != null) {
      // Wait for Space
      final LinkedHashMap<Long, Pending>  pending = this.pending;
      while(pending.size() >= limit) {
	// Drop oldest Entry if Timeout has elapsed
	final Iterator<Pending>  it  = pending.values().iterator();
	final long               ttl = it.next().timeout - System.currentTimeMillis();
	if(ttl <= 0) {
	  it.remove();
	  break;
	}
	wait(ttl);
	if(db == null)  return  0L;
      }

      // Fetch & Log Case
      final Database.Entry  e = db.fetchUnsolved();
      if(e != null) {
	final Pending  p = new Pending(e, System.currentTimeMillis()+timeout);
	// Reduce Case to plain Pre-Placement with odd Parity
	long  cs = e.getSpec() >> 5;
	if((Long.bitCount(cs)&1) == 0)  cs |= 0x8000000000L;
	pending.put(cs, p);
	return  cs;
      }
    }
    return  0L;

  } // fetchCase()

  protected synchronized boolean logCount(final long  cs, final long  res) {
    final LinkedHashMap<Long, Pending>  pending = this.pending;
    final Pending  p = pending.remove(cs);
    if(p != null) {
      notifyAll();
      if(p.entry.solve(this, res)) {
	solved.incrementAndGet();
	return  true;
      }
    }
    System.err.printf("Unlogged plain Result: 0x%010X: 0x%013X\n", cs, res);
    return  false;

  } // logCount()

  public final synchronized int activeCount() {
    final LinkedHashMap<Long, Pending>  pending = this.pending;
    return (pending == null)? 0 : pending.size();
  }

  public final int solvedCount() {
    return  solved.get();
  }

  private static class Pending {
    public final Database.Entry  entry;
    public final long            timeout;

    public Pending(final Database.Entry  entry, final long  timeout) {
      this.entry   = entry;
      this.timeout = timeout;
    }

  } // class Pending

} // class Solver
