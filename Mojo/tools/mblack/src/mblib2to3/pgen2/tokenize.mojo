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
#   Path:   src/mblib2to3/pgen2/tokenize.py
#
# ===----------------------------------------------------------------------=== #

# Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006 Python Software Foundation.
# All rights reserved.

# mypy: allow-untyped-defs, allow-untyped-calls

"""Tokenization help for Python programs.

generate_tokens(readline) is a generator that breaks a stream of
text into Python tokens.  It accepts a readline-like method which is called
repeatedly to get the next line of input (or "" for EOF).  It generates
5-tuples with these members:

    the token type (see token.py)
    the token (a string)
    the starting (row, column) indices of the token (a 2-tuple of ints)
    the ending (row, column) indices of the token (a 2-tuple of ints)
    the original line (string)

It is designed to match the working of the Python tokenizer exactly, except
that it produces COMMENT tokens for comments and gives type OP for all
operators

Older entry points
    tokenize_loop(readline, tokeneater)
    tokenize(readline, tokeneater=printtoken)
are the same, except instead of generating tokens, tokeneater is a callback
function to which the 5 fields described above are passed as 5 arguments,
each time a new token is found."""

# from collections.abc import Callable, Iterator
# from re import Pattern
# from typing import (
#    Final,
# )

from grammar import Grammar
from token import *

comptime __author__ = "Ka-Ping Yee <ping@lfw.org>"
comptime __credits__ = (
    "GvR, ESR, Tim Peters, Thomas Wouters, Fred Drake, Skip Montanaro"
)

import regex as re
from regex.comptime_regex import match_first, findall, Match

# import re
# from codecs import BOM_UTF8, lookup


from std.collections import Set
from std.utils import Variant

# __all__ = [x for x in dir(token) if x[0] != "_"] + [
#     "tokenize",
#     "generate_tokens",
#     "untokenize",
# ]
# del token

# Temporary compat aliases
comptime str = String
comptime bool = Bool
comptime int = Int
comptime tuple = Tuple
comptime bytes = List[Byte]
comptime list = List
# End aliases


# Mimic Python's `.startswith`, which takes an iterable.
def startswith[
    O1: Origin, O2: Origin, O3: Origin
](needles: Span[StringSlice[O1], O2], haystack: StringSlice[O3]) -> bool:
    for needle in needles:
        if haystack.startswith(needle):
            return True
    return False


def group(*choices: String) -> String:
    # return "(" + "|".join(choices) + ")"
    var result: String = "("
    var needs_bar = False
    for choice in choices:
        if needs_bar:
            result += "|"
        needs_bar = True
        result += choice
    result += ")"
    return result


def any(*choices: String) -> String:
    return group(*choices) + "*"


def maybe(*choices: String) -> String:
    return group(*choices) + "?"


def _combinations(*l: String) -> Set[String]:
    # return {x + y for x in l for y in l + ("",) if x.casefold() != y.casefold()}
    var l_and_empty: List = [item for item in l] + [""]
    return {
        x + y
        for x in l
        for y in l_and_empty
        # Swapping `.casefold()` for `lower()` since Mojo doesn't have the former
        if x.lower() != y.lower()
    }


comptime Whitespace = r"[ \f\t]*"
comptime Comment = r"#[^\r\n]*"
comptime Ignore = Whitespace + any(r"\\\r?\n" + Whitespace) + maybe(Comment)
comptime Name = (  # this is invalid but it's fine because Name comes after Number in all groups
    r"[^\s#\(\)\[\]\{\}+\-*/!@$%^&=|;:'\",\.<>/?~\\]+"
)

# Unlike Python, Mojo accepts trailing underscores in numeric literals (e.g.
# `2_000_000_`, `0xFF_`, `1.5_e3`). Each digit run therefore ends with a
# trailing `_*`. Underscores still may not lead a number, follow `.` or the
# exponent marker directly, or stand alone after a base prefix. The bare-zero
# decimal form likewise allows interior zeros/underscores (`00`, `0_0`), all of
# which Mojo reads as zero.
comptime Binnumber = r"0[bB]_*[01]+(?:_+[01]+)*_*"
comptime Hexnumber = r"0[xX]_*[\da-fA-F]+(?:_+[\da-fA-F]+)*_*[lL]?"
comptime Octnumber = r"0[oO]?_*[0-7]+(?:_+[0-7]+)*_*[lL]?"
comptime Decnumber = group(r"[1-9]\d*(?:_+\d+)*_*[lL]?", "0[0_]*[lL]?")
comptime Intnumber = group(Binnumber, Hexnumber, Octnumber, Decnumber)
comptime Exponent = r"[eE][-+]?\d+(?:_+\d+)*_*"
comptime Pointfloat = group(
    r"\d+(?:_+\d+)*_*\.(?:\d+(?:_+\d+)*_*)?", r"\.\d+(?:_+\d+)*_*"
) + maybe(Exponent)
comptime Expfloat = r"\d+(?:_+\d+)*_*" + Exponent
comptime Floatnumber = group(Pointfloat, Expfloat)
comptime Imagnumber = group(r"\d+(?:_\d+)*[jJ]", Floatnumber + r"[jJ]")
comptime Number = group(Imagnumber, Floatnumber, Intnumber)

# Tail end of ' string.
comptime Single = r"[^'\\]*(?:\\.[^'\\]*)*'"
# Tail end of " string.
comptime Double = r'[^"\\]*(?:\\.[^"\\]*)*"'
# Tail end of ` expr.
comptime Backtick = r"[^`\\]*(?:\\.[^`\\]*)*`"
# Tail end of ''' string.
comptime Single3 = r"[^'\\]*(?:(?:\\.|'(?!''))[^'\\]*)*'''"
# Tail end of """ string.
comptime Double3 = r'[^"\\]*(?:(?:\\.|"(?!""))[^"\\]*)*"""'


def _is_fstring_or_tstring(token: str, triple_quoted: bool = False) -> bool:
    # F-string/T-string prefixes for detection
    var _FSTRING_SINGLE_PREFIXES: Array[StaticString, 4] = [
        'f"',
        "f'",
        't"',
        "t'",
    ]
    var _FSTRING_TRIPLE_PREFIXES: Array[StaticString, 4] = [
        'f"""',
        "f'''",
        't"""',
        "t'''",
    ]
    var token_lower = token.lower()
    ref prefixes = (
        _FSTRING_TRIPLE_PREFIXES if triple_quoted else _FSTRING_SINGLE_PREFIXES
    )
    return startswith(prefixes, token_lower)


def _get_fstring_quote(token: str, triple_quoted: bool = False) -> str:
    """Parse f-string/t-string token to extract quote characters.

    Args:
        token: The token string (e.g., f", t''', etc.)
        triple_quoted: Whether this is a triple-quoted string

    Returns:
        The quote character(s) - single or triple quotes
    """
    # Prefix is always 1 character (f or t)
    # TODO: Converting to String for simplicity, should probably use a span
    if triple_quoted:
        return String(token[byte=1:4])  # """ or '''
    else:
        return String(token[byte=1])  # " or '


def scan_fstring_content(s: str, start: int, quote: str) -> int:
    """Scan f-string content handling nested braces and return end position.

    This function properly tracks brace depth to handle nested f-strings
    with same-quote delimiters, e.g., f"{f"{x}"}".

    Args:
        s: The source string to scan.
        start: Starting position (after opening quote).
        quote: The quote character(s) to match (single or triple quotes).

    Returns:
        Position after closing quote, or -1 if not found.
    """
    var i = start
    var brace_depth = 0
    var quote_len = quote.byte_length()

    while i < s.byte_length():
        # Check for closing quote (only when not inside braces)
        if brace_depth == 0 and s[byte = i : i + quote_len] == quote:
            return i + quote_len

        # Handle escaped characters
        if s[byte=i] == "\\" and i + 1 < s.byte_length():
            i += 2
            continue

        # Track brace depth
        if s[byte=i] == "{":
            # Only treat {{ as escaped when outside expressions (brace_depth == 0)
            if (
                brace_depth == 0
                and i + 1 < s.byte_length()
                and s[byte=i + 1] == "{"
            ):
                i += 2  # Escaped {{
                continue
            brace_depth += 1
            i += 1
            continue

        if s[byte=i] == "}":
            if brace_depth > 0:
                brace_depth -= 1
                i += 1
                continue
            # Only treat }} as escaped when outside expressions (brace_depth == 0)
            if i + 1 < s.byte_length() and s[byte=i + 1] == "}":
                i += 2  # Escaped }}
                continue
            i += 1
            continue

        # Inside braces, skip over string literals to avoid false brace matches
        if brace_depth > 0 and s[byte=i] in ('"', "'", "`"):
            # Detect triple-quoted strings
            var delim = (
                s[byte = i : i + 3] if s[byte = i : i + 3]
                in ('"""', "'''") else s[byte=i]
            )
            i += delim.byte_length()
            # Skip to end of string literal
            while i < s.byte_length():
                if s[byte = i : i + delim.byte_length()] == delim:
                    i += delim.byte_length()
                    break
                if s[byte=i] == "\\" and i + 1 < s.byte_length():
                    i += 2
                else:
                    i += 1
            continue

        i += 1

    return -1  # Not found


def _process_fstring_or_tstring(
    token: str,
    line: str,
    start: int,
    triple_quoted: bool,
) -> Optional[tuple[str, int, Optional[str]]]:
    """Process f-string or t-string token and return (token, pos, continuation_quote).

    Returns:
        Tuple of (token, new_pos, continuation_quote) or None
    """
    if not _is_fstring_or_tstring(token, triple_quoted):
        return None

    var quote_chars = _get_fstring_quote(token, triple_quoted)
    var quote_len = 3 if triple_quoted else 1
    # Prefix is always 1 character (f or t)
    var content_start = start + 1 + quote_len

    var new_end = scan_fstring_content(line, content_start, quote_chars)

    # TODO: Remove explicit Span to String conversion
    if new_end > 0:
        # Found on same line
        return (
            String(line[byte=start:new_end]),
            new_end,
            Optional[String](None),
        )
    else:
        # Multiline - needs continuation
        return (
            String(line[byte=start:]),
            line.byte_length(),
            Optional[String](quote_chars),
        )


comptime _litprefix = r"(?:[uUrRbBfFtT]|[rR][fFbBtT]|[fFbBuUtT][rR])?"
comptime _fprefix = r"(?:[fFtT]|[fFtT][rR]|[rR][fFtT])"
comptime _non_fprefix = r"(?:[uUrRbB]|[rR][bB]|[bB][rR])?"
comptime Triple = group(_litprefix + "'''", _litprefix + '"""')
# Single-line ' or " string or ` expr.
# F-strings need special handling to allow nested quotes inside {...}
comptime Stringgroup = group(
    # F-string patterns (must come first for longest match)
    _fprefix + r"'[^\n'\\{]*(?:(?:\\.|(?:\{[^\}]*\}))[^\n'\\{]*)*'",
    _fprefix + r'"[^\n"\\{]*(?:(?:\\.|(?:\{[^\}]*\}))[^\n"\\{]*)*"',
    # Regular string patterns
    _non_fprefix + r"'[^\n'\\]*(?:\\.[^\n'\\]*)*'",
    _non_fprefix + r'"[^\n"\\]*(?:\\.[^\n"\\]*)*"',
    _litprefix + r"`[^\n`\\]*(?:\\.[^\n`\\]*)*`",
)

# Because of leftmost-then-longest match semantics, be sure to put the
# longest operators first (e.g., if = came before ==, == would get
# recognized as two instances of =).
comptime Operator = group(
    r"\*\*=?",
    r">>=?",
    r"<<=?",
    r"<>",
    r"!=",
    r"//=?",
    r"->",
    r"[+\-*/%&@|^=<>:]=?",
    r"~",
)

comptime Bracket = "[][(){}]"
comptime Special = group(r"\r?\n", r"[:;.,@]")
comptime Funny = group(Operator, Bracket, Special)

# First (or only) line of ' or " string.
# F-strings need special patterns to allow nested quotes inside {...}
comptime ContStr = group(
    # F-string patterns
    _fprefix
    + r"'[^\n'\\{]*(?:(?:\\.|(?:\{[^\}]*\}))[^\n'\\{]*)*"
    + group("'", r"\\\r?\n"),
    _fprefix
    + r'"[^\n"\\{]*(?:(?:\\.|(?:\{[^\}]*\}))[^\n"\\{]*)*'
    + group('"', r"\\\r?\n"),
    # Regular string patterns
    _non_fprefix + r"'[^\n'\\]*(?:\\.[^\n'\\]*)*" + group("'", r"\\\r?\n"),
    _non_fprefix + r'"[^\n"\\]*(?:\\.[^\n"\\]*)*' + group('"', r"\\\r?\n"),
    _litprefix + r"`[^\n`\\]*(?:\\.[^\n`\\]*)*" + group("`", r"\\\r?\n"),
)
comptime PseudoExtras = group(r"\\\r?\n", Comment, Triple)
comptime PseudoToken = Whitespace + group(
    PseudoExtras, Number, Funny, ContStr, Name
)

comptime Matcher = def[O: ImmOrigin, //](
    text: StringSlice[O]
) raises thin -> Optional[Match[O]]


comptime _strprefixes = (
    _combinations("r", "R", "f", "F")
    | _combinations("r", "R", "t", "T")
    | _combinations("r", "R", "b", "B")
    | {"u", "U", "ur", "uR", "Ur", "UR"}
)


# TODO: list comprehensions don't work in comptime, but the error says to remove comptime _and_ move to a function?
def _get_endprogs() -> Dict[String, Optional[Matcher]]:
    comptime single3prog = match_first[Single3]
    comptime double3prog = match_first[Double3]
    var _strprefixes_mat = materialize[_strprefixes]()
    var result: Dict[String, Optional[Matcher]] = {
        "'": match_first[Single],
        '"': match_first[Double],
        "`": match_first[Backtick],
        "'''": single3prog,
        '"""': double3prog,
    }
    for prefix in _strprefixes_mat:
        # TODO: Does order matter here?
        result[String(t"{prefix}'''")] = single3prog
        result[String(t'{prefix}"""')] = double3prog
        result[prefix] = None
    return result^


comptime endprogs_comptime = _get_endprogs()


def _get_triple_quoted() -> Set[String]:
    var _strprefixes_mat = materialize[_strprefixes]()
    var result: Set[String]
    # TODO: Remove String() calls
    return {String(t"{prefix}'''") for prefix in _strprefixes_mat} | {
        String(t'{prefix}"""') for prefix in _strprefixes_mat
    }


comptime triple_quoted = {"'''", '"""'} | _get_triple_quoted()


def _get_single_quoted() -> Set[String]:
    var _strprefixes_mat = materialize[_strprefixes]()
    var result: Set[String]
    # TODO: Remove String() calls
    return {String(t"{prefix}'") for prefix in _strprefixes_mat} | {
        String(t'{prefix}"') for prefix in _strprefixes_mat
    }


comptime single_quoted_comptime = {"'", '"'} | _get_single_quoted()

comptime tabsize = 8


@fieldwise_init
struct TokenError:
    var err: String


@fieldwise_init
struct StopTokenizing:
    var err: String


@fieldwise_init
struct IndentationError:
    var err: String


comptime Coord = tuple[int, int]
comptime TokenEater = def(int, str, Coord, Coord, str)


comptime GoodTokenInfo = tuple[int, str, Coord, Coord, str]
comptime TokenInfo = Variant[tuple[int, str], GoodTokenInfo]


def _is_alpha(byte: Byte) -> Bool:
    return (Byte(ord("a")) <= byte and byte <= Byte(ord("z"))) or (
        Byte(ord("A")) <= byte and byte <= Byte(ord("Z"))
    )


def _is_digit(byte: Byte) -> Bool:
    return Byte(ord("0")) <= byte and byte <= Byte(ord("9"))


# Replaces Python's builtin
def _is_identifier(text: StringSpan) -> Bool:
    """Return True if text is a valid Mojo identifier."""
    if not text:
        return False

    # The first character must be a letter or underscore.
    if not (_is_alpha(Byte(ord(text[byte=0]))) or text[byte=0] == "_"):
        return False

    # Remaining characters may also include digits.
    for char in text[byte=1:]:
        var byte = Byte(ord(char))
        if not (_is_alpha(byte) or _is_digit(byte) or char == "_"):
            return False

    return True


def generate_tokens[
    f: def() -> str
](readline: f, grammar: Optional[Grammar] = None) raises Variant[
    TokenError, Error, IndentationError
] -> List[GoodTokenInfo]:
    """
    The generate_tokens() generator requires one argument, readline, which
    must be a callable object which provides the same interface as the
    readline() method of built-in file objects. Each call to the function
    should return one line of input as a string.  Alternately, readline
    can be a callable function terminating with StopIteration:
        readline = open(myfile).next    # Example of alternate readline.

    The generator produces 5-tuples with these members: the token type; the
    token string; a 2-tuple (srow, scol) of ints specifying the row and
    column where the token begins in the source; a 2-tuple (erow, ecol) of
    ints specifying the row and column where the token ends in the source;
    and the line on which the token was found. The line passed is the
    logical line; continuation lines are included.
    """
    # No async support in Mojo yet. Just make a list and return for now.
    var result: List[GoodTokenInfo] = []

    var lnum = 0
    var parenlev = 0
    var continued = 0
    comptime numchars = "0123456789"
    comptime pseudoprog = findall[PseudoToken]  # re.UNICODE ??
    var single_quoted = materialize[single_quoted_comptime]()
    var endprogs = materialize[endprogs_comptime]()
    var contstr = ""
    var needcont = 0
    var contline: Optional[str] = None
    var contstr_fstring_quote: Optional[
        str
    ] = None  # Track f-string quote for continuation
    var indents: List[Int] = [0]

    # If we know we're parsing 3.7+, we can unconditionally parse `async` and
    # `await` as keywords.
    var async_keywords = (
        False if grammar is None else grammar.value().async_keywords
    )
    # 'stashed' and 'async_*' are used for async/await parsing
    var stashed: Optional[GoodTokenInfo] = None
    var async_def = False
    var async_def_indent = 0
    var async_def_nl = False
    # If we know we're parsing Mojo, we can unconditionally parse various
    # identifiers, like `struct`, as keywords.
    var has_mojo_keywords = (
        False if grammar is None else grammar.value().mojo_keywords
    )
    # Tracks the value of the last meaningful (non-whitespace) token emitted,
    # used to decide whether a Mojo keyword token should instead be treated as
    # an ordinary NAME (e.g. `def struct(...)` where `struct` is the function name).
    var prev_token_value: Optional[String] = None
    var def_keywords: List[StaticString] = [
        "def",
        "__mlir_region",
    ] if has_mojo_keywords else [
        "def",
    ]
    # NOTE: If extending also update any lists of keywords in the testsuite.
    var mojo_keyword_tokens = {
        "struct": STRUCT,
        "comptime": COMPTIME,
        "var": VAR,
        "__mlir_region": MLIR_REGION,
        "__generator_type": GENERATOR_TYPE,
        "read": READ,
        "imm": IMM,
        "mut": MUT,
        "out": OUT,
        "deinit": DEINIT,
        "trait": TRAIT,
        "ref": REF,
        "where": WHERE,
        "__extension": EXTENSION,
    }

    var strstart: tuple[int, int]
    var endprog: Matcher

    while 1:  # loop over lines in stream
        var line: String
        try:
            line = readline()
        except StopIteration:
            line = ""
        lnum += 1
        var pos = 0
        var max = line.byte_length()

        if contstr:  # continued string
            assert contline is not None
            if not line:
                raise TokenError(
                    String(
                        t"EOF in multi-line string: ({strstart[0]},"
                        t" {strstart[1]})"
                    )
                )

            # Check if this is a continued f-string that needs stateful scanning
            if contstr_fstring_quote is not None:
                # Use stateful scanner for f-string continuation
                var end = scan_fstring_content(
                    line, 0, contstr_fstring_quote.value()
                )
                if end > 0:
                    # Found the end
                    pos = end
                    result.append(
                        (
                            STRING,
                            contstr + line[byte=:end],
                            strstart,
                            (lnum, end),
                            contline.value() + line,
                        )
                    )
                    contstr, needcont = "", 0
                    contline = None
                    contstr_fstring_quote = None
                else:
                    # Still continuing
                    contstr = contstr + line
                    contline = contline.value() + line
                    continue
            else:
                # Regular string continuation (not f-string)
                var endmatch = endprog(line)
                if endmatch:
                    pos = endmatch.value().end_idx
                    var end = pos
                    result.append(
                        (
                            STRING,
                            contstr + line[byte=:end],
                            strstart,
                            (lnum, end),
                            contline.value() + line,
                        )
                    )
                    contstr, needcont = "", 0
                    contline = None
                elif (
                    needcont
                    and line[byte= -2:] != StringSpan("\\\n")
                    and line[byte= -3:] != StringSpan("\\\r\n")
                ):
                    result.append(
                        (
                            ERRORTOKEN,
                            contstr + line,
                            strstart,
                            (lnum, line.byte_length()),
                            contline.value(),
                        )
                    )
                    contstr = ""
                    contline = None
                    continue
                else:
                    contstr = contstr + line
                    contline = contline.value() + line
                    continue

        elif parenlev == 0 and not continued:  # new statement
            if not line:
                break
            var column = 0
            while pos < max:  # measure leading whitespace
                if line[byte=pos] == " ":
                    column += 1
                elif line[byte=pos] == "\t":
                    column = (column // tabsize + 1) * tabsize
                elif line[byte=pos] == "\f":
                    column = 0
                else:
                    break
                pos += 1
            if pos == max:
                break

            if stashed:
                result.append(stashed.value())
                stashed = None

            if line[byte=pos] in "\r\n":  # skip blank lines
                result.append(
                    (
                        NL,
                        String(line[byte=pos:]),
                        Tuple(lnum, pos),
                        Tuple(lnum, line.byte_length()),
                        line,
                    )
                )
                continue

            if line[byte=pos] == "#":  # skip comments
                var comment_token = line[byte=pos:].rstrip("\r\n")
                var nl_pos = pos + comment_token.byte_length()
                result.append(
                    (
                        COMMENT,
                        String(comment_token),
                        (lnum, pos),
                        (lnum, nl_pos),
                        line,
                    )
                )
                result.append(
                    (
                        NL,
                        String(line[byte=nl_pos:]),
                        (lnum, nl_pos),
                        (lnum, line.byte_length()),
                        line,
                    )
                )
                continue

            if column > indents[-1]:  # count indents
                indents.append(column)
                result.append(
                    (
                        INDENT,
                        String(line[byte=:pos]),
                        (lnum, 0),
                        (lnum, pos),
                        line,
                    )
                )

            while column < indents[-1]:  # count dedents
                if column not in indents:
                    raise IndentationError(
                        String(
                            t"unindent does not match any outer indentation"
                            t" level: (<tokenize>, {lnum}, {pos}, {line})"
                        )
                    )
                # Remove last element
                _ = indents.pop()

                if async_def and async_def_indent >= indents[-1]:
                    async_def = False
                    async_def_nl = False
                    async_def_indent = 0

                result.append((DEDENT, "", (lnum, pos), (lnum, pos), line))

            if async_def and async_def_nl and async_def_indent >= indents[-1]:
                async_def = False
                async_def_nl = False
                async_def_indent = 0

        else:  # continued statement
            if not line:
                raise TokenError(
                    String(t"EOF in multi-line statement: ({lnum}, 0)")
                )
            continued = 0

        # Given an identifier matching a Mojo token, do extra context sensitive
        # checks for validity.  This is because we can't get things like 'out'
        # handled properly as soft tokens.  This returns true if this can be
        # handled as a normal Mojo token.
        def check_mojo_token(
            token_value: str, token_end: int
        ) {grammar, prev_token_value, line} -> Bool:
            assert grammar is not None
            # In Mojo, keywords can be used as function/struct names.
            # After a def-like keyword or '.', treat the token as a
            # plain NAME so `def fn(...)` or `x.struct` parse correctly.
            if (
                prev_token_value.value()
                in grammar.value().declaration_keywords + ["."]
            ):
                return False
            # Context sensitive arg conventions are only a keyword if followed
            # by an identifier letter or a variadic.
            if token_value not in ["out", "read", "imm", "mut", "deinit"]:
                return True
            var next_token = line[byte=token_end:].lstrip()
            if token_value == "out" and next_token.startswith("["):
                var bracket_depth = 0
                for idx, char in enumerate(next_token.bytes()):
                    if char == Byte(ord("[")):
                        bracket_depth += 1
                    elif char == Byte(ord("]")):
                        bracket_depth -= 1
                        if bracket_depth == 0:
                            var after_bracket = next_token[
                                byte = idx + 1 :
                            ].lstrip()
                            return bool(after_bracket) and _is_identifier(
                                after_bracket[byte=0]
                            )
                return False
            return next_token and (
                _is_identifier(next_token[byte=0])
                or next_token[byte=0] == StringSpan("*")
            )

        while pos < max:
            var pseudomatch = pseudoprog(line[byte=pos:])
            if len(pseudomatch) > 1:  # scan for tokens
                var start = pseudomatch[1].start_idx
                var end = pseudomatch[1].end_idx
                var spos = (lnum, start)
                var epos = (lnum, end)
                pos = end
                var token = String(line[byte=start:end])
                var initial = line[byte=start]

                if initial in numchars or (
                    initial == "." and token != StringSpan(".")
                ):  # ordinary number
                    result.append((NUMBER, token, spos, epos, line))
                elif initial in "\r\n":
                    var newline = NEWLINE
                    if parenlev > 0:
                        newline = NL
                    elif async_def:
                        async_def_nl = True
                    if stashed:
                        result.append(stashed.value())
                        stashed = None
                    if newline == NEWLINE:
                        prev_token_value = None
                    result.append((newline, token, spos, epos, line))

                elif initial == "#":
                    assert not token.endswith("\n")
                    if stashed:
                        result.append(stashed.value())
                        stashed = None
                    result.append((COMMENT, token, spos, epos, line))
                elif token in materialize[triple_quoted]():
                    # Try processing as f-string/t-string
                    var tfstr_result = _process_fstring_or_tstring(
                        token, line, start, triple_quoted=True
                    )
                    if tfstr_result:
                        token = tfstr_result.value()[0]
                        pos = tfstr_result.value()[1]
                        var quote_chars = tfstr_result.value()[2]
                        if quote_chars is None:
                            # Found on same line
                            if stashed:
                                result.append(stashed.value())
                                stashed = None
                            result.append(
                                (
                                    STRING,
                                    token,
                                    spos,
                                    (lnum, pos),
                                    line,
                                )
                            )
                        else:
                            # Multi-line f-string/t-string
                            strstart = (lnum, start)
                            contstr = token
                            contline = line
                            contstr_fstring_quote = quote_chars
                            break
                    else:
                        # Regular triple-quoted string (not f-string/t-string)
                        endprog = endprogs[token].value()
                        var endmatch = endprog(line[byte=:pos])
                        if endmatch:  # all on one line
                            pos = endmatch.value().end_idx
                            token = String(line[byte=start:pos])
                            if stashed:
                                result.append(stashed.value())
                                stashed = None
                            result.append(
                                (STRING, token, spos, (lnum, pos), line)
                            )
                        else:
                            strstart = (lnum, start)  # multiple lines
                            contstr = String(line[byte=start:])
                            contline = line
                            break
                elif (
                    String(initial) in single_quoted
                    or String(token[byte=:2]) in single_quoted
                    or String(token[byte=:3]) in single_quoted
                ):
                    # Try processing as f-string/t-string
                    if token[byte=-1] != String("\n"):
                        var result_tfstr = _process_fstring_or_tstring(
                            token, line, start, triple_quoted=False
                        )
                        if result_tfstr:
                            token = result_tfstr.value()[0]
                            pos = result_tfstr.value()[1]
                            var quote_char = result_tfstr.value()[2]
                            if quote_char is None:
                                # Found on same line
                                if stashed:
                                    result.append(stashed.value())
                                    stashed = None
                                result.append(
                                    (STRING, token, spos, (lnum, pos), line)
                                )
                                continue
                            else:
                                # Multi-line f-string/t-string
                                strstart = (lnum, start)
                                contstr = token
                                contline = line
                                contstr_fstring_quote = quote_char
                                break

                    if token[byte=-1] == "\n":  # continued string
                        strstart = (lnum, start)
                        endprog = (
                            endprogs[String(initial)]
                            or endprogs[String(token[byte=1])]
                            or endprogs[String(token[byte=2])]
                        ).value()  # this value() might be wrong
                        contstr = String(line[byte=start:])
                        needcont = 1
                        contline = line
                        break
                    else:  # ordinary string
                        if stashed:
                            result.append(stashed.value())
                            stashed = None
                        result.append((STRING, token, spos, epos, line))
                elif token.startswith("`"):
                    endprog = endprogs[
                        "`"
                    ].value()  # maybe this value() is correct?
                    # var endmatch = endprog(line[byte=pos:]) # unused
                    result.append((NAME, token, spos, epos, line))
                elif _is_identifier(initial):  # ordinary name
                    if (
                        has_mojo_keywords
                        and token in mojo_keyword_tokens
                        and check_mojo_token(token, end)
                    ):
                        var tok_type = mojo_keyword_tokens[token]
                        # comptime followed by '(' is the expression form
                        # comptime(expr) — emit as NAME so it parses as a
                        # regular function call.
                        if tok_type == COMPTIME:
                            var next_chars = line[byte=end:].lstrip()
                            if next_chars and next_chars[byte=0] == "(":
                                tok_type = NAME
                        prev_token_value = token
                        result.append((tok_type, token, spos, epos, line))
                        continue

                    if token in ("async", "await"):
                        if async_keywords or async_def:
                            result.append(
                                (
                                    ASYNC if token == "async" else AWAIT,
                                    token,
                                    spos,
                                    epos,
                                    line,
                                )
                            )
                            continue

                    var tok = (NAME, token, spos, epos, line)
                    if token == "async" and not stashed:
                        stashed = tok
                        continue

                    # No easy way to do "is string in list[stringspan]", file bug?
                    # "token in def_keywords"
                    if token == "for" or token in [
                        String(kw) for kw in def_keywords
                    ]:
                        if (
                            stashed
                            and stashed.value()[0] == NAME
                            and stashed.value()[1] == "async"
                        ):
                            if token in [String(kw) for kw in def_keywords]:
                                async_def = True
                                async_def_indent = indents[-1]

                            result.append(
                                (
                                    ASYNC,
                                    stashed.value()[1],
                                    stashed.value()[2],
                                    stashed.value()[3],
                                    stashed.value()[4],
                                )
                            )
                            stashed = None

                    if stashed:
                        prev_token_value = stashed.value()[1]
                        result.append(stashed.value())
                        stashed = None

                    prev_token_value = token
                    result.append(tok)
                elif initial == "\\":  # continued stmt
                    # This yield is new; needed for better idempotency:
                    if stashed:
                        result.append(stashed.value())
                        stashed = None
                    result.append((NL, token, spos, (lnum, pos), line))
                    continued = 1
                else:
                    if initial in "([{":
                        parenlev += 1
                    elif initial in ")]}":
                        parenlev -= 1
                    if stashed:
                        prev_token_value = stashed.value()[1]
                        result.append(stashed.value())
                        stashed = None
                    prev_token_value = token
                    result.append((OP, token, spos, epos, line))
            else:
                result.append(
                    (
                        ERRORTOKEN,
                        String(line[byte=pos]),
                        (lnum, pos),
                        (lnum, pos + 1),
                        line,
                    )
                )
                pos += 1

    if stashed:
        result.append(stashed.value())
        stashed = None

    for _indent in indents[1:]:  # pop remaining indent levels
        result.append((DEDENT, "", (lnum, 0), (lnum, 0), ""))
    result.append((ENDMARKER, "", (lnum, 0), (lnum, 0), ""))

    return result^
