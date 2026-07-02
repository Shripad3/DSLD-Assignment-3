module esm::Syntax

// ---------------------------------------------------------------------------
// Layout and lexicals
// ---------------------------------------------------------------------------

layout Layout = WhitespaceOrComment* !>> [\ \t\n\r];

lexical WhitespaceOrComment = Whitespace | Comment;
lexical Whitespace = [\ \t\n\r];
lexical Comment = "//" ![\n]*;

// Reserved words cannot be used as identifiers.
keyword Keywords
  = "machine" | "var" | "int" | "bool" | "event" | "state" | "initial" | "final"
  | "entry" | "exit" | "on" | "when" | "do" | "true" | "false"
  ;

lexical Name = ([a-zA-Z][a-zA-Z0-9_]*) \ Keywords;

lexical IntLit = [0-9]+;

// ---------------------------------------------------------------------------
// Top level: a machine is a name plus a list of declarations
// ---------------------------------------------------------------------------

start syntax Machine = machine: "machine" Name name "{" Decl* decls "}";

syntax Decl
  = declVar: VarDecl vardecl
  | declEvent: EventDecl eventdecl
  | declState: StateDecl statedecl
  ;

// ---------------------------------------------------------------------------
// Typed variables (extended state)
// ---------------------------------------------------------------------------

syntax VarDecl = varDecl: "var" Name name ":" Type tp "=" Literal init;

syntax Type = tyInt: "int" | tyBool: "bool";

syntax Literal = litInt: IntLit intLit | litTrue: "true" | litFalse: "false";

// ---------------------------------------------------------------------------
// Parameterized events
// ---------------------------------------------------------------------------

syntax EventDecl = eventDecl: "event" Name name "(" {Param ","}* params ")";

syntax Param = param: Name name ":" Type tp;

// ---------------------------------------------------------------------------
// States: entry/exit actions and outgoing transitions
// ---------------------------------------------------------------------------

syntax StateDecl = stateDecl: "state" Name name Modifier* mods "{" StateBody* body "}";

syntax Modifier = modInitial: "initial" | modFinal: "final";

syntax StateBody
  = bodyEntry: EntryAction entryAction
  | bodyExit: ExitAction exitAction
  | bodyTrans: Transition transition
  ;

syntax EntryAction = entryAction: "entry" Block block;

syntax ExitAction = exitAction: "exit" Block block;

// "when" guard and "do" action block are both optional. The guard is just an
// Expr now; the type checker (later) rejects non-bool guards.
syntax Transition = transition: "on" EventRef evt ("when" Expr guard)? "-\>" Name target ("do" Block block)?;

// An event reference re-binds the event's declared parameter names so they
// can be used inside the guard/action of this transition, e.g. coin(value).
// Arity/type matching against the EventDecl is deferred to the checker.
syntax EventRef = eventRef: Name name "(" {Name ","}* args ")";

// ---------------------------------------------------------------------------
// Action statements: assignment only, sequenced with ";"
// ---------------------------------------------------------------------------

syntax Block = block: "{" Stat* stats "}";

syntax Stat = assign: Name name ":=" Expr expr ";";

// ---------------------------------------------------------------------------
// Unified expression grammar: booleans, comparisons and arithmetic all live
// in one Expr type. The type checker enforces that guards are bool and that
// assignment RHS matches the variable's declared type.
//
// Precedence, high (tightest) to low (loosest):
//   atoms  >  !  >  unary-  >  * /  >  + -  >  comparisons (non-assoc)
//          >  == != (non-assoc)  >  && (left)  >  || (left)
// Binary + and - sit between * / and the comparisons, the conventional
// placement, since vending.esm needs them (e.g. "balance + value",
// "(balance - price) / 5").
// ---------------------------------------------------------------------------

syntax Expr
  = bracket "(" Expr e ")"
  | intLit: IntLit i
  | trueLit: "true"
  | falseLit: "false"
  | var: Name n
  > not: "!" Expr e
  > neg: "-" Expr e
  > left ( mul: Expr l "*" Expr r | div: Expr l "/" Expr r )
  > left ( add: Expr l "+" Expr r | sub: Expr l "-" Expr r )
  > non-assoc ( lt: Expr l "\<" Expr r | leq: Expr l "\<=" Expr r | gt: Expr l "\>" Expr r | geq: Expr l "\>=" Expr r )
  > non-assoc ( eq: Expr l "==" Expr r | neq: Expr l "!=" Expr r )
  > left and: Expr l "&&" Expr r
  > left or: Expr l "||" Expr r
  ;
