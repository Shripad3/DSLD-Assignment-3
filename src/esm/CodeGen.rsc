module esm::CodeGen

import esm::AST;
import List;
import IO;

// Python code generation. Assumes the AMachine has already passed
// esm::Check::check() with no errors (exactly one initial state, every
// transition's event/target/references resolved, etc.) - this module does
// not re-validate, it just renders.
//
// Transition order: guard check -> exit actions -> transition actions ->
// entry actions -> state change. Each event's handler tries its transitions
// in declaration order (state by state, then transition by transition
// within a state) and fires the first one whose owning state matches and
// whose guard holds.

str generatePython(AMachine m) {
  str out = "";
  out += genStateEnum(m);
  out += "class <m.name>:\n";
  out += genInit(m);
  out += "\n";
  for (s <- m.states) {
    out += genEnterExit(s);
  }
  out += genSend();
  for (ed <- m.events) {
    out += genEventHandler(m, ed) + "\n";
  }
  out += genDemoDriver(m);
  return out;
}

void generatePythonFile(AMachine m, loc target) {
  writeFile(target, generatePython(m));
}

str indentLines(list[str] lines, int level) {
  str pad = "";
  for (_ <- [0..level]) pad += "    ";
  str out = "";
  for (l <- lines) out += "<pad><l>\n";
  return out;
}

str genStateEnum(AMachine m) {
  str out = "from enum import Enum, auto\n\n\n";
  out += "class State(Enum):\n";
  for (s <- m.states) {
    out += "    <s.name> = auto()\n";
  }
  return out + "\n\n";
}

str genInit(AMachine m) {
  str out = "    def __init__(self):\n";
  for (v <- m.vars) {
    out += "        self.<v.name> = <renderExpr(v.init, {})>\n";
  }
  list[str] initNames = [s.name | s <- m.states, s.isInitial];
  str initState = initNames[0]; // Check.rsc guarantees exactly one
  out += "        self.state = State.<initState>\n";
  out += "        self._enter_<initState>()\n";
  return out;
}

str bodyLines(list[AStat] stats, set[str] paramNames) {
  if (size(stats) == 0) return "        pass\n";
  str out = "";
  for (st <- stats) {
    out += "        <renderStat(st, paramNames)>\n";
  }
  return out;
}

str genEnterExit(AState s) {
  str enter = "    def _enter_<s.name>(self):\n" + bodyLines(s.entryActions, {});
  str exit = "    def _exit_<s.name>(self):\n" + bodyLines(s.exitActions, {});
  return enter + "\n" + exit + "\n";
}

str genSend() {
  str out = "    def send(self, event, **kwargs):\n";
  out += "        handler = getattr(self, f\"_on_{event}\", None)\n";
  out += "        if handler is None:\n";
  out += "            print(f\"Unknown event: {event}\")\n";
  out += "            return False\n";
  out += "        return handler(**kwargs)\n";
  return out + "\n";
}

str genEventHandler(AMachine m, AEventDecl ed) {
  list[str] declNames = ["<p.name>" | p <- ed.params];
  str sigParams = size(declNames) == 0 ? "" : (", " + intercalate(", ", declNames));
  str out = "    def _on_<ed.name>(self<sigParams>):\n";

  list[tuple[AState s, ATransition t]] matches =
    [<s, t> | s <- m.states, t <- s.transitions, t.event == ed.name];

  if (size(matches) == 0) {
    return out + "        return False\n";
  }

  for (<s, t> <- matches) {
    set[str] paramNames = {a | a <- t.args};
    out += "        if self.state == State.<s.name>:\n";
    for (i <- [0..size(t.args)]) {
      localName = t.args[i];
      declared = declNames[i]; // arity already validated by Check.rsc
      out += "            <localName> = <declared>\n";
    }
    str guardExpr = size(t.guard) == 1 ? renderExpr(t.guard[0], paramNames) : "True";
    out += "            if <guardExpr>:\n";
    out += "                self._exit_<s.name>()\n";
    for (st <- t.actions) {
      out += "                <renderStat(st, paramNames)>\n";
    }
    out += "                self._enter_<t.target>()\n";
    out += "                self.state = State.<t.target>\n";
    out += "                return True\n";
  }
  out += "        return False\n";
  return out;
}

str renderStat(AStat s, set[str] paramNames) = "self.<s.var> = <renderExpr(s.expr, paramNames)>";

str renderExpr(AExpr e, set[str] paramNames) {
  switch (e) {
    case intLit(int i): return "<i>";
    case trueLit(): return "True";
    case falseLit(): return "False";
    case ref(str n): return (n in paramNames) ? n : "self.<n>";
    case not(AExpr e1): return "(not <renderExpr(e1, paramNames)>)";
    case neg(AExpr e1): return "(-<renderExpr(e1, paramNames)>)";
    case mul(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> * <renderExpr(r, paramNames)>)";
    case div(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> // <renderExpr(r, paramNames)>)";
    case add(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> + <renderExpr(r, paramNames)>)";
    case sub(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> - <renderExpr(r, paramNames)>)";
    case lt(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> \< <renderExpr(r, paramNames)>)";
    case leq(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> \<= <renderExpr(r, paramNames)>)";
    case gt(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> \> <renderExpr(r, paramNames)>)";
    case geq(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> \>= <renderExpr(r, paramNames)>)";
    case eq(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> == <renderExpr(r, paramNames)>)";
    case neq(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> != <renderExpr(r, paramNames)>)";
    case and(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> and <renderExpr(r, paramNames)>)";
    case or(AExpr l, AExpr r): return "(<renderExpr(l, paramNames)> or <renderExpr(r, paramNames)>)";
  }
  throw "Unhandled AExpr in CodeGen: <e>";
}

str defaultArgLiteral(AType tp) = (tp == intType()) ? "50" : "True";

str dictLiteralBody(list[str] names) = intercalate(", ", ["\'<n>\': m.<n>" | n <- names]);

// Builds the vars dict in a temporary first, then references only the bare
// name inside the f-string substitution. Embedding the dict literal's ":"
// directly inside an f-string {...} field misparses as a format spec
// (e.g. "{x:.2f}"), not as a colon belonging to a dict literal.
str printLine(str label, list[str] names) {
  str dictExpr = "{" + dictLiteralBody(names) + "}";
  return "    _v = <dictExpr>\n    print(f\"<label>: state={m.state.name} vars={_v}\")\n";
}

str genDemoDriver(AMachine m) {
  list[str] fieldNames = ["<v.name>" | v <- m.vars];
  str out = "\nif __name__ == \"__main__\":\n";
  out += "    m = <m.name>()\n";
  out += printLine("start", fieldNames);

  for (_ <- [0..3]) {
    for (ed <- m.events) {
      list[str] argParts = ["<p.name>=<defaultArgLiteral(p.tp)>" | p <- ed.params];
      str callArgs = intercalate(", ", argParts);
      str sendArgs = size(argParts) == 0 ? "" : (", " + callArgs);
      out += "    m.send(\"<ed.name>\"<sendArgs>)\n";
      out += printLine("after <ed.name>", fieldNames);
    }
  }

  return out;
}
