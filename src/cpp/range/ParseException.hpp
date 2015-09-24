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
#ifndef QUEENS_RANGE_PARSEEXCEPTION_HPP
#define QUEENS_RANGE_PARSEEXCEPTION_HPP

#include <string>

namespace queens {
namespace range {
/**
 * This class captures information about and the location of
 * a parsing problem.
 *
 * @author Thomas B. Preußer <thomas.preusser@utexas.edu>
 */
class ParseException {
    std::string const  m_msg;
    unsigned           m_pos;

public:
    ParseException(std::string  msg, unsigned  pos)
        : m_msg(msg), m_pos(pos) {}
    ~ParseException() {}

public:
    std::string const &message() const {
        return  m_msg;
    }
    unsigned position() const {
        return  m_pos;
    }
    void position(unsigned  pos) {
        m_pos = pos;
    }
};
}
}
#endif
