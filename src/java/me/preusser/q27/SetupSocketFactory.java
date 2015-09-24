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

import  java.io.IOException;

import  java.net.InetAddress;
import  java.net.Socket;
import  javax.net.SocketFactory;

public abstract class SetupSocketFactory extends SocketFactory {

  private final SocketFactory  factory;

  //+ Construction +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  protected SetupSocketFactory(final SocketFactory  factory) {
    this.factory = factory;
  }

  @FunctionalInterface
  public interface SocketConfigurator {
    public Socket setup(Socket  sock) throws IOException;
  }

  public static SetupSocketFactory getInstance(final SocketFactory       factory,
					       final SocketConfigurator  setup) {
    return  new SetupSocketFactory(factory) {
      @Override
      protected Socket setup(final Socket  sock) throws IOException {
	return  setup.setup(sock);
      }
    };
  }

  //+ Setup ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  protected abstract Socket setup(Socket  sock) throws IOException;

  //+ Filtered Socket Creation +++++++++++++++++++++++++++++++++++++++++++++++
  @Override
  public Socket createSocket() throws IOException {
    return  setup(factory.createSocket());
  }
  @Override
  public Socket	createSocket(InetAddress host, int port) throws IOException {
    return  setup(factory.createSocket(host, port));
  }
  @Override
  public Socket createSocket(InetAddress address, int port, InetAddress localAddress, int localPort) throws IOException {
    return  setup(factory.createSocket(address, port, localAddress, localPort));
  }
  @Override
  public Socket createSocket(String host, int port) throws IOException {
    return  setup(factory.createSocket(host, port));
  }
  @Override
  public Socket createSocket(String host, int port, InetAddress localHost, int localPort) throws IOException {
    return  setup(factory.createSocket(host, port, localHost, localPort));
  }

} // SetupSocketFactory
