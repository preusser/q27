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

import  java.lang.ref.Reference;
import  java.lang.ref.ReferenceQueue;
import  java.lang.ref.WeakReference;

import  java.util.Arrays;
import  java.util.HashMap;

import  java.io.Console;
import  java.io.DataInputStream;
import  java.io.DataOutputStream;
import  java.io.File;
import  java.io.FileInputStream;
import  java.io.FileOutputStream;
import  java.io.InputStream;
import  java.io.PrintWriter;
import  java.io.RandomAccessFile;
import  java.io.IOException;

import  java.nio.channels.FileChannel;

import  java.net.InetAddress;
import  java.net.ServerSocket;
import  java.net.Socket;

import  javax.net.ssl.SSLContext;
import  javax.net.ssl.SSLSocket;
import  javax.net.ssl.SSLServerSocket;
import  javax.net.ssl.TrustManagerFactory;
import  javax.net.ssl.KeyManagerFactory;

import  java.security.KeyStore;
import  java.security.SecureRandom;
import  java.security.cert.X509Certificate;

import static me.preusser.q27.Constants.*;

public final class Server {

  // The served Database.
  private final MappedDatabase    dbTarget;
  private final TrackingDatabase  dbTrack;

  // Server Configuration
  private final ServerSocket  statusSock;
  private final ServerSocket  clientSock;


  public Server(final MappedDatabase  db,
		final int             timeoutMin,
		final ServerSocket    statusSock,
		final ServerSocket    clientSock) {
    this.dbTarget   = db;
    this.dbTrack    = new TrackingDatabase(db, timeoutMin);
    this.statusSock = statusSock;
    this.clientSock = clientSock;
  }

  public void start() {
    new Thread(this::serveStatus ).start();
    new Thread(this::serveClients).start();
  }

  private void serveStatus() {
    try {
      final ServerSocket  sock = this.statusSock;
      while(true) {
	final Socket  s = sock.accept();
	try {
	  final PrintWriter  out = new PrintWriter(s.getOutputStream());
	  out.println("Q27 Database Status");
	  out.close();
	}
	catch(final Exception  e) {
	  System.err.println("Error serving Status Request from " + s.getInetAddress() + ':');
	  e.printStackTrace();
	}
      }
    }
    catch(Exception  e) {
      System.err.println("Status Server failing:");
      e.printStackTrace();
    }

  } // serveStatus()

  private void serveClients() {
    try {
      final ServerSocket  sock = this.clientSock;
      while(true) {
	new Handler(dbTrack, (SSLSocket)sock.accept()).start();
      }
    }
    catch(Exception  e) {
      System.err.println("Client Server failing:");
      e.printStackTrace();
    }

  } // serveClients()

  private static class Handler extends Thread {

    private final TrackingDatabase  db;
    private final SSLSocket         sock;

    // db MUST be a TrackingDatabase as this Handler relies on hard references
    // to the Database.Entries to be maintained externally
    public Handler(final TrackingDatabase  db, final SSLSocket  sock) {
      this.db   = db;
      this.sock = sock;
    }

    public void run() {
      final SSLSocket  sock = this.sock;

      String  client = sock.getRemoteSocketAddress().toString();
      try {
	{
	  final X509Certificate  cert = (X509Certificate)sock.getSession().getPeerCertificates()[0];
	  String  name = cert.getSubjectX500Principal().getName();
	  int  beg = name.indexOf("CN=");
	  if(beg >= 0) {
	    beg += 3;
	    final int  end = name.indexOf(',', beg);
	    if(end > 0)  name = name.substring(beg, end);
	  }

	  client = name + " [" + cert.getSerialNumber() + "] " + client;
	}
	System.err.printf("Serving %s.\n", client);

	final ReferenceQueue<Database.Entry>     staled  = new ReferenceQueue<>();
	final HashMap<Long, WeakEntryReference>  pending = new HashMap<>();
	final HashMap<Integer, Object>           solvers = new HashMap<>();

	final DataInputStream   in  = new DataInputStream (sock.getInputStream());
	final DataOutputStream  out = new DataOutputStream(sock.getOutputStream());
	while(true) {
	  switch(in.read()) {
	  case FETCH_CASES: {
	    while(true) {
	      final Reference<? extends Database.Entry>  stale = staled.poll();
	      if(stale == null)  break;
	      pending.remove(((WeakEntryReference)stale).key);
	    }

	    int  n = in.readInt();
	    while(--n >= 0) {
	      final Database.Entry  entry = db.fetchUnsolved();
	      final long            spec;
	      if(entry == null)  spec = 0L;
	      else {
		final WeakEntryReference  ref = new WeakEntryReference(entry, staled);
		pending.put(ref.key, ref);
		spec = entry.getSpec();
	      }
	      out.writeLong(spec);
	    }
	    out.flush();
	    continue;
	  }
	  case ANNOUNCE_SOLVER: {
	    solvers.put(in.readInt(), new Unique(client + ' ' + in.readUTF()));
	    continue;
	  }
	  case REPORT_RESULT: {
	    final Object  solver = solvers.get(in.readInt());
	    final long    spec   = in.readLong();
	    final long    res    = in.readLong();

	    final WeakEntryReference  ref = pending.remove(spec);
	    if(ref != null) {
	      Database.Entry  entry = ref.get();
	      if(entry != null) {
		entry.solve(solver, res);
		continue;
	      }
	    }
	    System.err.printf("Spurious result: 0x%011X: 0x%013X by %s\n", spec, res, solver);
	    continue;
	  }
	  case DENOUNCE_SOLVER: {
	    solvers.remove(in.readInt());
	    continue;
	  }
	  default:
	    System.err.println("Malformed command stream.");
	  case -1:
	    return;
	  }
	}
      }
      catch(final Exception  e) {
	System.err.println("Client failing:");
	e.printStackTrace();
      }
      finally {
	try { sock.close(); } catch(IOException  e) {}
	System.err.printf("Disconnected %s.\n", client);
      }

    } // run()

  } // class Handler

  // Avoids Solver aliasing via representing String in MappedDatabase
  private static final class Unique {
    private final String  name;
    public Unique(final String  name) { this.name = name; }
    public String toString() { return  this.name; }
  } // class Unique

  private static final class WeakEntryReference extends WeakReference<Database.Entry> {
    public final Long  key;
    public WeakEntryReference(final Database.Entry  entry, final ReferenceQueue<Database.Entry>  queue) {
      super(entry, queue);
      this.key = entry.getSpec();
    }
  } // class WeakEntryReference

  public static void main(String[] args) throws Exception {
    int  statusPort = 27000;
    int  clientPort = 27027;
    int  timeoutMin =   360;

    try {
      int  idx = 0;
      while(idx < args.length) {
	final String  arg = args[idx++];

	// Check for Option
	if((arg.length() == 2) && (arg.charAt(0) == '-')) {
	  final int  val = Integer.parseInt(args[idx++]);
	  switch(arg.charAt(1)) {
	  case 's': // Status Port
	    statusPort = val;
	    continue;
	  case 'c': // Client Port
	    clientPort = val;
	    continue;
	  case 't': // Timeout
	    timeoutMin = val;
	    continue;
	  }
	  // Unknown
	  break;
	}

	// Non-Option File Arguments
	if(args.length-idx != 4)  break;
	final FileChannel  db;

	{ // Open Database
	  final File  dbFile = new File(arg);
	  if(!dbFile.exists()) {
	    System.err.print(dbFile + ": DB does not exist.");
	    System.exit(1);
	  }
	  db = new RandomAccessFile(dbFile, "rw").getChannel();
	}

	// Duplicate Database Stream
	final DataOutputStream  dupStream = new DataOutputStream(new FileOutputStream(new File(args[idx++]), true));

	// Solver Log
	final PrintWriter  solverLog = new PrintWriter(new FileOutputStream(new File(args[idx++]), true), true);

	// ServerSockets: plain for status, TLS for Client Communication
	final ServerSocket  statusSock;
	final ServerSocket  clientSock; {
	  final TrustManagerFactory  tmf = TrustManagerFactory.getInstance("SunX509");
	  final KeyManagerFactory    kmf = KeyManagerFactory.getInstance("SunX509");
	  {
	    final String  trust = args[idx++];
	    final String  priv  = args[idx];

	    final InputStream  trustFile  = new FileInputStream(trust);
	    final InputStream  privFile   = new FileInputStream(priv);
	    final Console      console    = System.console();

	    { // Load Trust Store
	      final KeyStore  trustStore = KeyStore.getInstance("JKS");
	      trustStore.load(trustFile, console.readPassword("Unlock Trust Store '%s': ", trust));
	      tmf.init(trustStore);
	    }
	    trustFile.close();

	    { // Key Store
	      final KeyStore  privStore = KeyStore.getInstance("pkcs12");
	      final char[]    password  = console.readPassword("Unlock Key Store '%s': ", priv);
	      privStore.load(privFile,  password);
	      kmf.init(privStore, password);
	      Arrays.fill(password, '\0');
	    }
	    privFile.close();
	  }

	  // Create and setup ServerSockets
	  statusSock = new ServerSocket(statusPort, 0, InetAddress.getByName("localhost"));

	  final SSLContext  ctx = SSLContext.getInstance("TLS");
	  ctx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), new SecureRandom());
	  clientSock = ctx.getServerSocketFactory().createServerSocket(clientPort);
	  ((SSLServerSocket)clientSock).setNeedClientAuth(true);
	}
	new Server(new MappedDatabase(db, dupStream, solverLog),
		   timeoutMin, statusSock, clientSock).start();

	return; // shutdown this Thread
      }
    }
    catch(NumberFormatException  e) {}
    catch(IndexOutOfBoundsException  e) {}

    System.err.println(
      "java q27.Server\n\t[-s <statusPort(default:27000)>]\n\t[-c <clientPort(default:27027)>]\n\t[-t <timeout_min(default:360)>]\n" +
      "\t<database.db> <duplicates.db> <solvers.log> <trust.jks> <privkey.p12>"
    );
  }

} // class Server
