module esm::AST

// Abstract syntax for the Extended State Machine DSL. Types are prefixed
// with "A" (Machine/VarDecl/Type/... are taken by esm::Syntax's concrete
// nonterminals, and both modules are imported together in CST2AST.rsc).
//
// Every data type carries a "src" location so Check.rsc can attach
// error()/warning() to a precise position. Guards are list[AExpr] of length
// 0 (unguarded) or 1 (guarded) rather than a Maybe, to keep this
// dependency-free.

data AMachine(loc src = |unknown:///|)
  = machine(str name, list[AVarDecl] vars, list[AEventDecl] events, list[AState] states)
  ;

data AVarDecl(loc src = |unknown:///|)
  = varDecl(str name, AType tp, AExpr init)
  ;

data AType
  = intType()
  | boolType()
  ;

data AEventDecl(loc src = |unknown:///|)
  = eventDecl(str name, list[AParam] params)
  ;

data AParam(loc src = |unknown:///|)
  = param(str name, AType tp)
  ;

data AState(loc src = |unknown:///|)
  = state(str name, bool isInitial, bool isFinal,
      list[AStat] entryActions, list[AStat] exitActions, list[ATransition] transitions)
  ;

data ATransition(loc src = |unknown:///|)
  = transition(str event, list[str] args, list[AExpr] guard, str target, list[AStat] actions)
  ;

data AStat(loc src = |unknown:///|)
  = assign(str var, AExpr expr)
  ;

// Reused both for boolean guards and arithmetic expressions; Check.rsc is
// responsible for rejecting ill-typed combinations (e.g. a guard that isn't
// bool, or arithmetic on a bool variable).
data AExpr(loc src = |unknown:///|)
  = intLit(int ival)
  | trueLit()
  | falseLit()
  | ref(str name)
  | not(AExpr e)
  | neg(AExpr e)
  | mul(AExpr l, AExpr r)
  | div(AExpr l, AExpr r)
  | add(AExpr l, AExpr r)
  | sub(AExpr l, AExpr r)
  | lt(AExpr l, AExpr r)
  | leq(AExpr l, AExpr r)
  | gt(AExpr l, AExpr r)
  | geq(AExpr l, AExpr r)
  | eq(AExpr l, AExpr r)
  | neq(AExpr l, AExpr r)
  | and(AExpr l, AExpr r)
  | or(AExpr l, AExpr r)
  ;
