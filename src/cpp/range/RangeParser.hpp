#ifndef QUEENS_RANGE_RANGEPARSER_HPP_INCLUDED
#define QUEENS_RANGE_RANGEPARSER_HPP_INCLUDED
#line 21 "RangeParser.ypp"

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
  typedef std::shared_ptr< SVal > YYSVal;
  class YYStack;
#line 36 "RangeParser.ypp"

  
  char const              *m_line;
  std::shared_ptr<SRange>  m_range;

//- Life Cycle ---------------------------------------------------------------
public:
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
  std::shared_ptr<SRange> parse(char const *line) throw (ParseException);

#line 46 "RangeParser.hpp"
private:
  void parse();
public:
enum {
  FIRST = 256,
  LAST = 257,
  TAKEN = 258,
  SOLVED = 259,
  WRAPPED = 260,
  VALID = 261,
  NUMBER = 262,
};
private:
enum { YYINTERN = 263 };
static unsigned short const  yyintern[];
static char const    *const  yyterms[];

private:
static unsigned short const  yylength[];
static unsigned short const  yylhs   [];
static char const    *const  yyrules [];

private:
static unsigned short const  yygoto  [][4];
static signed   short const  yyaction[][18];
};
}}
#endif
