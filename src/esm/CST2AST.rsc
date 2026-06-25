module esm::CST2AST

import esm::Syntax;
import esm::AST;

// Concrete-to-abstract mapping.
// Needs explicit cases per nonterminal rather than a blind implode(): the
// Expr precedence layering means the parse tree shape doesn't match the
// flat AST shape we want for the checker and code generator.
