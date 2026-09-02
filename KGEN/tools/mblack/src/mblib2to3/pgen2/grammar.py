# ===----------------------------------------------------------------------=== #
# Copyright (c) 2026, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
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

# Python imports
from typing import TypeVar

# Local imports
from . import token

_P = TypeVar("_P", bound="Grammar")
Label = tuple[int, str | None]
DFA = list[list[tuple[int, int]]]
DFAS = tuple[DFA, dict[int, int]]
Path = str


class Grammar:
    """Pgen parsing tables conversion class.

    Once initialized, this class supplies the grammar tables for the
    parsing engine implemented by parse.py.  The parsing engine
    accesses the instance variables directly.  The class here does not
    provide initialization of the tables; several subclasses exist to
    do this (see the conv and pgen modules).

    The load() method reads the tables from a pickle file, which is
    much faster than the other ways offered by subclasses.  The pickle
    file is written by calling dump() (after loading the grammar
    tables using a subclass).  The report() method prints a readable
    representation of the tables to stdout, for debugging.

    The instance variables are as follows:

    symbol2number -- a dict mapping symbol names to numbers.  Symbol
                     numbers are always 256 or higher, to distinguish
                     them from token numbers, which are between 0 and
                     255 (inclusive).

    number2symbol -- a dict mapping numbers to symbol names;
                     these two are each other's inverse.

    states        -- a list of DFAs, where each DFA is a list of
                     states, each state is a list of arcs, and each
                     arc is a (i, j) pair where i is a label and j is
                     a state number.  The DFA number is the index into
                     this list.  (This name is slightly confusing.)
                     Final states are represented by a special arc of
                     the form (0, j) where j is its own state number.

    dfas          -- a dict mapping symbol numbers to (DFA, first)
                     pairs, where DFA is an item from the states list
                     above, and first is a set of tokens that can
                     begin this grammar rule (represented by a dict
                     whose values are always 1).

    labels        -- a list of (x, y) pairs where x is either a token
                     number or a symbol number, and y is either None
                     or a string; the strings are keywords.  The label
                     number is the index in this list; label numbers
                     are used to mark state transitions (arcs) in the
                     DFAs.

    start         -- the number of the grammar's start symbol.

    keywords      -- a dict mapping keyword strings to arc labels.

    tokens        -- a dict mapping token numbers to arc labels.

    """

    def __init__(self) -> None:
        self.symbol2number: dict[str, int] = {}
        self.number2symbol: dict[int, str] = {}
        self.states: list[DFA] = []
        self.dfas: dict[int, DFAS] = {}
        self.labels: list[Label] = [(0, "EMPTY")]
        self.keywords: dict[str, int] = {}
        self.soft_keywords: dict[str, int] = {}
        self.tokens: dict[int, int] = {}
        self.symbol2label: dict[str, int] = {}
        self.version: tuple[int, int] = (0, 0)
        self.start = 256
        # Python 3.7+ parses async as a keyword, not an identifier
        self.async_keywords = False
        # Mojo parses several identifiers, such as var/struct/etc., as keywords, not an identifier.
        self.mojo_keywords = False
        # Keywords that introduce a named declaration that can use a keyword
        # as a name, e.g. `def struct()`.
        self.declaration_keywords: list[str] = []

    def copy(self: _P) -> _P:
        """
        Copy the grammar.
        """
        new = self.__class__()
        for dict_attr in (
            "symbol2number",
            "number2symbol",
            "dfas",
            "keywords",
            "soft_keywords",
            "tokens",
            "symbol2label",
        ):
            setattr(new, dict_attr, getattr(self, dict_attr).copy())
        new.labels = self.labels[:]
        new.states = self.states[:]
        new.start = self.start
        new.version = self.version
        new.async_keywords = self.async_keywords
        new.mojo_keywords = self.mojo_keywords
        new.declaration_keywords = self.declaration_keywords
        return new


# Map from operator to number (since tokenize doesn't do this)

opmap = {
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
