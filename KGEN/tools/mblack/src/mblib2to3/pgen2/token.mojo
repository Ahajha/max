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
from std.python.bindings import PythonModuleBuilder, PyObjectPtr
from std.os import abort
from std.python._cpython import ExternalFunction
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


comptime PyModule_AddIntConstant = ExternalFunction[
    "PyModule_AddIntConstant",
    # int PyModule_AddIntConstant(PyObject *module, const char *name, long value)
    def(
        PyObjectPtr,
        OptionalPointer[c_char, ImmutAnyOrigin],
        c_long,
    ) thin abi("C") -> c_int,
]

comptime PyDict_SetItem = ExternalFunction[
    "PyDict_SetItem",
    # int PyDict_SetItem(PyObject *p, PyObject *key, PyObject *val)
    def(
        PyObjectPtr,
        PyObjectPtr,
        PyObjectPtr,
    ) thin abi("C") -> c_int,
]

comptime PyModule_Add = ExternalFunction[
    "PyModule_Add",
    # int PyModule_AddObject(PyObject *module, const char *name, PyObject *value)
    def(
        PyObjectPtr,
        OptionalPointer[c_char, ImmutAnyOrigin],
        PyObjectPtr,
    ) thin abi("C") -> c_int,
]

comptime PyLong_FromLong = ExternalFunction[
    "PyLong_FromLong",
    #  PyObject *PyLong_FromLong(long v)
    def(c_long) thin abi("C") -> PyObjectPtr,
]

comptime PyUnicode_FromString = ExternalFunction[
    "PyUnicode_FromString",
    # PyObject *PyUnicode_FromString(const char *str)
    def(OptionalPointer[c_char, ImmutAnyOrigin]) thin abi("C") -> PyObjectPtr,
]


@export
def PyInit_token() abi("C") -> PythonObject:
    try:
        var mb = PythonModuleBuilder("token")
        ref cpython = Python().cpython()
        var PyModule_AddIntConstant_call: PyModule_AddIntConstant.type = (
            PyModule_AddIntConstant.load(cpython.lib.borrow())
        )
        var PyDict_SetItem_call: PyDict_SetItem.type = PyDict_SetItem.load(
            cpython.lib.borrow()
        )
        var PyModule_Add_call: PyModule_Add.type = PyModule_Add.load(
            cpython.lib.borrow()
        )
        var PyLong_FromLong_call: PyLong_FromLong.type = PyLong_FromLong.load(
            cpython.lib.borrow()
        )
        var PyUnicode_FromString_call: PyUnicode_FromString.type = (
            PyUnicode_FromString.load(cpython.lib.borrow())
        )

        def add_int_constant(
            name: StaticString, value: c_long
        ) {mut mb, PyModule_AddIntConstant_call}:
            _ = PyModule_AddIntConstant_call(
                mb.module._obj_ptr,
                name.as_c_string_slice().ptr().as_unsafe_any_origin(),
                value,
            )

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

        set_tok_name("ENDMARKER", ENDMARKER)
        set_tok_name("NAME", NAME)
        set_tok_name("NUMBER", NUMBER)
        set_tok_name("STRING", STRING)
        set_tok_name("NEWLINE", NEWLINE)
        set_tok_name("INDENT", INDENT)
        set_tok_name("DEDENT", DEDENT)
        set_tok_name("LPAR", LPAR)
        set_tok_name("RPAR", RPAR)
        set_tok_name("LSQB", LSQB)
        set_tok_name("RSQB", RSQB)
        set_tok_name("COLON", COLON)
        set_tok_name("COMMA", COMMA)
        set_tok_name("SEMI", SEMI)
        set_tok_name("PLUS", PLUS)
        set_tok_name("MINUS", MINUS)
        set_tok_name("STAR", STAR)
        set_tok_name("SLASH", SLASH)
        set_tok_name("VBAR", VBAR)
        set_tok_name("AMPER", AMPER)
        set_tok_name("LESS", LESS)
        set_tok_name("GREATER", GREATER)
        set_tok_name("EQUAL", EQUAL)
        set_tok_name("DOT", DOT)
        set_tok_name("PERCENT", PERCENT)
        set_tok_name("BACKQUOTE", BACKQUOTE)
        set_tok_name("LBRACE", LBRACE)
        set_tok_name("RBRACE", RBRACE)
        set_tok_name("EQEQUAL", EQEQUAL)
        set_tok_name("NOTEQUAL", NOTEQUAL)
        set_tok_name("LESSEQUAL", LESSEQUAL)
        set_tok_name("GREATEREQUAL", GREATEREQUAL)
        set_tok_name("TILDE", TILDE)
        set_tok_name("CIRCUMFLEX", CIRCUMFLEX)
        set_tok_name("LEFTSHIFT", LEFTSHIFT)
        set_tok_name("RIGHTSHIFT", RIGHTSHIFT)
        set_tok_name("DOUBLESTAR", DOUBLESTAR)
        set_tok_name("PLUSEQUAL", PLUSEQUAL)
        set_tok_name("MINEQUAL", MINEQUAL)
        set_tok_name("STAREQUAL", STAREQUAL)
        set_tok_name("SLASHEQUAL", SLASHEQUAL)
        set_tok_name("PERCENTEQUAL", PERCENTEQUAL)
        set_tok_name("AMPEREQUAL", AMPEREQUAL)
        set_tok_name("VBAREQUAL", VBAREQUAL)
        set_tok_name("CIRCUMFLEXEQUAL", CIRCUMFLEXEQUAL)
        set_tok_name("LEFTSHIFTEQUAL", LEFTSHIFTEQUAL)
        set_tok_name("RIGHTSHIFTEQUAL", RIGHTSHIFTEQUAL)
        set_tok_name("DOUBLESTAREQUAL", DOUBLESTAREQUAL)
        set_tok_name("DOUBLESLASH", DOUBLESLASH)
        set_tok_name("DOUBLESLASHEQUAL", DOUBLESLASHEQUAL)
        set_tok_name("AT", AT)
        set_tok_name("ATEQUAL", ATEQUAL)
        set_tok_name("OP", OP)
        set_tok_name("COMMENT", COMMENT)
        set_tok_name("NL", NL)
        set_tok_name("RARROW", RARROW)
        set_tok_name("AWAIT", AWAIT)
        set_tok_name("ASYNC", ASYNC)
        set_tok_name("ERRORTOKEN", ERRORTOKEN)
        set_tok_name("COLONEQUAL", COLONEQUAL)
        set_tok_name("N_TOKENS", N_TOKENS)
        set_tok_name("STRUCT", STRUCT)
        set_tok_name("ALIAS", ALIAS)
        set_tok_name("REF", REF)
        set_tok_name("VAR", VAR)
        set_tok_name("MLIR_REGION", MLIR_REGION)
        set_tok_name("READ", READ)
        set_tok_name("MUT", MUT)
        set_tok_name("OUT", OUT)
        set_tok_name("TRAIT", TRAIT)
        set_tok_name("DEINIT", DEINIT)
        set_tok_name("WHERE", WHERE)
        set_tok_name("EXTENSION", EXTENSION)
        set_tok_name("COMPTIME", COMPTIME)
        set_tok_name("IMM", IMM)
        set_tok_name("GENERATOR_TYPE", GENERATOR_TYPE)
        set_tok_name("NT_OFFSET", NT_OFFSET)

        # No need to inc/decref, PyModule_Add steals a reference
        _ = PyModule_Add_call(
            mb.module._obj_ptr,
            "tok_name".as_c_string_slice().ptr().as_unsafe_any_origin(),
            tok_name,
        )

        return mb.finalize()
    except e:
        abort("error creating Mojo module")
