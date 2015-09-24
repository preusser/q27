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

import  java.util.ArrayDeque;
import  java.util.Queue;
import  java.util.concurrent.atomic.AtomicInteger;

import  java.io.DataInputStream;
import  java.io.DataOutputStream;
import  java.io.IOException;

import  java.net.Socket;
import  javax.net.SocketFactory;

import static me.preusser.q27.Constants.*;

/**
 * Logs the solver->ID association of solvers attached locally.
 * Duplicates reported results into a local log in raw database format.
 */
public class RemoteDatabase implements Database {

  // Remote Address
  private final SocketFactory  factory;
  private final String  host;
  private final int     port;

  // Input and Output Buffers
  private final Queue<Long>         inQueue;
  private final Queue<RemoteEntry>  outQueue;

  private final int  inCap;
  private final int  minAvail;

  private final AtomicInteger  reported;

  // Dynamic Connection
  private Connection  cnct;


  public RemoteDatabase(final SocketFactory  factory,
			final String  host,
			final int     port,
			final int     inCap,
			final int     minAvail) throws IOException {
    if((minAvail <= 0) || (inCap < minAvail)) {
      throw  new IllegalArgumentException("Must have 0 < minAvail <= inCap");
    }
    this.factory = factory;
    this.host    = host;
    this.port    = port;

    this.inQueue  = new ArrayDeque<>();
    this.outQueue = new ArrayDeque<>();
    this.inCap    = inCap;
    this.minAvail = minAvail;
    this.reported = new AtomicInteger();

    reconnect();
  }

  @Override
  public String toString() {
    final int  isz, osz;
    {
      final Queue<?>  inQueue = this.inQueue;
      synchronized(inQueue) { isz = inQueue.size(); }
    }
    {
      final Queue<?>  outQueue = this.outQueue;
      synchronized(outQueue) { osz = outQueue.size(); }
    }
    return "RemoteDatabase > " + isz + " > ... > " + osz + " > " + reported;
  }

  @Override
  public Entry fetchUnsolved() throws InterruptedException {
    final long  cs; {
      final Queue<Long>  inQueue = this.inQueue;
      synchronized(inQueue) {
	inQueue.notifyAll();
	while(inQueue.isEmpty())  inQueue.wait();
	cs = inQueue.remove();
      }
    }
    return (cs == 0L)? null : new RemoteEntry(cs, outQueue);
  }

  private synchronized void reconnect() throws IOException {

    // Clean up old Socket if it exists
    if(cnct != null) {
      cnct.close();
      cnct = null;
    }

    // Start new SSL Connection
    cnct = new Connection(factory.createSocket(host, port));

  } // reconnect()

  private synchronized boolean active(final Connection  cnct) {
    return  this.cnct == cnct;
  }

  private synchronized void broken(final Connection  cnct, Exception  e) {
    if(this.cnct == cnct) {
      while(true) {
	try {
	  System.err.println("Connection Error:");
	  e.printStackTrace();
	  System.err.println("Reconnect in 30s ...");
	  try { Thread.sleep(30000L); } catch(InterruptedException  ex) {}
	  reconnect();
	  return;
	}
	catch(final Exception  ex) {
	  e = ex;
	}
      }
    }

  } // broken()

  private final class Connection {

    private final Socket            sock;
    private final DataOutputStream  out;

    private final Thread  reader;
    private final Thread  writer;


    public Connection(final Socket  sock) throws IOException {
      this.sock = sock;
      this.out  = new DataOutputStream(sock.getOutputStream());
      (reader = new Thread(this::recv, "RemoteDB: recv")).start();
      (writer = new Thread(this::send, "RemoteDB: send")).start();
    }

    public void close() {
      reader.interrupt();
      writer.interrupt();
      try { sock.close(); } catch(IOException  e) {}
    } // close()

    private void recv() {
      try {
	final DataInputStream  in      = new DataInputStream(sock.getInputStream());
	final Queue<Long>      inQueue = RemoteDatabase.this.inQueue;
	while(true) {
	  int  n;
	  synchronized(inQueue) {
	    while((n = inQueue.size()) >= minAvail) {
	      inQueue.wait();
	      if(!active(this))  return;
	    }
	  }
	  n = inCap - n;
	  fetchCases(n);
	  while(--n >= 0) {
	    final long  cs = in.readLong();
	    synchronized(inQueue) {
	      inQueue.add(cs);
	      inQueue.notifyAll();
	    }
	  }
	}
      }
      catch(final Exception  e) {
	broken(this, e);
      }

    } // recv()

    private void send() {
      try {
	final Queue<RemoteEntry>  outQueue = RemoteDatabase.this.outQueue;
	final DataOutputStream    out      = this.out;
	final AtomicInteger       reported = RemoteDatabase.this.reported;
	final IDMap<Object>       solvers  = new IDMap<Object>(1 << 12) {
	    @Override
	    protected void cleanup(final int  id) {
	      super.cleanup(id);
	      try { denounceSolver(id); } catch(IOException  e) { throw  new RuntimeException(e); }
	    }
	  };

	while(true) {
	  final RemoteEntry  res;

	  // Fetch Result from outQueue
	  synchronized(outQueue) {
	    while(outQueue.isEmpty()) {
	      outQueue.wait();
	      if(!active(this))  return;
	    }
	    res = outQueue.remove();
	  }

	  try {
	    // Resolve Solver ID
	    final int  id; {
	      final Object   solv = res.solv;
	      if(solvers.containsKey(solv))  id = solvers.get(solv);
	      else {
		id = solvers.map(solv);
		announceSolver(id, solv);
	      }
	    }

	    // Report Result
	    reportResult(id, res.getSpec(), res.res);
	    reported.incrementAndGet();
	  }
	  catch(final IOException  e) {
	    synchronized(outQueue) { outQueue.add(res); }
	    throw  e;
	  }
	}
      }
      catch(final Exception  e) {
	broken(this, e);
      }

    } // send()

    private void fetchCases(final int  n) throws IOException {
      final DataOutputStream  out = this.out;
      synchronized(out) {
	out.writeByte(FETCH_CASES);
	out.writeInt(n);
	out.flush();
      }
    }
    private void announceSolver(final int  id, final Object  solv) throws IOException {
      final DataOutputStream  out = this.out;
      synchronized(out) {
	out.writeByte(ANNOUNCE_SOLVER);
	out.writeInt(id);
	out.writeUTF(solv.toString());
      }
    }
    private void reportResult(final int  id, final long  cs, final long  res) throws IOException {
      final DataOutputStream  out = this.out;
      synchronized(out) {
	out.writeByte(REPORT_RESULT);
	out.writeInt (id);
	out.writeLong(cs);
	out.writeLong(res);
	out.flush();
      }
    }
    private void denounceSolver(final int  id) throws IOException {
      final DataOutputStream  out = this.out;
      synchronized(out) {
	out.writeByte(DENOUNCE_SOLVER);
	out.writeInt(id);
      }
    }
  } // class Connection

  private static final class RemoteEntry extends Entry {
    private final Queue<RemoteEntry>  sink;
    public Object  solv;
    public long    res;

    public RemoteEntry(final long                spec,
		       final Queue<RemoteEntry>  sink) {
      super(spec);
      this.sink = sink;
    }

    @Override
    public boolean solve(final Object  solver, final long  res) {
      this.solv = solver;
      this.res  = res;
      final Queue<RemoteEntry>  sink = this.sink;
      synchronized(sink) {
	sink.add(this);
	sink.notifyAll();
      }
      return  true;
    }

  } // class RemoteEntry

} // class RemoteDatabase
