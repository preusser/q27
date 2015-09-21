/*****************************************************************************
 * This file is part of the Queens@TUD solver suite
 * for enumerating and counting the solutions of an N-Queens Puzzle.
 *
 * Copyright (C) 2008-2015
 *      Thomas B. Preusser <thomas.preusser@utexas.edu>
 *****************************************************************************
 * This design is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Modifications to this work must be clearly identified and must leave
 * the original copyright statement and contact information intact. This
 * license notice may not be removed.
 *
 * This design is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this design.  If not, see <http://www.gnu.org/licenses/>.
 ****************************************************************************/
package me.preusser.q27;


public interface Database {
  public Entry fetchUnsolved() throws InterruptedException;

  public static abstract class Entry {
    private final long    spec;

    protected Entry(final long  spec) {
      this.spec = spec;
    }

    public final long getSpec() { return  spec; }

    public abstract boolean solve(final Object  solver, final long  res);

  } // class Database.Entry

} // interface Database
