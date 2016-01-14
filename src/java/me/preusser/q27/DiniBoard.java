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

public class DiniBoard {

  private final int  board;

  public DiniBoard(final int  board) {
    this.board = board;
  }

  @Override
  public String toString() {
    return  String.valueOf(this.board);
  }

  public void write(final long  addr, final int  b) {
    write0(this.board, addr, b);
  }

  public int read(final long  addr) throws InterruptedException {
    return  read0(this.board, addr);
  }

  public void awaitInterrupt(final long  mask, final int  timeout) {
    awaitInterrupt0(this.board, mask, timeout);
  }

  private static native void write0(final int  board, final long  addr, final int  val);
  private static native int  read0 (final int  board, final long  addr);
  private static native void awaitInterrupt0(final int  board, final long  mask, final int  timeout);

  static {
    System.loadLibrary("dini");
  }

} // class DiniBoard
