@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Jurgen J. Vinju - Jurgen.Vinju@cwi.nl - CWI}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
@contributor{Arnold Lankamp - Arnold.Lankamp@cwi.nl}
module lang::rascal::grammar::ParserGenerator

import Grammar;
import lang::rascal::grammar::definition::Parameters;
import lang::rascal::grammar::definition::Regular;
import lang::rascal::grammar::definition::Productions;
import lang::rascal::grammar::definition::Modules;
import lang::rascal::grammar::definition::Priorities;
import lang::rascal::grammar::definition::Literals;
import lang::rascal::grammar::definition::Keywords;
import lang::rascal::grammar::Lookahead;
import lang::rascal::grammar::Assimilator;
import ParseTree;
import String;
import List;
import Node;
import Set;
import Map;
import IO;
import Exception;
  
// TODO: replace this complex data structure with several simple ones
private alias Items = map[Symbol,map[Item item, tuple[str new, int itemId] new]];
public anno str Symbol@prefix;

@doc{Used in bootstrapping only, to generate a parser for Rascal modules without concrete syntax.}
public str generateRootParser(str package, str name, Grammar gr) {
  // we annotate the grammar to generate identifiers that are different from object grammar identifiers
  gr = visit (gr) { case s:sort(_) => meta(s) case s:layouts(_) => meta(s) }
  int uniqueItem = -3; // -1 and -2 are reserved by the SGTDBF implementation
  int newItem() { uniqueItem -= 1; return uniqueItem; };
  // make sure the ` sign is expected for expressions and every non-terminal which' first set is governed by Pattern or Expression, even though ` not in the language yet
  rel[Symbol,Symbol] quotes = { <x, \char-class([range(40,40),range(96,96)])> | x <- [meta(sort("Expression")),meta(sort("Pattern")),meta(sort("Command")),meta(sort("Statement")),meta(layouts("LAYOUTLIST"))]}; 
  return generate(package, name, "org.rascalmpl.parser.gtd.SGTDBF", newItem, false, true, quotes, gr);
}

@doc{Used to generate parser that parse object language only}
public str generateObjectParser(str package, str name, Grammar gr) {
  int uniqueItem = 2;
  int newItem() { uniqueItem += 2; return uniqueItem; };
  // make sure the < is expected for every non-terminal
  rel[Symbol,Symbol] quotes = {<x,\char-class([range(60,60)])> | Symbol x:sort(_) <- gr.rules} // any sort could start with <
                            + {<x,\char-class([range(60,60)])> | Symbol x:layouts(_) <- gr.rules}
                            + {<layouts("$QUOTES"),\char-class([range(0,65535)])>} // always expect quoting layout (because the actual content is unknown at generation time)
                            ; 
  // prepare definitions for quoting layout
  gr = compose(gr, grammar({}, layoutProductions(gr)));
  return generate(package, name, "org.rascalmpl.library.lang.rascal.syntax.RascalRascal", newItem, false, false, quotes, gr);
}

@doc{
  Used to generate subclasses of object grammars that can be used to parse Rascal modules
  with embedded concrete syntax fragments.
}   
public str generateMetaParser(str package, str name, str super, Grammar gr) {
  int uniqueItem = 1; // we use the odd numbers here
  int newItem() { uniqueItem += 2; return uniqueItem; };
  
  gr = expandParameterizedSymbols(gr);
  
  fr = grammar({}, fromRascal(gr));
  tr = grammar({}, toRascal(gr));
  q = grammar({}, quotes()); // TODO parametrize quotes to use quote definitions
  l = grammar({}, layoutProductions(gr));
  
  full = compose(fr, compose(tr, compose(q, l)));
  
  return generate(package, name, super, newItem, true, false, {}, full);
}

public str generate(str package, str name, str super, int () newItem, bool callSuper, bool isRoot, rel[Symbol,Symbol] extraLookaheads, Grammar gr) {
    println("expanding parameterized symbols");
    gr = expandParameterizedSymbols(gr);
    
    println("generating stubs for regular");
    gr = makeRegularStubs(gr);
   
    println("generating literals");
    gr = literals(gr);
    
    println("establishing production set");
    uniqueProductions = {p | /Production p := gr, prod(_,_,_) := p || regular(_,_) := p, restricted(_) !:= p.rhs};
 
    println("generating item allocations");
    newItems = generateNewItems(gr, newItem);
   
    println("computing priority and associativity filter");
    rel[int parent, int child] dontNest = computeDontNests(newItems, gr);
    // this creates groups of children that forbidden below certain parents
    rel[set[int] parents, set[int] children] dontNestGroups = 
      {<c,g[c]> | rel[set[int] children, int parent] g := {<dontNest[p],p> | p <- dontNest.parent}, c <- g.children};
   
    //println("computing lookahead sets");
    //gr = computeLookaheads(gr, extraLookaheads);
    
    //println("optimizing lookahead automaton");
    //gr = compileLookaheads(gr);
   
    println("printing the source code of the parser class");
    
    return "package <package>;
           '
           'import java.io.ByteArrayInputStream;
           'import java.io.IOException;
           '
           'import org.eclipse.imp.pdb.facts.type.TypeFactory;
           'import org.eclipse.imp.pdb.facts.IConstructor;
           'import org.eclipse.imp.pdb.facts.IValue;
           'import org.eclipse.imp.pdb.facts.IMap;
           'import org.eclipse.imp.pdb.facts.ISet;
           'import org.eclipse.imp.pdb.facts.IRelation;
           'import org.eclipse.imp.pdb.facts.ITuple;
           'import org.eclipse.imp.pdb.facts.IInteger;
           'import org.eclipse.imp.pdb.facts.exceptions.FactTypeUseException;
           'import org.eclipse.imp.pdb.facts.io.StandardTextReader;
           'import org.rascalmpl.parser.gtd.stack.*;
           'import org.rascalmpl.parser.gtd.util.IntegerKeyedHashMap;
           'import org.rascalmpl.parser.gtd.util.IntegerList;
           'import org.rascalmpl.parser.gtd.util.IntegerMap;
           'import org.rascalmpl.values.uptr.Factory;
           'import org.rascalmpl.parser.ASTBuilder;
           'import org.rascalmpl.parser.IParserInfo;
           '
           'public class <name> extends <super> implements IParserInfo {
           '<if (isRoot) {>
           '  protected static final TypeFactory _tf = TypeFactory.getInstance();
           '
           '  private static final IntegerMap _resultStoreIdMappings;
           '  private static final IntegerKeyedHashMap\<IntegerList\> _dontNest;
           '	
           '  private static void _putDontNest(IntegerKeyedHashMap\<IntegerList\> result, int parentId, int childId) {
           '    IntegerList donts = result.get(childId);
           '    if (donts == null) {
           '      donts = new IntegerList();
           '      result.put(childId, donts);
           '    }
           '    donts.add(parentId);
           '  }
           '    
           '  protected int getResultStoreId(int parentId){
           '    return _resultStoreIdMappings.get(parentId);
           '  }<}>
           '    
           '  protected static IntegerKeyedHashMap\<IntegerList\> _initDontNest() {
           '    IntegerKeyedHashMap\<IntegerList\> result = <if (!isRoot) {><super>._initDontNest()<} else {>new IntegerKeyedHashMap\<IntegerList\>()<}>; 
           '    
           '    <for (<f,c> <- dontNest) {>
           '    _putDontNest(result, <f>, <c>);<}>
           '      
           '    return result;
           '  }
           '    
           '  protected static IntegerMap _initDontNestGroups() {
           '    IntegerMap result = <if (!isRoot) {><super>._initDontNestGroups()<} else {>new IntegerMap()<}>;
           '    int resultStoreId = result.size();
           '    
           '    <for (<parentIds, childrenIds> <- dontNestGroups) {>
           '    ++resultStoreId;
           '    <for (pid <- parentIds) {>
                result.putUnsafe(<pid>, resultStoreId);<}><}>
           '      
           '    return result;
           '  }
           '    
           '  protected IntegerList getFilteredParents(int childId) {
           '		return _dontNest.get(childId);
           '  }
           '    
           '  public org.rascalmpl.ast.LanguageAction getAction(IConstructor prod) {
           '    return _languageActions.get(prod);
           '  }
           '    
           '  // initialize priorities     
           '  static {
           '    _dontNest = _initDontNest();
           '    _resultStoreIdMappings = _initDontNestGroups();
           '  }
           '    
           '  // Production declarations
           '	<for (p <- uniqueProductions) {>
           '  private static final IConstructor <value2id(p)> = (IConstructor) _read(\"<esc("<unmeta(p)>")>\", Factory.Production);<}>
           '    
           '  // Item declarations
           '	<for (Symbol s <- newItems, isNonterminal(s)) {
	           items = newItems[s];
	           map[Production, list[Item]] alts = ();
	           for(Item item <- items) {
		         Production prod = item.production;
		         if (prod in alts) {
			       alts[prod] = alts[prod] + item;
		         } else {
			     alts[prod] = [item];
		       }
	         }>
           '	
           '  private static class <value2id(s)> {<for(Production alt <- alts) { list[Item] lhses = alts[alt]; id = value2id(alt);>
           '    public final static AbstractStackNode[] <id> = _init_<id>();
           '    private static final AbstractStackNode[] _init_<id>() {
           '      AbstractStackNode[] tmp = new AbstractStackNode[<size(lhses)>];
           '      <for (Item i <- lhses) { pi = value2id(i.production); ii = (i.index != -1) ? i.index : 0;>
           '      tmp[<ii>] = <items[i].new>;<}>
           '      return tmp;
           '	}<}>
           '  }<}>
           '	
           '  public <name>() {
           '    super();
           '  }
           '
           '  // Parse methods    
           '  <for (Symbol nont <- gr.rules, isNonterminal(nont)) { >
           '  <generateParseMethod(newItems, callSuper, gr.rules[nont])><}>
           '}";
}  

public &T <: value unmeta(&T <: value p) {
  return visit(p) {
    case meta(s) => s
  }
}

rel[int,int] computeDontNests(Items items, Grammar grammar) {
  // first we compute a map from productions to their last items (which identify each production)
  prodItems = (p:items[rhs][item(p,size(lhs)-1)].itemId | /Production p:prod(list[Symbol] lhs,Symbol rhs, _) := grammar);
  
  // now we get the "don't nest" relation, which is defined by associativity and priority declarations
  dnn       = {doNotNest(grammar.rules[nt]) | Symbol nt <- grammar.rules};
   
  // finally we produce a relation between item id for use the internals of the parser
  return {<items[father.rhs][item(father,pos)].itemId, prodItems[child]> | <father,pos,child> <- dnn};
}

@doc{This function generates Java code to allocate a new item for each position in the grammar.
We first collect these in a map, such that we can generate static fields. It's a simple matter of caching
constants to improve run-time efficiency of the generated parser}
private map[Symbol,map[Item,tuple[str new, int itemId]]] generateNewItems(Grammar g, int () newItem) {
  map[Symbol,map[Item,tuple[str new, int itemId]]] items = ();
  map[Item,tuple[str new, int itemId]] fresh = ();
  
  visit (g) {
    case Production p:prod([],Symbol s,_) : {
       int counter = newItem();
       items[s]?fresh += (item(p, -1):<"new EpsilonStackNode(<counter>, 0)", counter>);
    }
    case Production p:prod(list[Symbol] lhs, Symbol s,_) : 
      for (int i <- index(lhs)) 
        items[s]?fresh += (item(p, i): sym2newitem(g, lhs[i], newItem, i));
    case Production p:regular(Symbol s, _) :
      switch(s) {
        case \iter(Symbol elem) : 
          items[s]?fresh += (item(p,0):sym2newitem(g, elem, newItem, 0));
        case \iter-star(Symbol elem) : 
          items[s]?fresh += (item(p,0):sym2newitem(g, elem, newItem, 0));
        case \iter-seps(Symbol elem, list[Symbol] seps) : {
          items[s]?fresh += (item(p,0):sym2newitem(g, elem, newItem, 0));
          for (int i <- index(seps)) 
            items[s]?fresh += (item(p,i+1):sym2newitem(g, seps[i], newItem, i+1));
        }
        case \iter-star-seps(Symbol elem, list[Symbol] seps) : {
          items[s]?fresh += (item(p,0):sym2newitem(g, elem, newItem, 0));
          for (int i <- index(seps)) 
            items[s]?fresh += (item(p,i+1):sym2newitem(g, seps[i], newItem, i+1));
        } 
     }
  }
  return items;
}

private str split(str x) {
  if (size(x) <= 20000) {
    return "\"<esc(x)>\"";
  }
  else {
    return "<split(substring(x, 0,10000))>, <split(substring(x, 10000))>"; 
  }
}

@doc{this function selects all symbols for which a parse method should be generated}
private bool isNonterminal(Symbol s) {
  switch (s) {
    case \sort(_) : return true;
    case \lex(_) : return true;
    case \keywords(_) : return true;
    case \meta(x) : return isNonterminal(x);
    case \parameterized-sort(_,_) : return true;
    case \start(_) : return true;
    case \layouts(_) : return true;
    default: return false;
  }
}

public str generateParseMethod(Items items, bool callSuper, Production p) {
  return "public void <sym2name(p.rhs)>() {
         '  <if (callSuper) {>super.<sym2name(p.rhs)>();<}>
         '  <generateExpect(items, p, false)>
         '}";
}

public str generateExpect(Items items, Production p, bool reject){
    // note that this code heavily leans on the fact that production combinators are normalized 
    // (distribution and factoring laws have been applied to put a production expression in canonical form)
    
    switch (p) {
      case prod(_,_,_) : 
	       return "// <p>
	              'expect<reject ? "Reject" : "">(<value2id(p)>, <sym2name(p.rhs)>.<value2id(p)>);";
      case lookahead(_, classes, Production q) :
        return "if (<generateClassConditional(classes)>) {
               '  <generateExpect(items, q, reject)>
               '}";
      case choice(_, {l:lookahead(_, _, q)}) :
        return generateExpect(items, l, reject);
      case choice(_, {lookahead(_, classes, Production q), set[Production] rest}) :
        return "if (<generateClassConditional(classes)>) {
               '  <generateExpect(items, q, reject)>
               '} else {
               '  <generateExpect(items, choice(q.rhs, rest), reject)>
               '}";
      case choice(_, set[Production] ps) :
        return "<for (Production q <- ps){>
               '<generateExpect(items, q, reject)><}>";
      case priority(_, list[Production] ps) : 
        return generateExpect(items, choice(p.rhs, { q | q <- ps }), reject);
      case associativity(_,_,set[Production] ps) :
        return generateExpect(items, choice(p.rhs, ps), reject); 
    }
    
    throw "not implemented <p>";
}

str generateClassConditional(set[Symbol] classes) {
  if (eoi() in classes) {
    return ("lookAheadChar == 0" 
           | it + " || <generateRangeConditional(r)>"
           | \char-class(list[CharRange] ranges) <- classes, r <- ranges);
  }
  else {
    ranges = [r | \char-class(ranges) <- classes, r <- ranges];
    
    return ("<generateRangeConditional(head(ranges))>"| it + " || <generateRangeConditional(r)> "
           | r <- tail(ranges));
  } 
}

str generateRangeConditional(CharRange r) {
  switch (r) {
    case single(i) : return "(lookAheadChar == <i>)";
    case range(0,65535) : return "(true /*every char*/)";
    case range(i, i) : return "(lookAheadChar == <i>)";
    case range(i, j) : return "((lookAheadChar \>= <i>) && (lookAheadChar \<= <j>))";
    default: throw "unexpected range type: <r>";
  }
}

public str generateSeparatorExpects(Grammar grammar, int() id, list[Symbol] seps) {
   if (seps == []) {
     return "";
   }
   
   return (sym2newitem(grammar, head(seps), id, 1).new | it + ", <sym2newitem(grammar, seps[i+1], id, i+2).new>" | int i <- index(tail(seps)));
}

public str literals2ints(list[Symbol] chars){
    if(chars == []) return "";
    
    str result = "<head(head(chars).ranges).start>";
    
    for(ch <- tail(chars)){
        result += ",<head(ch.ranges).start>";
    }
    
    return result;
}

// TODO
public str ciliterals2ints(list[Symbol] chars){
    throw "case insensitive literals not yet implemented by parser generator";
}

public tuple[str new, int itemId] sym2newitem(Grammar grammar, Symbol sym, int() id, int dot){
    itemId = id();
    
    list[str] enters = [];
    list[str] exits = [];
    filters = "";
    
    if (conditional(_, conds) := sym) {
      conds = expandKeywords(grammar, conds);
      exits += ["new CharFollowRequirement(new char[][]{<generateCharClassArrays(ranges)>})" | follow(\char-class(ranges)) <- conds];
      exits += ["new StringFollowRequirement(new char[] {<literals2ints(str2syms(s))>})" | follow(lit(s)) <- conds]; 
      exits += ["new CharFollowRestriction(new char[][]{<generateCharClassArrays(ranges)>})" | \not-follow(\char-class(ranges)) <- conds];
      exits += ["new StringFollowRestriction(new char[] {<literals2ints(str2syms(s))>})" | \not-follow(lit(s)) <- conds];
      exits += ["new CharMatchRestriction(new char[][]{<generateCharClassArrays(ranges)>})" | \delete(\char-class(ranges)) <- conds];
      exits += ["new StringMatchRestriction(new char[] {<literals2ints(str2syms(s))>})" | \delete(lit(s)) <- conds]; 
      enters += ["new CharPrecedeRequirement(new char[][]{<generateCharClassArrays(ranges)>})" | precede(\char-class(ranges)) <- conds];
      enters += ["new StringPrecedeRequirement(new char[] {<literals2ints(str2syms(s))>})" | precede(lit(s)) <- conds]; 
      enters += ["new CharPrecedeRestriction(new char[][]{<generateCharClassArrays(ranges)>})" | \not-precede(\char-class(ranges)) <- conds];
      enters += ["new StringPrecedeRestriction(new char[] {<literals2ints(str2syms(s))>})" | \not-precede(lit(s)) <- conds]; 
      
      sym = sym.symbol;
    }
    
    filters  = "new IEnterFilter[] {<(enters != []) ? head(enters) : ""><for (enters != [], f <- tail(enters)) {>, <f><}>}"
             + ", new ICompletionFilter[] {<(exits != []) ? head(exits) : ""><for (exits != [], f <- tail(exits)) {>, <f><}>}";
    
    switch ((meta(_) := sym) ? sym.wrapped : sym) {
        case \label(_,s) : 
            return sym2newitem(grammar, s, id, dot); // ignore labels
        case \sort(n) : 
            return <"new NonTerminalStackNode(<itemId>, <dot>, \"<sym2name(sym)>\", <filters>)", itemId>;
        case \lex(n) : 
            return <"new NonTerminalStackNode(<itemId>, <dot>, \"<sym2name(sym)>\", <filters>)", itemId>;
        case \keywords(n) : 
            return <"new NonTerminalStackNode(<itemId>, <dot>, \"<sym2name(sym)>\", <filters>)", itemId>;
        case \layouts(_) :
            return <"new NonTerminalStackNode(<itemId>, <dot>, \"<sym2name(sym)>\", <filters>)", itemId>;
        case \parameterized-sort(n,args): 
            return <"new NonTerminalStackNode(<itemId>, <dot>, \"<sym2name(sym)>\", <filters>)", itemId>;
        case \parameter(n) :
            throw "all parameters should have been instantiated by now";
        case \start(s) : 
            return <"new NonTerminalStackNode(<itemId>, <dot>, \"<sym2name(sym)>\", <filters>)", itemId>;
        case \lit(l) : 
            if (/p:prod(list[Symbol] chars,sym,attrs([\literal()])) := grammar.rules[sym])
                return <"new LiteralStackNode(<itemId>, <dot>, <value2id(p)>, new char[] {<literals2ints(chars)>}, <filters>)",itemId>;
            else throw "literal not found in grammar: <grammar>";
        case \cilit(l) : 
            if (/p:prod(list[Symbol] chars,sym,attrs([literal()])) := grammar.rules[sym])
                return <"new CaseInsensitiveLiteralStackNode(<itemId>, <dot>, <value2id(p)>, new char[] {<literals2ints(chars)>}, <filters>)",itemId>;
            else throw "ci-literal not found in grammar: <grammar>";
        case \iter(s) : 
            return <"new ListStackNode(<itemId>, <dot>, <value2id(regular(sym,\no-attrs()))>, <sym2newitem(grammar, s, id, 0).new>, true, <filters>)",itemId>;
        case \iter-star(s) :
            return <"new ListStackNode(<itemId>, <dot>, <value2id(regular(sym,\no-attrs()))>, <sym2newitem(grammar, s, id, 0).new>, false, <filters>)", itemId>;
        case \iter-seps(Symbol s,list[Symbol] seps) : {
            reg = regular(sym,\no-attrs());
            return <"new SeparatedListStackNode(<itemId>, <dot>, <value2id(reg)>, <sym2newitem(grammar, s, id, 0).new>, new AbstractStackNode[]{<generateSeparatorExpects(grammar,id,seps)>}, true, <filters>)",itemId>;
        }
        case \iter-star-seps(Symbol s,list[Symbol] seps) : {
            reg = regular(sym,\no-attrs());
            return <"new SeparatedListStackNode(<itemId>, <dot>, <value2id(reg)>, <sym2newitem(grammar, s, id, 0).new>, new AbstractStackNode[]{<generateSeparatorExpects(grammar,id,seps)>}, false, <filters>)",itemId>;
        }
        case \opt(s) : {
            reg =  regular(sym,\no-attrs());
            return <"new OptionalStackNode(<itemId>, <dot>, <value2id(reg)>, <sym2newitem(grammar, s, id, 0).new>, <filters>)", itemId>;
        }
        case \alt(as) : {
            return <"new AlternativeStackNode(<itemId>, <dot>, <value2id(regular(sym, \no-attrs()))>, new AbstractStackNode[]{<sym2newitem(grammar, head(alts), id, 0)> <for (a <- tail(alts)) {>, <sym2newitem(grammar, a, id, 0)><}>}, <filters>)", itemId>;
        }
        case \seq(ss) : {
            return <"new SequenceStackNode(<itemId>, <dot>, <value2id(regular(sym, \no-attrs()))>, new AbstractStackNode[]{<sym2newitem(grammar, head(ss), id, 0)> <for (i <- tail(index(ss))) {>, <sym2newitem(grammar, ss[i], id, i)><}>}, <filters>)", itemId>;
        }
        case \char-class(list[CharRange] ranges) : 
            return <"new CharStackNode(<itemId>, <dot>, new char[][]{<generateCharClassArrays(ranges)>}, <filters>)", itemId>;
        default: 
            throw "unexpected symbol <sym> while generating parser code";
    }
}

public str generateCharClassArrays(list[CharRange] ranges){
    if(ranges == []) return "";
    result = "";
    if(range(from, to) := head(ranges)) 
        result += "{<from>,<to>}";
    for(range(from, to) <- tail(ranges))
        result += ",{<from>,<to>}";
    return result;
}

public str esc(Symbol s){
    return esc("<s>");
}

private map[str,str] javaStringEscapes = ( "\n":"\\n", "\"":"\\\"", "\t":"\\t", "\r":"\\r","\\u":"\\\\u","\\":"\\\\");

public str esc(str s){
    return escape(s, javaStringEscapes);
}

private map[str,str] javaIdEscapes = javaStringEscapes + ("-":"_");

public str escId(str s){
    return escape(s, javaIdEscapes);
}

public str sym2name(Symbol s){
    switch(s){
        case sort(x) : return "<x>";
        case meta(x) : return "$<sym2name(x)>";
        default      : return value2id(s);
    }
}

public str value2id(value v) {
  return v2i(v);
}

str v2i(value v) {
    switch (v) {
        case item(p:prod(_,Symbol u,_), int i) : return "<v2i(u)>.<v2i(p)>_<v2i(i)>";
        case label(str x,Symbol u) : return escId(x) + "_" + v2i(u);
        case layouts(str x) : return "layouts_<escId(x)>";
        case "cons"(str x) : return "cons_<escId(x)>";
        case sort(str s)   : return "<s>";
        case \lex(str s)   : return "<s>";
        case keywords(str s)   : return "<s>";
        case meta(Symbol s) : return "$<v2i(s)>";
        case \parameterized-sort(str s, list[Symbol] args) : return ("<s>_" | it + "_<v2i(arg)>" | arg <- args);
        case cilit(/<s:^[A-Za-z0-9\-\_]+$>/)  : return "cilit_<escId(s)>";
	    case lit(/<s:^[A-Za-z0-9\-\_]+$>/) : return "lit_<escId(s)>"; 
        case int i         : return i < 0 ? "min_<-i>" : "<i>";
        case str s         : return ("" | it + "_<charAt(s,i)>" | i <- [0..size(s)-1]);
        case str s()       : return escId(s);
        case node n        : return "<escId(getName(n))>_<("" | it + "_" + v2i(c) | c <- getChildren(n))>";
        case list[value] l : return ("" | it + "_" + v2i(e) | e <- l);
        case set[value] s  : return ("" | it + "_" + v2i(e) | e <- s);
        default            : throw "value not supported <v>";
    }
}
