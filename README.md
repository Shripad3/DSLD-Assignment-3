# Extended State Machine (ESM) — 2IMP20 DSL Design, Assignment 3

An executable **extended state-machine / statechart DSL**, implemented in **Rascal**
and compiling to executable **Python**.

## Folder layout

```
.
├── esm/                     Rascal project — OPEN THIS FOLDER IN VS CODE
│   ├── src/esm/             language implementation (.rsc)
│   │   ├── Syntax.rsc       concrete syntax (grammar): machine, states, events,
│   │   │                    guarded transitions, entry/exit + transition actions,
│   │   │                    typed variables, full expression grammar
│   │   ├── AST.rsc          abstract syntax (A-prefixed algebraic data types)
│   │   ├── CST2AST.rsc      manual CST → AST mapping (no implode)
│   │   ├── Check.rsc        static semantics (well-formedness checker)
│   │   ├── CodeGen.rsc      code generator: AST → Python
│   │   ├── Parser.rsc       thin parse wrapper
│   │   └── Plugin.rsc       pipeline driver: checkFile / compileFile / main
│   ├── examples/            non-trivial input programs + generated output
│   │   ├── vending.esm      → vending.py
│   │   ├── trafficlight.esm → trafficlight.py
│   │   ├── elevator.esm     → elevator.py
│   │   └── broken.esm       deliberately invalid — exercises every static check
│   ├── META-INF/RASCAL.MF   Rascal project manifest
│   └── pom.xml              Maven / Rascal dependency + build config
├──    
└── video/                   demo video (added before submission)
```

## Running it

**In VS Code** (Rascal extension): open the **`esm/`** folder, then in the REPL:

```rascal
import esm::Plugin;
main();          // checks + compiles all examples, runs the broken.esm check demo
```

Individual actions:

```rascal
checkFile(|cwd:///examples/vending.esm|);      // parse → CST2AST → check, print diagnostics
compileFile(|cwd:///examples/vending.esm|);    // generate .py (only if no errors)
```

**Headless** (from inside `esm/`):

```
printf 'import esm::Plugin;\nmain();\n:quit\n' | java -jar <rascal.jar>
```

`main()` uses `cwd:///examples/...` so it is independent of the folder name.

## Running the generated code

```
python3 examples/vending.py
```

Each generated Python file is a self-contained state-machine class with a demo driver
(no external dependencies).
