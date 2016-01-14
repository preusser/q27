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

import  java.math.BigInteger;

import  java.util.concurrent.atomic.AtomicInteger;

public class DiniSolver extends Solver {

  // Package Start Marker
  private static final byte  SENTINEL = (byte)0xFA;
  private static final int   RESULT_PAY_LENGTH = 12; // 18 with COUNT_CYCLES

  // CRC-8 Codes, Polynom: 0x1D5
  private static final short[] FCS = {
    0x00, 0xD5, 0x7F, 0xAA, 0xFE, 0x2B, 0x81, 0x54,
    0x29, 0xFC, 0x56, 0x83, 0xD7, 0x02, 0xA8, 0x7D,
    0x52, 0x87, 0x2D, 0xF8, 0xAC, 0x79, 0xD3, 0x06,
    0x7B, 0xAE, 0x04, 0xD1, 0x85, 0x50, 0xFA, 0x2F,
    0xA4, 0x71, 0xDB, 0x0E, 0x5A, 0x8F, 0x25, 0xF0,
    0x8D, 0x58, 0xF2, 0x27, 0x73, 0xA6, 0x0C, 0xD9,
    0xF6, 0x23, 0x89, 0x5C, 0x08, 0xDD, 0x77, 0xA2,
    0xDF, 0x0A, 0xA0, 0x75, 0x21, 0xF4, 0x5E, 0x8B,
    0x9D, 0x48, 0xE2, 0x37, 0x63, 0xB6, 0x1C, 0xC9,
    0xB4, 0x61, 0xCB, 0x1E, 0x4A, 0x9F, 0x35, 0xE0,
    0xCF, 0x1A, 0xB0, 0x65, 0x31, 0xE4, 0x4E, 0x9B,
    0xE6, 0x33, 0x99, 0x4C, 0x18, 0xCD, 0x67, 0xB2,
    0x39, 0xEC, 0x46, 0x93, 0xC7, 0x12, 0xB8, 0x6D,
    0x10, 0xC5, 0x6F, 0xBA, 0xEE, 0x3B, 0x91, 0x44,
    0x6B, 0xBE, 0x14, 0xC1, 0x95, 0x40, 0xEA, 0x3F,
    0x42, 0x97, 0x3D, 0xE8, 0xBC, 0x69, 0xC3, 0x16,
    0xEF, 0x3A, 0x90, 0x45, 0x11, 0xC4, 0x6E, 0xBB,
    0xC6, 0x13, 0xB9, 0x6C, 0x38, 0xED, 0x47, 0x92,
    0xBD, 0x68, 0xC2, 0x17, 0x43, 0x96, 0x3C, 0xE9,
    0x94, 0x41, 0xEB, 0x3E, 0x6A, 0xBF, 0x15, 0xC0,
    0x4B, 0x9E, 0x34, 0xE1, 0xB5, 0x60, 0xCA, 0x1F,
    0x62, 0xB7, 0x1D, 0xC8, 0x9C, 0x49, 0xE3, 0x36,
    0x19, 0xCC, 0x66, 0xB3, 0xE7, 0x32, 0x98, 0x4D,
    0x30, 0xE5, 0x4F, 0x9A, 0xCE, 0x1B, 0xB1, 0x64,
    0x72, 0xA7, 0x0D, 0xD8, 0x8C, 0x59, 0xF3, 0x26,
    0x5B, 0x8E, 0x24, 0xF1, 0xA5, 0x70, 0xDA, 0x0F,
    0x20, 0xF5, 0x5F, 0x8A, 0xDE, 0x0B, 0xA1, 0x74,
    0x09, 0xDC, 0x76, 0xA3, 0xF7, 0x22, 0x88, 0x5D,
    0xD6, 0x03, 0xA9, 0x7C, 0x28, 0xFD, 0x57, 0x82,
    0xFF, 0x2A, 0x80, 0x55, 0x01, 0xD4, 0x7E, 0xAB,
    0x84, 0x51, 0xFB, 0x2E, 0x7A, 0xAF, 0x05, 0xD0,
    0xAD, 0x78, 0xD2, 0x07, 0x53, 0x86, 0x2C, 0xF9
  };

  private static final ThreadGroup    tgrp = new ThreadGroup("DINI Workers");
  private static final AtomicInteger  tcnt = new AtomicInteger();

  private final DiniBoard  board;
  private final String     desc;

  private Thread  reader;
  private Thread  writer;

  public DiniSolver(final int  board, final String  desc, final int  limit) {
    super(limit, 600);
    this.board = new DiniBoard(board);
    this.desc  = desc;
  }

  @Override
  public String toString() {
    return  desc + " on /dini/board" + board;
  }

  /*
  // Configures the FPGA, e.g., enables the proper interrupts
  private static native void _setupFPGA(final int  board);
  private static native void _writeFPGA(final int  board, final int  b);
  private static native int  _readFPGA (final int  board);
  private static int readFPGA(final int  board) throws InterruptedException {
    final int  res = _readFPGA(board);
    if(res < 0)  throw  new InterruptedException();
    return  res;
  }
  */

  private int read() throws InterruptedException {
    final DiniBoard  board = this.board;
    while(true) {
      final int  b = board.read(8L);
      if(b >= 0)  return  b & 0xFF;
      board.awaitInterrupt(0x0100000000L, 10);
      if(Thread.interrupted())  throw  new InterruptedException();
    }
  }

  @Override
  public synchronized void start(final Database  db) throws Exception {
    if(reader != null)  throw  new IllegalStateException("Already running.");

    { // Setup Q27 Design Communication
      final DiniBoard  board = this.board;
      board.write(0L, 0); // Clear and disable input interrupt
      board.write(4L, 3); // Enable output interrupt
    }

    // Prepare inherited start()
    super.start(db);
    final int  tid = tcnt.getAndIncrement();

    // Fork Reader
    (reader = new Thread(tgrp, "Reader-" + tid) {
      public void run() {
	try {
	  final byte[] data = new byte[RESULT_PAY_LENGTH];

	  while(true) {
	    // Scan for Sentinel
	    while(true) {
	      final int  b = read();
	      if((byte)b == SENTINEL)  break;
	      System.err.printf("Spurious byte: 0x%02X\n", b);
	    }

	    // Read Frame & Calculate expected CRC
	    int  crc = FCS[0xFF];
	    for(int i = 0; i < RESULT_PAY_LENGTH; i++) {
	      final int  b = read();
	      data[i] = (byte)b;
	      crc = FCS[crc^b];
	    }

	    // Read and Check CRC
	    if(crc == read()) {
	      final BigInteger  sol = new BigInteger(data);
	      logCount(sol.shiftRight(56).longValue()&    0xFFFFFFFFFFL,  // case
		       (sol.longValue()>>>4)         & 0xFFFFFFFFFFFFFL); // counts
	    }
	    else {
	      System.err.print("Flawy Packet: ");
	      for(int i = 0; i < RESULT_PAY_LENGTH; i++) {
		System.err.printf("0x%02X, ", data[i]);
	      }
	      System.err.printf("0x%02X [EXP-CRC]", crc);
	    }
	  }
	}
	catch(final InterruptedException e) {}
	catch(final Exception e) {
	  e.printStackTrace();
	}
      }
    }).start(); // Reader

    // Fork Writer
    (writer = new Thread(tgrp, "Writer-" + tid) {
      public void run() {
	final DiniBoard  board = DiniSolver.this.board;
	final byte[]     data  = new byte[7];

	try {
	  data[0] = SENTINEL;
	  while(true) {

	    // Fetch Case & Write to serial Interface
	    int   crc = FCS[0xFF];
	    long  cs  = fetchCase() << 24;
	    if(cs == 0L)  return;

	    board.write(8L, SENTINEL);
	    for(int i = 0; i < 5; i++) {
	      final int  b = (int)(cs >> 56);
	      board.write(8L, b);
	      crc  = FCS[crc ^ (0xFF & b)];
	      cs <<= 8;
	    }
	    board.write(8L, crc);
	  }
	}
	catch(Exception e) {
	  e.printStackTrace();
	}
      }
      }).start(); // Writer
  }

  @Override
  public synchronized void stop() {
    try {
      reader.interrupt();
      writer.interrupt();
    }
    finally {
      reader = null;
      writer = null;
      super.stop();
    }
  }

} // class DiniSolver
