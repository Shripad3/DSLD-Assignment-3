module esm::Parser

import ParseTree;
import esm::Syntax;

start[Machine] parseMachine(loc l) = parse(#start[Machine], l);
