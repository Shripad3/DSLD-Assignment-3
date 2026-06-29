module esm::Plugin

import esm::Parser;
import esm::CST2AST;
import esm::Check;
import esm::CodeGen;
import esm::AST;
import Message;
import IO;
import Set;
import List;

// Driver tying the whole pipeline together: parse -> CST2AST -> static checks
// -> Python code generation. compileFile() is the single entry point used for
// both the demo and the video (show the .esm, run this, get a runnable .py).
//
// Open the Code/ folder (the one containing META-INF/RASCAL.MF) in VS Code so
// the project:// locations in main() resolve.

// Severity tag for one diagnostic.
str severity(Message msg) = msg is error ? "ERROR" : (msg is warning ? "WARN " : "INFO ");

// Pretty-print one diagnostic with its source location.
str showMessage(Message msg) = "<severity(msg)> <msg.at>: <msg.msg>";

// Parse + check a single .esm file and print all diagnostics. Returns the set
// of messages so callers can decide whether to proceed to code generation.
set[Message] checkFile(loc src) {
  println("=== Checking <src.file> ===");
  AMachine m = cst2ast(parseMachine(src));
  msgs = check(m);
  if (isEmpty(msgs)) {
    println("  (no problems found)");
  } else {
    for (msg <- msgs) {
      println("  <showMessage(msg)>");
    }
  }
  return msgs;
}

// Full pipeline for one file. Generates the .py next to the source (same name,
// .py extension) only when there are no errors; warnings do not block.
// Returns true when code was generated.
bool compileFile(loc src) {
  msgs = checkFile(src);
  errors = {msg | msg <- msgs, msg is error};
  if (!isEmpty(errors)) {
    println("  -\> <size(errors)> error(s); skipping code generation.");
    return false;
  }
  AMachine m = cst2ast(parseMachine(src));
  loc target = src[extension="py"];
  generatePythonFile(m, target);
  println("  -\> generated <target.file>");
  return true;
}

// Compile every realistic example into Python, and run the checker over the
// deliberately broken machine to demonstrate the static semantics.
void main() {
  examples = [
    |project://esm/examples/vending.esm|,
    |project://esm/examples/trafficlight.esm|,
    |project://esm/examples/elevator.esm|
  ];
  for (ex <- examples) {
    compileFile(ex);
    println("");
  }

  println("### Static-semantics demo (errors below are intentional) ###");
  checkFile(|project://esm/examples/broken.esm|);
}
