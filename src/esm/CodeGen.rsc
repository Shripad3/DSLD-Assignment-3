module esm::CodeGen

import esm::AST;

// Python code generation via string templates. Will emit a class with
// state/var fields, a send(event, **params) dispatch method, and a small
// demo driver at the bottom of the generated file.
