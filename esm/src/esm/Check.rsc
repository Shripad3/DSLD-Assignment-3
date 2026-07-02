module esm::Check

import esm::AST;
import Message;
import List;
import Set;
import Map;

// Static semantic checks: exactly-one-initial, reachability, no-dead-ends,
// conservative determinism, undefined-reference checks, guard/action type
// checking. Collects a set[Message] rather than throwing, so all problems
// in a model are reported together.

// Internal type lattice for the checker. Distinct from AST's AType (which
// only describes declared variable/parameter types): cErr() lets a failed
// sub-expression (e.g. an undefined reference) propagate without triggering
// a cascade of further type-mismatch messages for the same root cause.
data CType = cInt() | cBool() | cErr();

alias Env = map[str, CType];

CType toCType(AType t) = (t == intType()) ? cInt() : cBool();

str showType(CType t) = t == cInt() ? "int" : (t == cBool() ? "bool" : "<error>");

set[Message] check(AMachine m) {
  map[str, AType] varTypes = (v.name: v.tp | v <- m.vars);
  map[str, AEventDecl] eventsByName = (e.name: e | e <- m.events);
  set[str] stateNames = {s.name | s <- m.states};

  set[Message] msgs = {};
  msgs += checkVarDecls(m.vars);
  msgs += checkInitial(m);
  msgs += checkStates(m, varTypes, eventsByName, stateNames);
  msgs += checkReachability(m, stateNames);
  return msgs;
}

set[Message] checkVarDecls(list[AVarDecl] vars) {
  set[Message] msgs = {};
  for (vd <- vars) {
    <ct, m2> = typeOfExpr(vd.init, ());
    msgs += m2;
    declared = toCType(vd.tp);
    if (ct != cErr() && ct != declared) {
      msgs += error("Initial value of \'<vd.name>\' has type <showType(ct)>, expected <showType(declared)>", vd.src);
    }
  }
  return msgs;
}

set[Message] checkInitial(AMachine m) {
  set[Message] msgs = {};
  inits = [s | s <- m.states, s.isInitial];
  if (size(inits) == 0) {
    msgs += error("Machine \'<m.name>\' has no initial state", m.src);
  } else if (size(inits) > 1) {
    for (s <- inits) {
      msgs += error("Multiple initial states declared; \'<s.name>\' is one of them", s.src);
    }
  }
  return msgs;
}

set[Message] checkReachability(AMachine m, set[str] stateNames) {
  set[Message] msgs = {};
  inits = [s.name | s <- m.states, s.isInitial];
  if (size(inits) == 0) return msgs; // already reported by checkInitial

  map[str, AState] byName = (s.name: s | s <- m.states);
  set[str] visited = {};
  list[str] frontier = inits;
  while (size(frontier) > 0) {
    name = frontier[0];
    frontier = frontier[1..];
    if (name notin visited) {
      visited += {name};
      if (name in byName) {
        for (t <- byName[name].transitions) {
          if (t.target notin visited) frontier += [t.target];
        }
      }
    }
  }

  for (s <- m.states) {
    if (s.name notin visited) {
      msgs += warning("State \'<s.name>\' is unreachable from the initial state", s.src);
    }
  }
  return msgs;
}

set[Message] checkStates(AMachine m, map[str, AType] varTypes, map[str, AEventDecl] eventsByName, set[str] stateNames) {
  set[Message] msgs = {};
  Env baseEnv = (n: toCType(varTypes[n]) | n <- varTypes);

  for (s <- m.states) {
    if (!s.isFinal && size(s.transitions) == 0) {
      msgs += error("State \'<s.name>\' has no outgoing transitions (dead end)", s.src);
    }

    msgs += checkStats(s.entryActions, varTypes, baseEnv, {});
    msgs += checkStats(s.exitActions, varTypes, baseEnv, {});

    map[str, list[ATransition]] byEvent = ();
    for (t <- s.transitions) {
      byEvent[t.event] = (t.event in byEvent ? byEvent[t.event] : []) + [t];

      if (t.event notin eventsByName) {
        msgs += error("Undefined event \'<t.event>\'", t.src);
      }
      if (t.target notin stateNames) {
        msgs += error("Undefined target state \'<t.target>\'", t.src);
      }

      Env env = baseEnv;
      set[str] paramNames = {};
      if (t.event in eventsByName) {
        ed = eventsByName[t.event];
        if (size(t.args) != size(ed.params)) {
          msgs += error("Event \'<t.event>\' expects <size(ed.params)> parameter(s), got <size(t.args)>", t.src);
        }
        n = size(t.args) < size(ed.params) ? size(t.args) : size(ed.params);
        // [a..b] in Rascal is half-open (exclusive of b), like Python's
        // range(): [0..n] gives indices 0..n-1, and is already empty for
        // n == 0, so no special-casing is needed.
        for (i <- [0..n]) {
          pname = t.args[i];
          env[pname] = toCType(ed.params[i].tp);
          paramNames += {pname};
        }
      }

      if (size(t.guard) == 1) {
        <guardType, guardMsgs> = typeOfExpr(t.guard[0], env);
        msgs += guardMsgs;
        if (guardType != cErr() && guardType != cBool()) {
          msgs += error("Guard must be bool, got <showType(guardType)>", t.guard[0].src);
        }
      }

      msgs += checkStats(t.actions, varTypes, env, paramNames);
    }

    for (ev <- byEvent, size(byEvent[ev]) > 1, any(tt <- byEvent[ev], size(tt.guard) == 0)) {
      for (tt <- byEvent[ev]) {
        msgs += error("Transitions on event \'<ev>\' from state \'<s.name>\' are not (conservatively) deterministic: an unguarded transition coexists with another", tt.src);
      }
    }
  }

  return msgs;
}

// Assignment targets must be declared variables, never event parameters
// (paramNames is only used to give a clearer message in that case).
set[Message] checkStats(list[AStat] stats, map[str, AType] varTypes, Env env, set[str] paramNames) {
  set[Message] msgs = {};
  for (st <- stats) {
    if (st.var in varTypes) {
      <t, m2> = typeOfExpr(st.expr, env);
      msgs += m2;
      declared = toCType(varTypes[st.var]);
      if (t != cErr() && t != declared) {
        msgs += error("Cannot assign <showType(t)> to \'<st.var>\' of type <showType(declared)>", st.src);
      }
    } else if (st.var in paramNames) {
      msgs += error("Cannot assign to event parameter \'<st.var>\'; only declared variables can be assigned", st.src);
    } else {
      msgs += error("Undefined variable \'<st.var>\' (assignment target)", st.src);
    }
  }
  return msgs;
}

tuple[CType, set[Message]] typeOfExpr(AExpr e, Env env) {
  switch (e) {
    case intLit(_): return <cInt(), {}>;
    case trueLit(): return <cBool(), {}>;
    case falseLit(): return <cBool(), {}>;
    case ref(str n): {
      if (n in env) return <env[n], {}>;
      return <cErr(), {error("Undefined reference \'<n>\'", e.src)}>;
    }
    case not(AExpr e1): {
      <t1, m1> = typeOfExpr(e1, env);
      if (t1 == cErr()) return <cErr(), m1>;
      if (t1 != cBool()) return <cErr(), m1 + error("Operator \'!\' expects bool, got <showType(t1)>", e.src)>;
      return <cBool(), m1>;
    }
    case neg(AExpr e1): {
      <t1, m1> = typeOfExpr(e1, env);
      if (t1 == cErr()) return <cErr(), m1>;
      if (t1 != cInt()) return <cErr(), m1 + error("Unary \'-\' expects int, got <showType(t1)>", e.src)>;
      return <cInt(), m1>;
    }
    case mul(AExpr l, AExpr r): return arith(e, l, r, env, "*");
    case div(AExpr l, AExpr r): return arith(e, l, r, env, "/");
    case add(AExpr l, AExpr r): return arith(e, l, r, env, "+");
    case sub(AExpr l, AExpr r): return arith(e, l, r, env, "-");
    case lt(AExpr l, AExpr r): return cmp(e, l, r, env, "\<");
    case leq(AExpr l, AExpr r): return cmp(e, l, r, env, "\<=");
    case gt(AExpr l, AExpr r): return cmp(e, l, r, env, "\>");
    case geq(AExpr l, AExpr r): return cmp(e, l, r, env, "\>=");
    case eq(AExpr l, AExpr r): return eqop(e, l, r, env, "==");
    case neq(AExpr l, AExpr r): return eqop(e, l, r, env, "!=");
    case and(AExpr l, AExpr r): return boolop(e, l, r, env, "&&");
    case or(AExpr l, AExpr r): return boolop(e, l, r, env, "||");
  }
  throw "Unhandled AExpr: <e>";
}

tuple[CType, set[Message]] arith(AExpr e, AExpr l, AExpr r, Env env, str op) {
  <tl, ml> = typeOfExpr(l, env);
  <tr, mr> = typeOfExpr(r, env);
  set[Message] msgs = ml + mr;
  if (tl == cErr() || tr == cErr()) return <cErr(), msgs>;
  if (tl != cInt() || tr != cInt()) {
    return <cErr(), msgs + error("Operator \'<op>\' expects int operands, got <showType(tl)> and <showType(tr)>", e.src)>;
  }
  return <cInt(), msgs>;
}

tuple[CType, set[Message]] cmp(AExpr e, AExpr l, AExpr r, Env env, str op) {
  <tl, ml> = typeOfExpr(l, env);
  <tr, mr> = typeOfExpr(r, env);
  set[Message] msgs = ml + mr;
  if (tl == cErr() || tr == cErr()) return <cErr(), msgs>;
  if (tl != cInt() || tr != cInt()) {
    return <cErr(), msgs + error("Operator \'<op>\' expects int operands, got <showType(tl)> and <showType(tr)>", e.src)>;
  }
  return <cBool(), msgs>;
}

tuple[CType, set[Message]] eqop(AExpr e, AExpr l, AExpr r, Env env, str op) {
  <tl, ml> = typeOfExpr(l, env);
  <tr, mr> = typeOfExpr(r, env);
  set[Message] msgs = ml + mr;
  if (tl == cErr() || tr == cErr()) return <cErr(), msgs>;
  if (tl != tr) {
    return <cErr(), msgs + error("Operator \'<op>\' expects operands of the same type, got <showType(tl)> and <showType(tr)>", e.src)>;
  }
  return <cBool(), msgs>;
}

tuple[CType, set[Message]] boolop(AExpr e, AExpr l, AExpr r, Env env, str op) {
  <tl, ml> = typeOfExpr(l, env);
  <tr, mr> = typeOfExpr(r, env);
  set[Message] msgs = ml + mr;
  if (tl == cErr() || tr == cErr()) return <cErr(), msgs>;
  if (tl != cBool() || tr != cBool()) {
    return <cErr(), msgs + error("Operator \'<op>\' expects bool operands, got <showType(tl)> and <showType(tr)>", e.src)>;
  }
  return <cBool(), msgs>;
}
