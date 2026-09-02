# ===----------------------------------------------------------------------=== #
# Copyright (c) 2026, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# diStringibuted under the License is diStringibuted on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

# ===----------------------------------------------------------------------=== #
#
# File originates from:
#   Repo:   git@github.com:psf/black.git
#   Commit: d4a85643a465f5fae2113d07d22d021d4af4795a
#   Path:   src/mblib2to3/pgen2/grammar.py
#
# ===----------------------------------------------------------------------=== #

# Copyright 2004-2005 Elemental Security, Inc. All Rights Reserved.
# Licensed to PSF under a Contributor Agreement.

"""This module defines the data structures used to represent a grammar.

These are a bit arcane because they are derived from the data
structures used by Python's 'pgen' parser generator.

There's also a table here mapping operators to their names in the
token module; the Python tokenize module reports all operators as the
fallback token code OP, but the parser needs the actual token code.

"""

import token

from std.python import PythonObject, Python
from std.python.bindings import PythonModuleBuilder, PyObjectPtr
from std.os import abort
from std.python._cpython import ExternalFunction
from std.ffi import c_char, c_long, c_int

comptime Label = Tuple[Int, Optional[String]]
comptime DFA = List[List[Tuple[Int, Int]]]
comptime DFAS = Tuple[DFA, Dict[Int, Int]]
comptime Path = String


struct Grammar(Copyable, Defaultable, Writable):
    """Pgen parsing tables conversion class.

    Once initialized, this class supplies the grammar tables for the
    parsing engine implemented by parse.py.  The parsing engine
    accesses the instance variables directly.  The class here does not
    provide initialization of the tables; several subclasses exist to
    do this (see the conv and pgen modules).

    The load() method reads the tables from a pickle file, which is
    much faster than the other ways offered by subclasses.  The pickle
    file is written by calling dump() (after loading the grammar
    tables using a subclass).  The report() method prInts a readable
    representation of the tables to stdout, for debugging.

    The instance variables are as follows:

    symbol2number -- a Dict mapping symbol names to numbers.  Symbol
                     numbers are always 256 or higher, to distinguish
                     them from token numbers, which are between 0 and
                     255 (inclusive).

    number2symbol -- a Dict mapping numbers to symbol names;
                     these two are each other's inverse.

    states        -- a List of DFAs, where each DFA is a List of
                     states, each state is a List of arcs, and each
                     arc is a (i, j) pair where i is a label and j is
                     a state number.  The DFA number is the index Into
                     this List.  (This name is slightly confusing.)
                     Final states are represented by a special arc of
                     the form (0, j) where j is its own state number.

    dfas          -- a Dict mapping symbol numbers to (DFA, first)
                     pairs, where DFA is an item from the states List
                     above, and first is a set of tokens that can
                     begin this grammar rule (represented by a Dict
                     whose values are always 1).

    labels        -- a List of (x, y) pairs where x is either a token
                     number or a symbol number, and y is either None
                     or a Stringing; the Stringings are keywords.  The label
                     number is the index in this List; label numbers
                     are used to mark state transitions (arcs) in the
                     DFAs.

    start         -- the number of the grammar's start symbol.

    keywords      -- a Dict mapping keyword Stringings to arc labels.

    tokens        -- a Dict mapping token numbers to arc labels.

    """

    # These all have to be read-only once they get to Python... which might cause problems.
    # In the interim we may need to convert to a Python dict, modify, and convert back.
    # Gross.
    # Or, we could manually bind every operation people could ever need....
    # Also gross, but maybe doable.
    var symbol2number: Dict[String, Int]
    var number2symbol: Dict[Int, String]
    var states: List[DFA]
    var dfas: Dict[Int, DFAS]
    var labels: List[Label]
    var keywords: Dict[String, Int]
    var soft_keywords: Dict[String, Int]
    var tokens: Dict[Int, Int]
    var symbol2label: Dict[String, Int]
    var version: Tuple[Int, Int]
    var start: Int
    # Python 3.7+ parses async as a keyword, not an identifier
    var async_keywords: Bool
    # Keywords that Introduce a named declaration that can use a keyword
    # as a name, e.g. `def struct()`.
    var declaration_keywords: List[String]

    def __init__(out self):
        self.symbol2number = {}
        self.number2symbol = {}
        self.states = []
        self.dfas = {}
        self.labels = [Label(0, "EMPTY")]
        self.keywords = {}
        self.soft_keywords = {}
        self.tokens = {}
        self.symbol2label = {}
        self.version = (0, 0)
        self.start = 256
        # Python 3.7+ parses async as a keyword, not an identifier
        self.async_keywords = False
        # Keywords that Introduce a named declaration that can use a keyword
        # as a name, e.g. `def struct()`.
        self.declaration_keywords = []


# Map from operator to number (since tokenize doesn't do this)

comptime opmap = {
    "(": token.LPAR,
    ")": token.RPAR,
    "[": token.LSQB,
    "]": token.RSQB,
    ":": token.COLON,
    ",": token.COMMA,
    ";": token.SEMI,
    "+": token.PLUS,
    "-": token.MINUS,
    "*": token.STAR,
    "/": token.SLASH,
    "|": token.VBAR,
    "&": token.AMPER,
    "<": token.LESS,
    ">": token.GREATER,
    "=": token.EQUAL,
    ".": token.DOT,
    "%": token.PERCENT,
    "`": token.BACKQUOTE,
    "{": token.LBRACE,
    "}": token.RBRACE,
    "@": token.AT,
    "@=": token.ATEQUAL,
    "==": token.EQEQUAL,
    "!=": token.NOTEQUAL,
    "<>": token.NOTEQUAL,
    "<=": token.LESSEQUAL,
    ">=": token.GREATEREQUAL,
    "~": token.TILDE,
    "^": token.CIRCUMFLEX,
    "<<": token.LEFTSHIFT,
    ">>": token.RIGHTSHIFT,
    "**": token.DOUBLESTAR,
    "+=": token.PLUSEQUAL,
    "-=": token.MINEQUAL,
    "*=": token.STAREQUAL,
    "/=": token.SLASHEQUAL,
    "%=": token.PERCENTEQUAL,
    "&=": token.AMPEREQUAL,
    "|=": token.VBAREQUAL,
    "^=": token.CIRCUMFLEXEQUAL,
    "<<=": token.LEFTSHIFTEQUAL,
    ">>=": token.RIGHTSHIFTEQUAL,
    "**=": token.DOUBLESTAREQUAL,
    "//": token.DOUBLESLASH,
    "//=": token.DOUBLESLASHEQUAL,
    "->": token.RARROW,
    ":=": token.COLONEQUAL,
}


def clone_grammar(py_self: PythonObject) raises -> PythonObject:
    var clone: Grammar = py_self.downcast_value_ptr[Grammar]()[].copy()
    return PythonObject(alloc=clone^)


@export
def PyInit_grammar() abi("C") -> PythonObject:
    try:
        var mb = PythonModuleBuilder("token")
        ref cpython = Python().cpython()

        # Grammar
        ref grammar_type = (
            mb.add_type[Grammar]("Grammar")
            .def_init_defaultable[Grammar]()
            .def_method[clone_grammar]("copy")
        )

        var PyDict_SetItem_call: token.PyDict_SetItem.type = (
            token.PyDict_SetItem.load(cpython.lib.borrow())
        )
        var PyModule_Add_call: token.PyModule_Add.type = (
            token.PyModule_Add.load(cpython.lib.borrow())
        )
        var PyLong_FromLong_call: token.PyLong_FromLong.type = (
            token.PyLong_FromLong.load(cpython.lib.borrow())
        )
        var PyUnicode_FromString_call: token.PyUnicode_FromString.type = (
            token.PyUnicode_FromString.load(cpython.lib.borrow())
        )

        var tok_name = cpython.PyDict_New()

        def set_tok_name(
            name: StaticString, value: c_long
        ) {
            mut tok_name,
            cpython,
            PyDict_SetItem_call,
            PyLong_FromLong_call,
            PyUnicode_FromString_call,
        }:
            var key_obj = PyLong_FromLong_call(value)
            var value_obj = PyUnicode_FromString_call(
                name.as_c_string_slice().ptr().as_unsafe_any_origin()
            )
            _ = PyDict_SetItem_call(
                tok_name,
                key_obj,
                value_obj,
            )
            # PyDict_SetItem does _not_ steal a reference to val, so we must decref here.
            # I'm not sure if it steals a reference to key.
            cpython.Py_DecRef(value_obj)

        # No need to inc/decref, PyModule_Add steals a reference
        _ = PyModule_Add_call(
            mb.module._obj_ptr,
            "tok_name".as_c_string_slice().ptr().as_unsafe_any_origin(),
            tok_name,
        )

        return mb.finalize()
    except e:
        abort("error creating Mojo module")
