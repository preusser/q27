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

import  java.util.LinkedHashSet;
import  java.util.Iterator;


public class TrackingDatabase implements Database {

  private final Database                      parent;
  private final LinkedHashSet<TrackingEntry>  pending;
  private final int                           timeout;

  public TrackingDatabase(final Database  parent, final int  timeout_min) {
    this.parent  = parent;
    this.pending = new LinkedHashSet<TrackingEntry>();
    this.timeout = timeout_min * 60000;
  }

  public Entry fetchUnsolved() throws InterruptedException {

    final LinkedHashSet<TrackingEntry>  pending = this.pending;
    final long  now = System.currentTimeMillis();

    Entry  target = null;
    synchronized(pending) {
      if(!pending.isEmpty()) {
	final Iterator<TrackingEntry>  it = pending.iterator();
	final TrackingEntry  old = it.next();
	if(old.timeout < now) {
	  it.remove();
	  target = old.target;
	}
      }
    }
    if(target == null)  target = parent.fetchUnsolved();
    if(target == null)  return  null;

    final TrackingEntry  res = new TrackingEntry(target, now + timeout, pending);
    synchronized(pending) { pending.add(res); }
    return  res;
  }

  private static final class TrackingEntry extends Entry {

    public  final Entry                         target;
    public  final long                          timeout;
    private final LinkedHashSet<TrackingEntry>  pending;

    public TrackingEntry(final Entry  target, final long  timeout,
			 final LinkedHashSet<TrackingEntry>  pending) {
      super(target.getSpec());
      this.target  = target;
      this.timeout = timeout;
      this.pending = pending;
    }

    public boolean solve(final Object  solver, final long  res) {
      final LinkedHashSet<TrackingEntry>  pending = this.pending;
      synchronized(pending) { pending.remove(this); }
      return  target.solve(solver, res);
    }

  } // class TrackingEntry

} // interface TrackingDatabase
