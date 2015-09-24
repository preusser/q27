#line 61 "RangeParser.ypp"

#include "RangeParser.hpp"
#include "IR.hpp"

#include <cassert>

#include <string.h>

  using namespace queens::range;

//- Parser Interface Methods -------------------------------------------------
inline void RangeParser::error(std::string  msg) {
  throw  ParseException(msg, 0);
}

unsigned RangeParser::nextToken(YYSVal &sval) {
  assert(m_line != 0);

 again:
  char const  c = *m_line;
  switch(c) {
  case 'f':
    if(strncmp(m_line, "first", 5) == 0) {
      m_line += 5;
      return  FIRST;
    }
    break;

  case 'l':
    if(strncmp(m_line, "last", 4) == 0) {
      m_line += 4;
      return  LAST;
    }
    break;

  case 's':
    if(strncmp(m_line, "solved", 6) == 0) {
      m_line += 6;
      return  SOLVED;
    }
    break;

  case 't':
    if(strncmp(m_line, "taken", 5) == 0) {
      m_line += 5;
      return  TAKEN;
    }
    break;

  default:
    if(isspace(c)) {
      m_line++;
      goto again;
    }
    if(isdigit(c)) {
      char *end;
      int  const  val = (int)strtol(m_line, &end, 0);
      m_line = end;
      sval = std::make_shared<SPosition>(val < 0? 0 : val > 26? 26 : val);
      return  POSITION;
    }
    m_line++;

  case '\0':
    return  c;
  }    

  error("Illegal Token");
  assert(false);
  return  0;
}

//- Public Usage Interface ---------------------------------------------------
std::shared_ptr<SRange> RangeParser::parse(char const *line) throw (ParseException) {
  RangeParser  p;
  try {
    p.m_line = line;
    p.parse();
    return  p.m_range;
  }
  catch(ParseException &e) {
    e.position(p.m_line - line);
    throw;
  }
}


void RangeParser::buildSpec(uint64_t &spec, unsigned &wild, SVal const &position) {
  int const  pos = static_cast<SPosition const&>(position);
  spec <<= 5;
  if(pos < 0)  wild++;
  else {
    if(wild > 0)  error("Fixed placement not allowed after wildcard.");
    spec |= pos;
  }
}
 

#line 100 "RangeParser.cpp"
#include <vector>
class queens::range::RangeParser::YYStack {
  class Ele {
  public:
    unsigned short  state;
    YYSVal          sval;

  public:
    Ele(unsigned short _state, YYSVal const& _sval)
     : state(_state), sval(_sval) {}
    Ele(unsigned short _state)
     : state(_state) {}
  };
  typedef std::vector<Ele>  Stack;
  Stack  stack;

public:
  YYStack() {}
  ~YYStack() {}

public:
  void push(unsigned short state) {
    stack.push_back(Ele(state));
  }
  void push(unsigned short state, YYSVal const& sval) {
    stack.push_back(Ele(state, sval));
  }
  void pop(unsigned cnt) {
    Stack::iterator  it = stack.end();
    stack.erase(it-cnt, it);
  }

  YYSVal& operator[](unsigned idx) { return  (stack.rbegin()+idx)->sval; }
  unsigned short operator*() const { return  stack.back().state; }
};

char const *const  queens::range::RangeParser::yyterms[] = { "EOF", 
"FIRST", "LAST", "TAKEN", "SOLVED", "POSITION", "'-'", "'('", "')'",
"','", "'!'", "'*'", };
unsigned short const  queens::range::RangeParser::yyintern[] = {
     0,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,     10,    261,    261,    261,    261,    261,    261,
     7,      8,     11,    261,      9,      6,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
     1,      2,      3,      4,      5, };

#ifdef TRACE
char const *const  queens::range::RangeParser::yyrules[] = {
"   0: [ 0] $        -> range",
"   1: [ 0] range    -> addr",
"   2: [ 0] range    -> addr '-' addr",
"   3: [ 1] addr     -> FIRST",
"   4: [ 0] addr     -> FIRST '(' pred ')'",
"   5: [ 1] addr     -> LAST",
"   6: [ 0] addr     -> LAST '(' pred ')'",
"   7: [ 0] addr     -> '(' pos ',' pos ')' '(' pos ',' pos ')' '(' pos ',' pos ')' '(' pos ',' pos ')'",
"   8: [ 1] pred     -> TAKEN",
"   9: [ 1] pred     -> SOLVED",
"  10: [ 0] pred     -> '!' pred",
"  11: [ 1] pos      -> POSITION",
"  12: [ 0] pos      -> '*'",
};
#endif
unsigned short const queens::range::RangeParser::yylength[] = {
     1,      1,      3,      1,      4,      1,      4,     20,
     1,      1,      2,      1,      1, };
unsigned short const queens::range::RangeParser::yylhs   [] = {
   (unsigned short)~0u,      0,      0,      1,      1,      1,      1,      1,
     2,      2,      2,      3,      3, };

unsigned short const  queens::range::RangeParser::yygoto  [][4] = {
{      2,      1,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      6,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     10,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     13,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     15,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     18,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     20,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     23,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     25,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,     28,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,     32,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,     35,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,     38,      0,      0,  },
{      0,      0,      0,      0,  },
};

signed short const  queens::range::RangeParser::yyaction[][12] = {
{      0,      3,      4,      0,      0,      0,      0,      5,      0,      0,      0,      0,  },
{     -1,      0,      0,      0,      0,      0,     37,      0,      0,      0,      0,      0,  },
{      1,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{     -3,      0,      0,      0,      0,      0,     -3,     34,      0,      0,      0,      0,  },
{     -5,      0,      0,      0,      0,      0,     -5,     27,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      9,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,    -11,    -11,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,    -12,    -12,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     11,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,     12,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,     14,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     16,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,     17,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,     19,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     21,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,     22,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,     24,      0,      0,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      8,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     26,      0,      0,      0,  },
{     -7,      0,      0,      0,      0,      0,     -7,      0,      0,      0,      0,      0,  },
{      0,      0,      0,     29,     30,      0,      0,      0,      0,      0,     31,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     33,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     -8,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     -9,      0,      0,      0,  },
{      0,      0,      0,     29,     30,      0,      0,      0,      0,      0,     31,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,    -10,      0,      0,      0,  },
{     -6,      0,      0,      0,      0,      0,     -6,      0,      0,      0,      0,      0,  },
{      0,      0,      0,     29,     30,      0,      0,      0,      0,      0,     31,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,     36,      0,      0,      0,  },
{     -4,      0,      0,      0,      0,      0,     -4,      0,      0,      0,      0,      0,  },
{      0,      3,      4,      0,      0,      0,      0,      5,      0,      0,      0,      0,  },
{     -2,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
};

void queens::range::RangeParser::parse() {
  YYStack  yystack;
  yystack.push(0);

  // Fetch until error (throw) or accept (return)
  while(true) {
    // Current lookahead
    YYSVal          yysval;
    unsigned short  yytok = nextToken(yysval);

    if(yytok <  YYINTERN)  yytok = yyintern[yytok];
    if(yytok >= YYINTERN)  error("Unknown Token");
#ifdef TRACE
    std::cerr << "Read " << yyterms[yytok] << std::endl;
#endif

    // Reduce until shift
    while(true) {
      signed short const  yyact = yyaction[*yystack][yytok];
      if(yyact == 0) {
        std::string                yymsg("Expecting (");
        signed short const *const  yyrow = yyaction[*yystack];
        for(unsigned  i = 0; i < 12; i++) {
          if(yyrow[i])  yymsg.append(yyterms[i]) += '|';
        }
        *yymsg.rbegin() = ')';
        error(yymsg.append(" instead of ").append(yyterms[yytok]));
        return;
      }
      if(yyact >  1) { // shift
#ifdef TRACE
        std::cerr << "Push " << yyterms[yytok] << std::endl;
#endif
        yystack.push(yyact, yysval);
        break;
      }
      else {           // reduce (includes accept)
        YYSVal                yylval;
        unsigned short const  yyrno = (yyact < 0)? -yyact : 0;
        unsigned short const  yylen = yylength[yyrno];
        
#ifdef TRACE
        std::cerr << "Reduce by " << yyrules[yyrno] << std::endl;
#endif
        switch(yyrno) { // do semantic actions
        case 0:         // accept
          return;
case 1: {
#line 165 "RangeParser.ypp"

          m_range = std::make_shared<SRange>(
	              std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		      std::static_pointer_cast<SAddress>(yystack[yylen - 1])
		    );
        
#line 338 "RangeParser.cpp"
break;
}
case 2: {
#line 171 "RangeParser.ypp"

          m_range = std::make_shared<SRange>(
	              std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		      std::static_pointer_cast<SAddress>(yystack[yylen - 3])
		    );
	
#line 349 "RangeParser.cpp"
break;
}
case 3: {
#line 178 "RangeParser.ypp"

        yylval = SAddress::createFirst(SPredicate::TRUE);
       
#line 357 "RangeParser.cpp"
break;
}
case 4: {
#line 181 "RangeParser.ypp"

	yylval = SAddress::createFirst(std::static_pointer_cast<SPredicate>(yystack[yylen - 3]));
       
#line 365 "RangeParser.cpp"
break;
}
case 5: {
#line 184 "RangeParser.ypp"

	yylval = SAddress::createLast(SPredicate::TRUE);
       
#line 373 "RangeParser.cpp"
break;
}
case 6: {
#line 187 "RangeParser.ypp"

	yylval = SAddress::createLast(std::static_pointer_cast<SPredicate>(yystack[yylen - 3]));
       
#line 381 "RangeParser.cpp"
break;
}
case 7: {
#line 190 "RangeParser.ypp"

         uint64_t  spec = 0L;
	 unsigned  wild = 0;
	 buildSpec(spec, wild, *yystack[yylen - 2]);
	 buildSpec(spec, wild, *yystack[yylen - 4]);
	 buildSpec(spec, wild, *yystack[yylen - 7]);
	 buildSpec(spec, wild, *yystack[yylen - 9]);
	 buildSpec(spec, wild, *yystack[yylen - 12]);
	 buildSpec(spec, wild, *yystack[yylen - 14]);
	 buildSpec(spec, wild, *yystack[yylen - 17]);
	 buildSpec(spec, wild, *yystack[yylen - 19]);
	 yylval = SAddress::create(spec, wild);
       
#line 399 "RangeParser.cpp"
break;
}
case 8: {
#line 204 "RangeParser.ypp"
 yylval = SPredicate::TAKEN; 
#line 405 "RangeParser.cpp"
break;
}
case 9: {
#line 205 "RangeParser.ypp"
 yylval = SPredicate::SOLVED; 
#line 411 "RangeParser.cpp"
break;
}
case 10: {
#line 206 "RangeParser.ypp"

	yylval = SPredicate::createInverted(std::static_pointer_cast<SPredicate>(yystack[yylen - 2]));
       
#line 419 "RangeParser.cpp"
break;
}
case 11: {
#line 210 "RangeParser.ypp"
 yylval = yystack[yylen - 1]; 
#line 425 "RangeParser.cpp"
break;
}
case 12: {
#line 211 "RangeParser.ypp"
 yylval = std::make_shared<SPosition>(-1); 
#line 431 "RangeParser.cpp"
break;
}
        }
        
        yystack.pop(yylen);
        yystack.push(yygoto[*yystack][yylhs[yyrno]], yylval);
      }
    }
  }
}
