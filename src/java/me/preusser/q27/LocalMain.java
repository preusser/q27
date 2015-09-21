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

import  java.io.File;
import  java.io.PrintWriter;
import  java.io.RandomAccessFile;

import  java.nio.ByteBuffer;
import  java.nio.channels.FileChannel;


class LocalMain {

  public static void main(String[] args) throws Exception {
    try {
      if(args.length == 4) {

	// Open Database
	final ByteBuffer  db; {
	  final File  dbFile = new File(args[0]);
	  if(!dbFile.exists()) {
	    System.err.print(dbFile + ": DB does not exist.");
	    System.exit(1);
	  }
	  final RandomAccessFile  dbRAF = new RandomAccessFile(dbFile, "rw");
	  db = dbRAF.getChannel().map(FileChannel.MapMode.READ_WRITE, 0, dbRAF.length());
	}

	// Open UART
	final File  uart = new File(args[1]);
	if(!uart.exists()) {
	  System.err.println(uart + ": UART Device  does not exist.");
	  System.exit(1);
	}

	// Determine Send Limit
	final int  lim = Integer.decode(args[3]);
	if(lim <= 0) {
	  System.err.println("Must specify positive limit.");
	  System.exit(1);
	}

	final String  desc = args[2];
	new UartSolver(uart, desc, lim) {
	  protected long fetchCase() throws InterruptedException {
	    final long  cs = super.fetchCase();
	    System.out.printf("%s < 0x%010X\n", desc, cs);
	    return  cs;
	  }
	  protected boolean logCount(final long  cs, final long  res) {
	    final boolean  logged = super.logCount(cs, res);
	    System.out.printf("%s > 0x%010X: %d [%d/%d] %c\n", desc, cs,
			      res & 0xFFFFFFFFFFFL, (res >> 44)&0xF, (res >> 48),
			      logged? '.' : '!');
	    return  logged;
	  }
	}.start(new MappedDatabase(db, null, new PrintWriter(System.out)));
	return;
      }
    }
    catch(final NumberFormatException  e) {}

    System.err.println("java LocalMain <DB File> <UART Device File> <Solver Name> <Limit>\n");
    System.exit(1);
  }

}
