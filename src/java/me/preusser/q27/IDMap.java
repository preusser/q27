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

import  java.util.BitSet;
import  java.util.WeakHashMap;
import  java.util.NoSuchElementException;


public class IDMap<K> {
  private final int  cap;

  private final BitSet                   taken;
  private final WeakHashMap<K, Mapping>  mappings;
  private final ReferenceQueue<K>        zombies;

  private int  ptr;

  public IDMap(final int  cap) {
    this.cap      = cap;
    this.taken    = new BitSet();
    this.mappings = new WeakHashMap<>();
    this.zombies  = new ReferenceQueue<>();
  }

  public boolean containsKey(final K  key) {
    return  mappings.containsKey(key);
  }

  public int get(final K  key) {
    final Mapping  m = mappings.get(key);
    if(m != null)  return  m.id;
    throw  new NoSuchElementException();
  }

  @SuppressWarnings("unchecked")
  public int map(final K  key) {
    final WeakHashMap<K, Mapping>  mappings = this.mappings;

    // Find existing Mapping
    final Mapping  m = mappings.get(key);
    if(m != null)  return  m.id;

    { // Clean up Zombies
      final ReferenceQueue<K>  zombies = this.zombies;
      while(true) {
	final  Reference<? extends K>  zombie = zombies.poll();
	if(zombie == null)  break;
	cleanup(((Mapping)zombie).id);
      }
    }

    // Create new Mapping
    final BitSet  taken = this.taken;
    int  id = taken.nextClearBit(this.ptr);
    if(id >= cap)  id = taken.nextClearBit(0);
    if(id < cap) {
      mappings.put(key, new Mapping(key, id, (ReferenceQueue<Object>)zombies));
      taken.set(id);
      this.ptr = id+1;
      return  id;
    }
    throw  new IndexOutOfBoundsException("ID Pool exhausted");

  } // map()

  protected void cleanup(final int  id) {
    taken.clear(id);
  }

  private static final class Mapping extends WeakReference<Object> {
    public final int  id;

    public Mapping(final Object  key, final int  id,
		   final ReferenceQueue<Object>  zombies) {
      super(key, zombies);
      this.id = id;
    }
  } // class Mapping

} // class IDMap
