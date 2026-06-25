module esm::Check

import esm::AST;
import Message;

// Static semantic checks: exactly-one-initial, reachability, no-dead-ends,
// conservative determinism, undefined-reference checks, guard/action type
// checking. None of these are implemented yet.
set[Message] check(value ast) = {};
