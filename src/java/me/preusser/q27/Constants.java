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

final class Constants {
  private Constants() {}

  //+ RemoteDatabase - Client Communication Commands
  public static final byte  FETCH_CASES     = 0x01;
  public static final byte  ANNOUNCE_SOLVER = 0x02;
  public static final byte  REPORT_RESULT   = 0x03;
  public static final byte  DENOUNCE_SOLVER = 0x04;

}
