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
      sval = std::make_shared<SNumber>(val);
      return  NUMBER;
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
  int const  pos = static_cast<SNumber const&>(position);
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
"FIRST", "LAST", "TAKEN", "SOLVED", "NUMBER", "':'", "'+'", "'-'",
"'('", "')'", "','", "'@'", "'!'", "'*'", };
unsigned short const  queens::range::RangeParser::yyintern[] = {
     0,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,     13,    261,    261,    261,    261,    261,    261,
     9,     10,     14,      7,     11,      8,    261,    261,
   261,    261,    261,    261,    261,    261,    261,    261,
   261,    261,      6,    261,    261,    261,    261,    261,
    12,    261,    261,    261,    261,    261,    261,    261,
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
"   2: [ 0] range    -> addr ':' addr",
"   3: [ 1] range    -> addr ':' '+' NUMBER",
"   4: [ 1] range    -> addr ':' '-' NUMBER",
"   5: [ 1] addr     -> FIRST",
"   6: [ 0] addr     -> FIRST '(' pred ')'",
"   7: [ 1] addr     -> LAST",
"   8: [ 0] addr     -> LAST '(' pred ')'",
"   9: [ 0] addr     -> '(' pos ',' pos ')' '(' pos ',' pos ')' '(' pos ',' pos ')' '(' pos ',' pos ')'",
"  10: [ 1] addr     -> '@' NUMBER",
"  11: [ 1] addr     -> addr '+' NUMBER",
"  12: [ 1] addr     -> addr '-' NUMBER",
"  13: [ 1] pred     -> TAKEN",
"  14: [ 1] pred     -> SOLVED",
"  15: [ 0] pred     -> '!' pred",
"  16: [ 1] pos      -> NUMBER",
"  17: [ 0] pos      -> '*'",
};
#endif
unsigned short const queens::range::RangeParser::yylength[] = {
     1,      1,      3,      4,      4,      1,      4,      1,
     4,     20,      2,      3,      3,      1,      1,      2,
     1,      1, };
unsigned short const queens::range::RangeParser::yylhs   [] = {
   (unsigned short)~0u,      0,      0,      0,      0,      1,      1,      1,
     1,      1,      1,      1,      1,      2,      2,      2,
     3,      3, };

unsigned short const  queens::range::RangeParser::yygoto  [][4] = {
{      2,      1,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      8,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     12,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     15,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     17,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     20,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     22,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     25,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,     27,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,     30,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,     34,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,     37,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,     44,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
{      0,      0,      0,      0,  },
};

signed short const  queens::range::RangeParser::yyaction[][15] = {
{      0,      3,      4,      0,      0,      0,      0,      0,      0,      5,      0,      0,      6,      0,      0,  },
{     -1,      0,      0,      0,      0,      0,     39,     40,     41,      0,      0,      0,      0,      0,      0,  },
{      1,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{     -5,      0,      0,      0,      0,      0,     -5,     -5,     -5,     36,      0,      0,      0,      0,      0,  },
{     -7,      0,      0,      0,      0,      0,     -7,     -7,     -7,     29,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      7,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{    -10,      0,      0,      0,      0,      0,    -10,    -10,    -10,      0,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     11,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,    -16,    -16,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,    -17,    -17,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     13,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,     14,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     16,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     18,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,     19,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     21,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     23,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,     24,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     26,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      9,      0,      0,      0,      0,      0,      0,      0,      0,     10,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     28,      0,      0,      0,      0,  },
{     -9,      0,      0,      0,      0,      0,     -9,     -9,     -9,      0,      0,      0,      0,      0,      0,  },
{      0,      0,      0,     31,     32,      0,      0,      0,      0,      0,      0,      0,      0,     33,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     35,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,    -13,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,    -14,      0,      0,      0,      0,  },
{      0,      0,      0,     31,     32,      0,      0,      0,      0,      0,      0,      0,      0,     33,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,    -15,      0,      0,      0,      0,  },
{     -8,      0,      0,      0,      0,      0,     -8,     -8,     -8,      0,      0,      0,      0,      0,      0,  },
{      0,      0,      0,     31,     32,      0,      0,      0,      0,      0,      0,      0,      0,     33,      0,  },
{      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,     38,      0,      0,      0,      0,  },
{     -6,      0,      0,      0,      0,      0,     -6,     -6,     -6,      0,      0,      0,      0,      0,      0,  },
{      0,      3,      4,      0,      0,      0,      0,     45,     46,      5,      0,      0,      6,      0,      0,  },
{      0,      0,      0,      0,      0,     43,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,     42,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{    -12,      0,      0,      0,      0,      0,    -12,    -12,    -12,      0,      0,      0,      0,      0,      0,  },
{    -11,      0,      0,      0,      0,      0,    -11,    -11,    -11,      0,      0,      0,      0,      0,      0,  },
{     -2,      0,      0,      0,      0,      0,      0,     40,     41,      0,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,     48,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{      0,      0,      0,      0,      0,     47,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{     -4,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
{     -3,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,  },
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
        for(unsigned  i = 0; i < 15; i++) {
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

          m_range = SRange::create(
	              std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		      std::static_pointer_cast<SAddress>(yystack[yylen - 1])
		    );
        
#line 365 "RangeParser.cpp"
break;
}
case 2: {
#line 171 "RangeParser.ypp"

          m_range = SRange::create(
	              std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		      std::static_pointer_cast<SAddress>(yystack[yylen - 3])
		    );
	
#line 376 "RangeParser.cpp"
break;
}
case 3: {
#line 177 "RangeParser.ypp"

          m_range = SRange::createSpan(
	              std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		      static_cast<SNumber const&>(*yystack[yylen - 4])
		    );
	
#line 387 "RangeParser.cpp"
break;
}
case 4: {
#line 183 "RangeParser.ypp"

          m_range = SRange::createSpan(
	              std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		      -static_cast<SNumber const&>(*yystack[yylen - 4])
		    );
	
#line 398 "RangeParser.cpp"
break;
}
case 5: {
#line 190 "RangeParser.ypp"

        yylval = SAddress::createFirst(SPredicate::TRUE);
       
#line 406 "RangeParser.cpp"
break;
}
case 6: {
#line 193 "RangeParser.ypp"

	yylval = SAddress::createFirst(std::static_pointer_cast<SPredicate>(yystack[yylen - 3]));
       
#line 414 "RangeParser.cpp"
break;
}
case 7: {
#line 196 "RangeParser.ypp"

	yylval = SAddress::createLast(SPredicate::TRUE);
       
#line 422 "RangeParser.cpp"
break;
}
case 8: {
#line 199 "RangeParser.ypp"

	yylval = SAddress::createLast(std::static_pointer_cast<SPredicate>(yystack[yylen - 3]));
       
#line 430 "RangeParser.cpp"
break;
}
case 9: {
#line 202 "RangeParser.ypp"

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
       
#line 448 "RangeParser.cpp"
break;
}
case 10: {
#line 215 "RangeParser.ypp"

         yylval = SAddress::createOffset(SAddress::createFirst(SPredicate::TRUE),
				     static_cast<SNumber const&>(*yystack[yylen - 2]));
       
#line 457 "RangeParser.cpp"
break;
}
case 11: {
#line 219 "RangeParser.ypp"

         yylval = SAddress::createOffset(std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		                     static_cast<SNumber const&>(*yystack[yylen - 3]));
       
#line 466 "RangeParser.cpp"
break;
}
case 12: {
#line 223 "RangeParser.ypp"

         yylval = SAddress::createOffset(std::static_pointer_cast<SAddress>(yystack[yylen - 1]),
		                     -static_cast<SNumber const&>(*yystack[yylen - 3]));
       
#line 475 "RangeParser.cpp"
break;
}
case 13: {
#line 228 "RangeParser.ypp"
 yylval = SPredicate::TAKEN; 
#line 481 "RangeParser.cpp"
break;
}
case 14: {
#line 229 "RangeParser.ypp"
 yylval = SPredicate::SOLVED; 
#line 487 "RangeParser.cpp"
break;
}
case 15: {
#line 230 "RangeParser.ypp"

	yylval = SPredicate::createInverted(std::static_pointer_cast<SPredicate>(yystack[yylen - 2]));
       
#line 495 "RangeParser.cpp"
break;
}
case 16: {
#line 234 "RangeParser.ypp"

        int const  v = static_cast<SNumber const&>(*yystack[yylen - 1]);
	if((v < 0) || (26 < v)) {
	  error("Absolute position must be in the range [0, 27)");
	}
        yylval = yystack[yylen - 1];
      
#line 507 "RangeParser.cpp"
break;
}
case 17: {
#line 241 "RangeParser.ypp"
 yylval = std::make_shared<SNumber>(-1); 
#line 513 "RangeParser.cpp"
break;
}
        }
        
        yystack.pop(yylen);
        yystack.push(yygoto[*yystack][yylhs[yyrno]], yylval);
      }
    }
  }
}
