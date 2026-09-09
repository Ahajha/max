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

comptime tok_name: Dict[Int, StaticString] = {
    ENDMARKER: "ENDMARKER",
    NAME: "NAME",
    NUMBER: "NUMBER",
    STRING: "STRING",
    NEWLINE: "NEWLINE",
    INDENT: "INDENT",
    DEDENT: "DEDENT",
    LPAR: "LPAR",
    RPAR: "RPAR",
    LSQB: "LSQB",
    RSQB: "RSQB",
    COLON: "COLON",
    COMMA: "COMMA",
    SEMI: "SEMI",
    PLUS: "PLUS",
    MINUS: "MINUS",
    STAR: "STAR",
    SLASH: "SLASH",
    VBAR: "VBAR",
    AMPER: "AMPER",
    LESS: "LESS",
    GREATER: "GREATER",
    EQUAL: "EQUAL",
    DOT: "DOT",
    PERCENT: "PERCENT",
    BACKQUOTE: "BACKQUOTE",
    LBRACE: "LBRACE",
    RBRACE: "RBRACE",
    EQEQUAL: "EQEQUAL",
    NOTEQUAL: "NOTEQUAL",
    LESSEQUAL: "LESSEQUAL",
    GREATEREQUAL: "GREATEREQUAL",
    TILDE: "TILDE",
    CIRCUMFLEX: "CIRCUMFLEX",
    LEFTSHIFT: "LEFTSHIFT",
    RIGHTSHIFT: "RIGHTSHIFT",
    DOUBLESTAR: "DOUBLESTAR",
    PLUSEQUAL: "PLUSEQUAL",
    MINEQUAL: "MINEQUAL",
    STAREQUAL: "STAREQUAL",
    SLASHEQUAL: "SLASHEQUAL",
    PERCENTEQUAL: "PERCENTEQUAL",
    AMPEREQUAL: "AMPEREQUAL",
    VBAREQUAL: "VBAREQUAL",
    CIRCUMFLEXEQUAL: "CIRCUMFLEXEQUAL",
    LEFTSHIFTEQUAL: "LEFTSHIFTEQUAL",
    RIGHTSHIFTEQUAL: "RIGHTSHIFTEQUAL",
    DOUBLESTAREQUAL: "DOUBLESTAREQUAL",
    DOUBLESLASH: "DOUBLESLASH",
    DOUBLESLASHEQUAL: "DOUBLESLASHEQUAL",
    AT: "AT",
    ATEQUAL: "ATEQUAL",
    OP: "OP",
    COMMENT: "COMMENT",
    NL: "NL",
    RARROW: "RARROW",
    AWAIT: "AWAIT",
    ASYNC: "ASYNC",
    ERRORTOKEN: "ERRORTOKEN",
    COLONEQUAL: "COLONEQUAL",
    N_TOKENS: "N_TOKENS",
    STRUCT: "STRUCT",
    ALIAS: "ALIAS",
    REF: "REF",
    VAR: "VAR",
    MLIR_REGION: "MLIR_REGION",
    READ: "READ",
    MUT: "MUT",
    OUT: "OUT",
    TRAIT: "TRAIT",
    DEINIT: "DEINIT",
    WHERE: "WHERE",
    EXTENSION: "EXTENSION",
    COMPTIME: "COMPTIME",
    IMM: "IMM",
    GENERATOR_TYPE: "GENERATOR_TYPE",
    NT_OFFSET: "NT_OFFSET",
}


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
            name: StaticString, value: Int
        ) {mut mb, PyModule_AddIntConstant_call}:
            _ = PyModule_AddIntConstant_call(
                mb.module._obj_ptr,
                name.as_c_string_slice().ptr().as_unsafe_any_origin(),
                c_long(value),
            )

        var tok_name_py = cpython.PyDict_New()

        def set_tok_name(
            name: StaticString, key: Int
        ) {
            mut tok_name_py,
            cpython,
            PyDict_SetItem_call,
            PyLong_FromLong_call,
            PyUnicode_FromString_call,
        }:
            var key_obj = PyLong_FromLong_call(c_long(key))
            var value_obj = PyUnicode_FromString_call(
                name.as_c_string_slice().ptr().as_unsafe_any_origin()
            )
            _ = PyDict_SetItem_call(
                tok_name_py,
                key_obj,
                value_obj,
            )
            # PyDict_SetItem does _not_ steal a reference to val, so we must decref here.
            # I'm not sure if it steals a reference to key.
            cpython.Py_DecRef(value_obj)

        for pair in materialize[tok_name]().items():
            add_int_constant(pair.value, pair.key)
            set_tok_name(pair.value, pair.key)

        # No need to inc/decref, PyModule_Add steals a reference
        _ = PyModule_Add_call(
            mb.module._obj_ptr,
            "tok_name".as_c_string_slice().ptr().as_unsafe_any_origin(),
            tok_name_py,
        )

        return mb.finalize()
    except e:
        abort("error creating Mojo module")
