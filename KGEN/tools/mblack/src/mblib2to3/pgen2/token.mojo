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
#   Path:   src/mblib2to3/pgen2/token.py
#
# ===----------------------------------------------------------------------=== #

"""Token constants (from "token.h")."""

from std.python import PythonObject, Python
from std.python.bindings import PythonModuleBuilder
from std.os import abort
from std.python._cpython import ExternalFunction, PyObjectPtr
from std.ffi import c_char, c_long, c_int

#  Taken from Python (r53757) and modified to include some tokens
#   originally monkeypatched in by pgen2.tokenize

# --start constants--
comptime ENDMARKER = 0
comptime NAME = 1
comptime NUMBER = 2
comptime STRING = 3
comptime NEWLINE = 4
comptime INDENT = 5
comptime DEDENT = 6
comptime LPAR = 7
comptime RPAR = 8
comptime LSQB = 9
comptime RSQB = 10
comptime COLON = 11
comptime COMMA = 12
comptime SEMI = 13
comptime PLUS = 14
comptime MINUS = 15
comptime STAR = 16
comptime SLASH = 17
comptime VBAR = 18
comptime AMPER = 19
comptime LESS = 20
comptime GREATER = 21
comptime EQUAL = 22
comptime DOT = 23
comptime PERCENT = 24
comptime BACKQUOTE = 25
comptime LBRACE = 26
comptime RBRACE = 27
comptime EQEQUAL = 28
comptime NOTEQUAL = 29
comptime LESSEQUAL = 30
comptime GREATEREQUAL = 31
comptime TILDE = 32
comptime CIRCUMFLEX = 33
comptime LEFTSHIFT = 34
comptime RIGHTSHIFT = 35
comptime DOUBLESTAR = 36
comptime PLUSEQUAL = 37
comptime MINEQUAL = 38
comptime STAREQUAL = 39
comptime SLASHEQUAL = 40
comptime PERCENTEQUAL = 41
comptime AMPEREQUAL = 42
comptime VBAREQUAL = 43
comptime CIRCUMFLEXEQUAL = 44
comptime LEFTSHIFTEQUAL = 45
comptime RIGHTSHIFTEQUAL = 46
comptime DOUBLESTAREQUAL = 47
comptime DOUBLESLASH = 48
comptime DOUBLESLASHEQUAL = 49
comptime AT = 50
comptime ATEQUAL = 51
comptime OP = 52
comptime COMMENT = 53
comptime NL = 54
comptime RARROW = 55
comptime AWAIT = 56
comptime ASYNC = 57
comptime ERRORTOKEN = 58
comptime COLONEQUAL = 59
comptime N_TOKENS = 60

# Mojo constants
# 61 was FN, removed
comptime STRUCT = 62
comptime ALIAS = 63
comptime REF = 64
comptime VAR = 65
comptime MLIR_REGION = 66
# 67 was OWNED, removed
comptime READ = 68
comptime MUT = 69
comptime OUT = 70
comptime TRAIT = 71
comptime DEINIT = 72
# 73 was UNIFIED, removed
comptime WHERE = 74
comptime EXTENSION = 75
comptime COMPTIME = 76
comptime IMM = 77
comptime GENERATOR_TYPE = 78
comptime NT_OFFSET = 256
# --end constants--

# tok_name[dict[int, str]] = {}
# for _name, _value in list(globals().items()):
#     if type(_value) is int:
#         tok_name[_value] = _name

comptime PyModule_AddIntConstant = ExternalFunction[
    "PyModule_AddIntConstant",
    # int PyModule_AddIntConstant(PyObject *module, const char *name, long value)
    def(
        PyObjectPtr, OptionalPointer[c_char, ImmutAnyOrigin], c_long,
    ) thin abi("C") -> c_int,
]


@export
def PyInit_token() abi("C") -> PythonObject:
    try:
        var mb = PythonModuleBuilder("token")
        ref cpython = Python().cpython()
        var PyModule_AddIntConstant_call: PyModule_AddIntConstant.type = PyModule_AddIntConstant.load(cpython.lib.borrow())
        def add_int_constant(name: StaticString, value: c_long) {mut mb, mut PyModule_AddIntConstant_call}:
            _ = PyModule_AddIntConstant_call(mb.module._obj_ptr, name.as_c_string_slice().ptr().as_unsafe_any_origin(), value)


        add_int_constant("ENDMARKER", ENDMARKER)
        add_int_constant("NAME", NAME)
        add_int_constant("NUMBER", NUMBER)
        add_int_constant("STRING", STRING)
        add_int_constant("NEWLINE", NEWLINE)
        add_int_constant("INDENT", INDENT)
        add_int_constant("DEDENT", DEDENT)
        add_int_constant("LPAR", LPAR)
        add_int_constant("RPAR", RPAR)
        add_int_constant("LSQB", LSQB)
        add_int_constant("RSQB", RSQB)
        add_int_constant("COLON", COLON)
        add_int_constant("COMMA", COMMA)
        add_int_constant("SEMI", SEMI)
        add_int_constant("PLUS", PLUS)
        add_int_constant("MINUS", MINUS)
        add_int_constant("STAR", STAR)
        add_int_constant("SLASH", SLASH)
        add_int_constant("VBAR", VBAR)
        add_int_constant("AMPER", AMPER)
        add_int_constant("LESS", LESS)
        add_int_constant("GREATER", GREATER)
        add_int_constant("EQUAL", EQUAL)
        add_int_constant("DOT", DOT)
        add_int_constant("PERCENT", PERCENT)
        add_int_constant("BACKQUOTE", BACKQUOTE)
        add_int_constant("LBRACE", LBRACE)
        add_int_constant("RBRACE", RBRACE)
        add_int_constant("EQEQUAL", EQEQUAL)
        add_int_constant("NOTEQUAL", NOTEQUAL)
        add_int_constant("LESSEQUAL", LESSEQUAL)
        add_int_constant("GREATEREQUAL", GREATEREQUAL)
        add_int_constant("TILDE", TILDE)
        add_int_constant("CIRCUMFLEX", CIRCUMFLEX)
        add_int_constant("LEFTSHIFT", LEFTSHIFT)
        add_int_constant("RIGHTSHIFT", RIGHTSHIFT)
        add_int_constant("DOUBLESTAR", DOUBLESTAR)
        add_int_constant("PLUSEQUAL", PLUSEQUAL)
        add_int_constant("MINEQUAL", MINEQUAL)
        add_int_constant("STAREQUAL", STAREQUAL)
        add_int_constant("SLASHEQUAL", SLASHEQUAL)
        add_int_constant("PERCENTEQUAL", PERCENTEQUAL)
        add_int_constant("AMPEREQUAL", AMPEREQUAL)
        add_int_constant("VBAREQUAL", VBAREQUAL)
        add_int_constant("CIRCUMFLEXEQUAL", CIRCUMFLEXEQUAL)
        add_int_constant("LEFTSHIFTEQUAL", LEFTSHIFTEQUAL)
        add_int_constant("RIGHTSHIFTEQUAL", RIGHTSHIFTEQUAL)
        add_int_constant("DOUBLESTAREQUAL", DOUBLESTAREQUAL)
        add_int_constant("DOUBLESLASH", DOUBLESLASH)
        add_int_constant("DOUBLESLASHEQUAL", DOUBLESLASHEQUAL)
        add_int_constant("AT", AT)
        add_int_constant("ATEQUAL", ATEQUAL)
        add_int_constant("OP", OP)
        add_int_constant("COMMENT", COMMENT)
        add_int_constant("NL", NL)
        add_int_constant("RARROW", RARROW)
        add_int_constant("AWAIT", AWAIT)
        add_int_constant("ASYNC", ASYNC)
        add_int_constant("ERRORTOKEN", ERRORTOKEN)
        add_int_constant("COLONEQUAL", COLONEQUAL)
        add_int_constant("N_TOKENS", N_TOKENS)
        add_int_constant("STRUCT", STRUCT)
        add_int_constant("ALIAS", ALIAS)
        add_int_constant("REF", REF)
        add_int_constant("VAR", VAR)
        add_int_constant("MLIR_REGION", MLIR_REGION)
        add_int_constant("READ", READ)
        add_int_constant("MUT", MUT)
        add_int_constant("OUT", OUT)
        add_int_constant("TRAIT", TRAIT)
        add_int_constant("DEINIT", DEINIT)
        add_int_constant("WHERE", WHERE)
        add_int_constant("EXTENSION", EXTENSION)
        add_int_constant("COMPTIME", COMPTIME)
        add_int_constant("IMM", IMM)
        add_int_constant("GENERATOR_TYPE", GENERATOR_TYPE)
        add_int_constant("NT_OFFSET", NT_OFFSET)

        # Progress! Now we need `tok_name`


        return mb.finalize()
    except e:
        abort("error creating Mojo module")
