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

import  java.net.InetAddress;
import  java.net.ServerSocket;
import  java.net.Socket;
import  java.net.SocketTimeoutException;

import  javax.net.ssl.SSLContext;
import  javax.net.ssl.SSLSocket;
import  javax.net.ssl.KeyManagerFactory;
import  javax.net.ssl.TrustManagerFactory;

import  java.security.KeyStore;
import  java.security.SecureRandom;

import  java.io.BufferedReader;
import  java.io.Console;
import  java.io.File;
import  java.io.FileInputStream;
import  java.io.InputStream;
import  java.io.InputStreamReader;
import  java.io.OutputStreamWriter;
import  java.io.IOException;

import  java.util.Arrays;
import  java.util.Formatter;
import  java.util.Map;
import  java.util.HashMap;

import  java.util.regex.Matcher;
import  java.util.regex.Pattern;

public final class Client extends Thread {
  // Server Configuration
  private final InetAddress  iface;
  private final int          port;

  // Database
  private final Database  db;

  // Solvers
  private final HashMap<String, Solver>  solvers;


  public Client(InetAddress iface, int port, Database db) throws Exception {
    super("Client Control");

    // Server Configuration
    this.iface = iface;
    this.port  = port;

    // Database
    this.db      = db;
    this.solvers = new HashMap<>();
  }

  public void run() {
    if(Thread.currentThread() != this)  throw  new IllegalArgumentException();

    try {
      System.err.println("Opening Socket on " + iface + ":" + port);
      final ServerSocket  sock = new ServerSocket(port, 0, iface);
      while(true)  new Handler(sock.accept()).start();
    }
    catch(Exception e) {
      System.err.println("Server Error:");
      e.printStackTrace();
    }
    finally {
      System.err.println("Server shutting down.");
    }
  }

  public static void main(String[] args) throws Exception {

    try {
      int  port = 27001;

      if(args.length >= 3) {
	int  idx = 0;
	if("-p".equals(args[0])) {
	  port = Integer.parseInt(args[1]);
	  idx  = 2;
	}
	if(args.length - idx == 3) {
	  // DB Server
	  final String  dbHost;
	  final int     dbPort; {
	    final String  spec  = args[idx];
	    final int     colon = spec.indexOf(':');
	    if(colon < 0) {
	      dbHost = spec;
	      dbPort = 27027;
	    }
	    else {
	      dbHost = spec.substring(0, colon);
	      dbPort = Integer.parseInt(spec.substring(colon+1));
	    }
	  }

	  // TLS
	  final SSLContext  ctx; {
	    final TrustManagerFactory  tmf = TrustManagerFactory.getInstance("SunX509");
	    final KeyManagerFactory    kmf = KeyManagerFactory.getInstance("SunX509");
	    {
	      final InputStream  trustFile  = new FileInputStream(args[idx+1]);
	      final InputStream  privFile   = new FileInputStream(args[idx+2]);
	      final Console      console    = System.console();

	      { // Load Trust Strore
		final KeyStore  trustStore = KeyStore.getInstance("JKS");
		trustStore.load(trustFile, console.readPassword("Unlock Trust Store '%s': ", args[idx+1]));
		tmf.init(trustStore);
	      }
	      trustFile.close();

	      { // Key Store
		final KeyStore  privStore = KeyStore.getInstance("pkcs12");
		final char[]    password  = console.readPassword("Unlock Key Store '%s': ", args[idx+2]);
		privStore.load(privFile,  password);
		kmf.init(privStore, password);
		Arrays.fill(password, '\0');
	      }
	      privFile.close();
	    }
	    ctx = SSLContext.getInstance("TLS");
	    ctx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), new SecureRandom());
	  }
	  new Client(
	    InetAddress.getByName("127.0.0.1"), port,
	    new RemoteDatabase(
	      SetupSocketFactory.getInstance(ctx.getSocketFactory(),
					     (Socket s) -> { ((SSLSocket)s).startHandshake(); return  s; }),
	      dbHost, dbPort, 200, 100
	    )
	  ).start();

	  return;
	}
      }
    }
    catch(NumberFormatException e) {}

    System.err.println("java Client [-p <ctlPort(default:27001)>] <dbHost[:dbPort(default:27027)]> <trust.jks> <key.p12>");
  }

  //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //+ Client Handler
  private final class Handler extends Thread {
    private final Socket  sock;

    private Formatter  out;

    public Handler(final Socket  sock) {
      super(sock.getRemoteSocketAddress().toString());
      this.sock = sock;
    }

    public void run() {
      try {
	final BufferedReader  in = new BufferedReader(new InputStreamReader(sock.getInputStream()));

	out = new Formatter(sock.getOutputStream());
	while(true) {
	  // Fetch a Command Line
	  final String  line = in.readLine();
	  if(line == null)  break;

	  final String[]  split = line.trim().split("\\s+", 2);
	  final String    cmd   = split[0].toUpperCase();

	  // Control
	  if     (cmd.equals("INFO"))  info();
	  else if(cmd.equals("STRT")) { if(split.length < 2) missing(); else start(split[1]); }
	  else if(cmd.equals("STOP")) { if(split.length < 2) missing(); else stop (split[1]); }
	  // Undocumented
	  else if(cmd.equals("GC"   ))  System.gc();
	  else if(cmd.equals("TDUMP"))  tdump();

	  // Help & Exit
	  else if(cmd.equals("HELP"))  help();
	  else if(cmd.equals("QUIT") ||
		  cmd.equals("EXIT"))  break;
	  else unknown(cmd);
	  out.flush();
	}
      }
      catch(Exception e) {
	System.err.println("Handler dying on:");
	e.printStackTrace();
      }
      finally {
	try { sock.close(); } catch(IOException e) {}
      }
    }

    private void unknown(final String cmd) {
      out.format("    Unknown command: %s\n", cmd);
    }

    private void missing() {
      out.format("    Missing argument.\n");
    }

    private void help() {
      out.format("    HELP  print this help\n"+
		 "    INFO  obtain solver info\n"+
		 "    STOP /dev/ttyXX\n\tstop solver on given device\n"+
		 "    STRT /dev/ttyXX \"<Description>\" <pipeline depth>\n\tstart solver on given device\n"+
                 "    EXIT\n"+
		 "    QUIT  close this session\n");
    }

    private void info() {
      final Map<String, Solver>  solvers = Client.this.solvers;
      out.format("    %s\n", Client.this.db);
      synchronized(solvers) {
	for(final Solver  s : solvers.values()) {
	  out.format("    [%4d >%7d] %s\n", s.activeCount(), s.solvedCount(), s);
	}
      }
    }

    private void tdump() {
      final Thread[]  active = new Thread[Thread.activeCount() << 1];

      for(int  i = Thread.enumerate(active); i-- > 0;) {
	final Thread  t = active[i];
	out.format("    %-25s %s\n", t.getClass().getName(), t.getName());
      }
    }

    private void start(final String  args) {
      //                                   1                        2           3         4
      final Matcher  m = Pattern.compile("^(/dev/tty\\S+|/dini/board(\\d))\\s+\"(.*)\"\\s+(\\d+)\\s*$").matcher(args);
      if(m.matches()) {
	final Map<String, Solver>  solvers = Client.this.solvers;
	final String  dev = m.group(1);

	try { // Create and Register Solver Instance

	  final String  dini  = m.group(2);
	  final String  desc  = m.group(3);
	  final int     limit = Integer.parseInt(m.group(4));
	  final Solver  solver;

	  synchronized(solvers) {
	    if(solvers.containsKey(dev)) {
	      out.format("    Device %s already in use.\n", dev);
	      return;
	    }

	    solver = (dini == null)?
	      new UartSolver(new File(dev), desc, limit) :
	      new DiniSolver(dini.charAt(0) - '0', desc, limit);
	    solvers.put(dev, solver);
	  }

	  // Initialize UART and Start Solver
	  boolean  fail = false;
	  if(dini == null) {
	    final Process  pInit
	      = Runtime.getRuntime().exec(new String[] {
		  "bash", "-c",
		  "stty -F "+dev+" 115200 raw -cstopb -parenb -crtscts -echo -ixon -ixoff >/dev/null 2>&1"
		});
	    if(pInit.waitFor() != 0)  fail = true;
	  }
	  if(!fail) {
	    out.format("    Starting %s.\n", solver);
	    solver.start(Client.this.db);
	    return;
	  }
	}
	catch(Exception e) {}
	out.format("    Could not initialize %s.\n", dev);
	synchronized(solvers) { solvers.remove(dev); }
	return;
      }
      out.format("    Illegal Arguments: '%s'\n", args);
    }

    private void stop(String args) {
      final Matcher  m = Pattern.compile("^(/dev/tty\\S+|/dini/board\\d)\\s*$").matcher(args);
      if(m.matches()) {
	final String  dev = m.group(1);

	final Map<String, Solver>  solvers = Client.this.solvers;
	synchronized(solvers) {
	  final Solver  solver = solvers.remove(dev);
	  if(solver == null)  out.format("    No Solver on %s.\n", dev);
	  else {
	    solver.stop();
	    out.format("    Stopped %s.\n", solver);
	  }
	}
	return;
      }
      out.format("    Illegal Arguments: '%s'\n", args);
    }

  } // Handler

} // Client
