#ifndef QUEENS_RANGE_RANGEPARSER_HPP_INCLUDED
#define QUEENS_RANGE_RANGEPARSER_HPP_INCLUDED
#line 1 "RangeParser.ypp"

#include "ParseException.hpp"
#include <memory>

namespace queens {
  namespace range {
    class SVal;
    class SRange;
  }
}

#line 15 "RangeParser.hpp"
#include <string>
namespace queens {
namespace range {
class RangeParser {
  typedef SVal* YYSVal;
  class YYStack;
#line 16 "RangeParser.ypp"

  
  char const *m_line;
  SRange     *m_range;

//- Life Cycle ---------------------------------------------------------------
private:
  RangeParser() {}
  ~RangeParser() {}

//- Parser Interface Methods -------------------------------------------------
private:
  void error(std::string  msg);
  unsigned nextToken(YYSVal &sval);

//- Private Helpers ----------------------------------------------------------
private:
  void buildSpec(uint64_t &spec, unsigned &wild, SVal const &position);

//- Usage Interface ----------------------------------------------------------
public:
  static SRange *parse(char const *line) throw (ParseException);

#line 46 "RangeParser.hpp"
private:
  void parse();
public:
enum {
  FIRST = 256,
  LAST = 257,
  TAKEN = 258,
  SOLVED = 259,
  POSITION = 260,
};
private:
enum { YYINTERN = 261 };
static unsigned short const  yyintern[];
static char const    *const  yyterms[];

private:
static unsigned short const  yylength[];
static unsigned short const  yylhs   [];
static char const    *const  yyrules [];

private:
static unsigned short const  yygoto  [][4];
static signed   short const  yyaction[][12];
};
}}
#endif
