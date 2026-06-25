module esm::CST2AST

import esm::AST;
import esm::Syntax;
import ParseTree;
import String;

// Concrete-to-abstract mapping, written by hand per nonterminal rather than
// a blind implode(): Expr's precedence layering means the parse tree shape
// does not match the flat AST shape we want for the checker and code
// generator, and Transition's two optional groups (when/do) need their four
// combinations spelled out explicitly.

AMachine cst2ast(start[Machine] pt) = cst2ast(pt.top);

AMachine cst2ast(Machine m) {
  switch (m) {
    case (Machine)`machine <Name name> { <Decl* decls> }`: {
      list[AVarDecl] vars = [];
      list[AEventDecl] events = [];
      list[AState] states = [];
      for (Decl d <- decls) {
        switch (d) {
          case (Decl)`<VarDecl vd>`: vars += [toVarDecl(vd)];
          case (Decl)`<EventDecl ed>`: events += [toEventDecl(ed)];
          case (Decl)`<StateDecl sd>`: states += [toStateDecl(sd)];
        }
      }
      return machine("<name>", vars, events, states)[src=m@\loc];
    }
  }
  throw "Unhandled Machine: <m>";
}

AVarDecl toVarDecl(VarDecl vd) {
  switch (vd) {
    case (VarDecl)`var <Name name> : <Type tp> = <Literal init>`:
      return varDecl("<name>", toType(tp), toLiteral(init))[src=vd@\loc];
  }
  throw "Unhandled VarDecl: <vd>";
}

AType toType(Type t) {
  switch (t) {
    case (Type)`int`: return intType();
    case (Type)`bool`: return boolType();
  }
  throw "Unhandled Type: <t>";
}

AExpr toLiteral(Literal lit) {
  switch (lit) {
    case (Literal)`<IntLit i>`: return intLit(toInt("<i>"))[src=lit@\loc];
    case (Literal)`true`: return trueLit()[src=lit@\loc];
    case (Literal)`false`: return falseLit()[src=lit@\loc];
  }
  throw "Unhandled Literal: <lit>";
}

AEventDecl toEventDecl(EventDecl ed) {
  switch (ed) {
    case (EventDecl)`event <Name name> ( <{Param ","}* params> )`:
      return eventDecl("<name>", [toParam(p) | Param p <- params])[src=ed@\loc];
  }
  throw "Unhandled EventDecl: <ed>";
}

AParam toParam(Param p) {
  switch (p) {
    case (Param)`<Name name> : <Type tp>`:
      return param("<name>", toType(tp))[src=p@\loc];
  }
  throw "Unhandled Param: <p>";
}

AState toStateDecl(StateDecl sd) {
  switch (sd) {
    case (StateDecl)`state <Name name> <Modifier* mods> { <StateBody* body> }`: {
      list[str] modStrs = ["<m>" | Modifier m <- mods];
      bool isInitial = "initial" in modStrs;
      bool isFinal = "final" in modStrs;
      list[AStat] entryActs = [];
      list[AStat] exitActs = [];
      list[ATransition] transitions = [];
      for (StateBody b <- body) {
        switch (b) {
          case (StateBody)`<EntryAction ea>`: entryActs += toEntryStats(ea);
          case (StateBody)`<ExitAction xa>`: exitActs += toExitStats(xa);
          case (StateBody)`<Transition t>`: transitions += [toTransition(t)];
        }
      }
      return state("<name>", isInitial, isFinal, entryActs, exitActs, transitions)[src=sd@\loc];
    }
  }
  throw "Unhandled StateDecl: <sd>";
}

list[AStat] toEntryStats(EntryAction ea) {
  switch (ea) {
    case (EntryAction)`entry <Block block>`: return toStats(block);
  }
  throw "Unhandled EntryAction: <ea>";
}

list[AStat] toExitStats(ExitAction xa) {
  switch (xa) {
    case (ExitAction)`exit <Block block>`: return toStats(block);
  }
  throw "Unhandled ExitAction: <xa>";
}

list[AStat] toStats(Block blk) {
  switch (blk) {
    case (Block)`{ <Stat* stats> }`: return [toStat(s) | Stat s <- stats];
  }
  throw "Unhandled Block: <blk>";
}

AStat toStat(Stat s) {
  switch (s) {
    case (Stat)`<Name name> := <Expr expr> ;`:
      return assign("<name>", toExpr(expr))[src=s@\loc];
  }
  throw "Unhandled Stat: <s>";
}

tuple[str ev, list[str] args] toEventRef(EventRef er) {
  switch (er) {
    case (EventRef)`<Name name> ( <{Name ","}* args> )`:
      return <"<name>", ["<a>" | Name a <- args]>;
  }
  throw "Unhandled EventRef: <er>";
}

ATransition toTransition(Transition tr) {
  switch (tr) {
    case (Transition)`on <EventRef evt> -\> <Name target>`: {
      er = toEventRef(evt);
      return transition(er.ev, er.args, [], "<target>", [])[src=tr@\loc];
    }
    case (Transition)`on <EventRef evt> when <Expr guard> -\> <Name target>`: {
      er = toEventRef(evt);
      return transition(er.ev, er.args, [toExpr(guard)], "<target>", [])[src=tr@\loc];
    }
    case (Transition)`on <EventRef evt> -\> <Name target> do <Block block>`: {
      er = toEventRef(evt);
      return transition(er.ev, er.args, [], "<target>", toStats(block))[src=tr@\loc];
    }
    case (Transition)`on <EventRef evt> when <Expr guard> -\> <Name target> do <Block block>`: {
      er = toEventRef(evt);
      return transition(er.ev, er.args, [toExpr(guard)], "<target>", toStats(block))[src=tr@\loc];
    }
  }
  throw "Unhandled Transition: <tr>";
}

AExpr toExpr(Expr e) {
  switch (e) {
    case (Expr)`( <Expr inner> )`: return toExpr(inner);
    case (Expr)`<IntLit i>`: return intLit(toInt("<i>"))[src=e@\loc];
    case (Expr)`true`: return trueLit()[src=e@\loc];
    case (Expr)`false`: return falseLit()[src=e@\loc];
    case (Expr)`<Name n>`: return ref("<n>")[src=e@\loc];
    case (Expr)`! <Expr e2>`: return not(toExpr(e2))[src=e@\loc];
    case (Expr)`- <Expr e2>`: return neg(toExpr(e2))[src=e@\loc];
    case (Expr)`<Expr l> * <Expr r>`: return mul(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> / <Expr r>`: return div(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> + <Expr r>`: return add(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> - <Expr r>`: return sub(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> \< <Expr r>`: return lt(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> \<= <Expr r>`: return leq(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> \> <Expr r>`: return gt(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> \>= <Expr r>`: return geq(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> == <Expr r>`: return eq(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> != <Expr r>`: return neq(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> && <Expr r>`: return and(toExpr(l), toExpr(r))[src=e@\loc];
    case (Expr)`<Expr l> || <Expr r>`: return or(toExpr(l), toExpr(r))[src=e@\loc];
  }
  throw "Unhandled Expr: <e>";
}
