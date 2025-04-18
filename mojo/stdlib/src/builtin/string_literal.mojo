# ===----------------------------------------------------------------------=== #
# Copyright (c) 2025, Modular Inc. All rights reserved.
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
"""Implements the StringLiteral struct.

These are Mojo built-ins, so you don't need to import them.
"""

from collections import List
from collections.string.format import _CurlyEntryFormattable, _FormatCurlyEntry
from collections.string.string_slice import (
    StaticString,
    StringSlice,
    CodepointSliceIter,
    _to_string_list,
)
from hashlib._hasher import _HashableWithHasher, _Hasher
from sys.ffi import c_char

from memory import Span, UnsafePointer, memcpy

from os import PathLike

from utils import Writable, Writer
from utils._visualizers import lldb_formatter_wrapping_type
from utils.write import _WriteBufferStack

# ===-----------------------------------------------------------------------===#
# StringLiteral
# ===-----------------------------------------------------------------------===#


@lldb_formatter_wrapping_type
@register_passable("trivial")
struct StringLiteral(
    Boolable,
    Comparable,
    CollectionElementNew,
    Writable,
    IntableRaising,
    KeyElement,
    Representable,
    Sized,
    Stringable,
    FloatableRaising,
    _HashableWithHasher,
    PathLike,
    EqualityComparableCollectionElement,
    _CurlyEntryFormattable,
):
    """This type represents a string literal.

    String literals are all null-terminated for compatibility with C APIs, but
    this is subject to change. String literals store their length as an integer,
    and this does not include the null terminator.
    """

    # Fields
    alias type = __mlir_type.`!kgen.string`

    var value: Self.type
    """The underlying storage for the string literal."""

    # ===-------------------------------------------------------------------===#
    # Life cycle methods
    # ===-------------------------------------------------------------------===#

    @always_inline("builtin")
    @implicit
    fn __init__(out self, value: Self.type):
        """Create a string literal from a builtin string type.

        Args:
            value: The string value.
        """
        self.value = value

    @always_inline("nodebug")
    fn copy(self) -> Self:
        """Copy constructor.

        Returns:
            A copy of the value.
        """
        return self

    # ===-------------------------------------------------------------------===#
    # Operator dunders
    # ===-------------------------------------------------------------------===#

    @always_inline("nodebug")
    fn __add__(self, rhs: StringLiteral) -> StringLiteral:
        """Concatenate two string literals.

        Args:
            rhs: The string to concat.

        Returns:
            The concatenated string.
        """
        return __mlir_op.`pop.string.concat`(self.value, rhs.value)

    fn __mul__(self, n: Int) -> String:
        """Concatenates the string `n` times.

        Args:
            n : The number of times to concatenate the string.

        Returns:
            The string concatenated `n` times.
        """
        return self.as_string_slice() * n

    @always_inline("nodebug")
    fn __eq__(self, rhs: StringLiteral) -> Bool:
        """Compare two string literals for equality.

        Args:
            rhs: The string to compare.

        Returns:
            True if they are equal.
        """
        return not (self != rhs)

    @always_inline("nodebug")
    fn __ne__(self, rhs: StringLiteral) -> Bool:
        """Compare two string literals for inequality.

        Args:
            rhs: The string to compare.

        Returns:
            True if they are not equal.
        """
        return self.as_string_slice() != rhs.as_string_slice()

    @always_inline("nodebug")
    fn __eq__(self, rhs: StringSlice) -> Bool:
        """Compare two string literals for equality.

        Args:
            rhs: The string to compare.

        Returns:
            True if they are equal.
        """
        return not (self != rhs)

    @always_inline("nodebug")
    fn __ne__(self, rhs: StringSlice) -> Bool:
        """Compare two string literals for inequality.

        Args:
            rhs: The string to compare.

        Returns:
            True if they are not equal.
        """
        return self.as_string_slice() != rhs

    @always_inline("nodebug")
    fn __lt__(self, rhs: StringLiteral) -> Bool:
        """Compare this StringLiteral to the RHS using lesser than (LT) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is strictly less than the RHS StringLiteral and False otherwise.
        """
        return self.as_string_slice() < rhs.as_string_slice()

    @always_inline("nodebug")
    fn __le__(self, rhs: StringLiteral) -> Bool:
        """Compare this StringLiteral to the RHS using lesser than or equal to (LE) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is less than or equal to the RHS StringLiteral and False otherwise.
        """
        return not (rhs < self)

    @always_inline("nodebug")
    fn __gt__(self, rhs: StringLiteral) -> Bool:
        """Compare this StringLiteral to the RHS using greater than (GT) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is strictly greater than the RHS StringLiteral and False otherwise.
        """
        return rhs < self

    @always_inline("nodebug")
    fn __ge__(self, rhs: StringLiteral) -> Bool:
        """Compare this StringLiteral to the RHS using greater than or equal to (GE) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is greater than or equal to the RHS StringLiteral and False otherwise.
        """
        return not (self < rhs)

    @always_inline("nodebug")
    fn __lt__(self, rhs: StringSlice) -> Bool:
        """Compare this StringLiteral to the RHS using lesser than (LT) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is strictly less than the RHS StringLiteral and False otherwise.
        """
        return self.as_string_slice() < rhs

    @always_inline("nodebug")
    fn __le__(self, rhs: StringSlice) -> Bool:
        """Compare this StringLiteral to the RHS using lesser than or equal to (LE) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is less than or equal to the RHS StringLiteral and False otherwise.
        """
        return not (rhs < self)

    @always_inline("nodebug")
    fn __gt__(self, rhs: StringSlice) -> Bool:
        """Compare this StringLiteral to the RHS using greater than (GT) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is strictly greater than the RHS StringLiteral and False otherwise.
        """
        return rhs < self

    @always_inline("nodebug")
    fn __ge__(self, rhs: StringSlice) -> Bool:
        """Compare this StringLiteral to the RHS using greater than or equal to (GE) comparison.

        Args:
            rhs: The other StringLiteral to compare against.

        Returns:
            True if this StringLiteral is greater than or equal to the RHS StringLiteral and False otherwise.
        """
        return not (self < rhs)

    fn __contains__(self, substr: StringLiteral) -> Bool:
        """Returns True if the substring is contained within the current string.

        Args:
          substr: The substring to check.

        Returns:
          True if the string contains the substring.
        """
        return substr in self.as_string_slice()

    # ===-------------------------------------------------------------------===#
    # Trait implementations
    # ===-------------------------------------------------------------------===#

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Get the string length.

        Returns:
            The length of this StringLiteral.
        """
        # TODO(MSTDL-160):
        #   Properly count Unicode codepoints instead of returning this length
        #   in bytes.
        return self.byte_length()

    @always_inline("nodebug")
    fn __bool__(self) -> Bool:
        """Convert the string to a bool value.

        Returns:
            True if the string is not empty.
        """
        return len(self) != 0

    @always_inline
    fn __int__(self) raises -> Int:
        """Parses the given string as a base-10 integer and returns that value.
        If the string cannot be parsed as an int, an error is raised.

        Returns:
            An integer value that represents the string, or otherwise raises.
        """
        return Int(self.as_string_slice())

    @always_inline
    fn __float__(self) raises -> Float64:
        """Parses the string as a float point number and returns that value. If
        the string cannot be parsed as a float, an error is raised.

        Returns:
            A float value that represents the string, or otherwise raises.
        """
        return Float64(self.as_string_slice())

    @no_inline
    fn __str__(self) -> String:
        """Convert the string literal to a string.

        Returns:
            A new string.
        """
        # TODO(MOCO-1224): We should be able to reuse this, but we have to
        # inline the string slice constructor to work around an elaborator
        # memory leak.
        # return self.as_string_slice()
        var buffer = String._buffer_type(capacity=self.byte_length() + 1)
        buffer.extend(self.as_bytes())
        buffer.append(0)
        return String(buffer=buffer^)

    @no_inline
    fn __repr__(self) -> String:
        """Return a representation of the `StringLiteral` instance.

        You don't need to call this method directly, use `repr("...")` instead.

        Returns:
            A new representation of the string.
        """
        return repr(self.as_string_slice())

    fn __hash__(self) -> UInt:
        """Hash the underlying buffer using builtin hash.

        Returns:
            A 64-bit hash value. This value is _not_ suitable for cryptographic
            uses. Its intended usage is for data structures. See the `hash`
            builtin documentation for more details.
        """
        return hash(self.unsafe_ptr(), len(self))

    fn __hash__[H: _Hasher](self, mut hasher: H):
        """Updates hasher with the underlying bytes.

        Parameters:
            H: The hasher type.

        Args:
            hasher: The hasher instance.
        """
        hasher._update_with_bytes(self.unsafe_ptr(), self.byte_length())

    fn __fspath__(self) -> String:
        """Return the file system path representation of the object.

        Returns:
          The file system path representation as a string.
        """
        return self.__str__()

    fn __iter__(self) -> CodepointSliceIter[StaticConstantOrigin]:
        """Return an iterator over the string literal.

        Returns:
            An iterator over the string.
        """
        return CodepointSliceIter(self.as_string_slice())

    fn __reversed__(self) -> CodepointSliceIter[StaticConstantOrigin, False]:
        """Iterate backwards over the string, returning immutable references.

        Returns:
            A reversed iterator over the string.
        """
        return CodepointSliceIter[StaticConstantOrigin, False](
            self.as_string_slice()
        )

    fn __getitem__[IndexerType: Indexer](self, idx: IndexerType) -> String:
        """Gets the character at the specified position.

        Parameters:
            IndexerType: The inferred type of an indexer argument.

        Args:
            idx: The index value.

        Returns:
            A new string containing the character at the specified position.
        """
        return String(self)[idx]

    # ===-------------------------------------------------------------------===#
    # Methods
    # ===-------------------------------------------------------------------===#

    @always_inline("builtin")
    fn byte_length(self) -> Int:
        """Get the string length in bytes.

        Returns:
            The length of this StringLiteral in bytes.

        Notes:
            This does not include the trailing null terminator in the count.
        """
        return __mlir_op.`pop.string.size`(self.value)

    @always_inline("nodebug")
    fn unsafe_ptr(
        self,
    ) -> UnsafePointer[Byte, mut=False, origin=StaticConstantOrigin]:
        """Get raw pointer to the underlying data.

        Returns:
            The raw pointer to the data.
        """
        var ptr = UnsafePointer(__mlir_op.`pop.string.address`(self.value))

        # TODO(MSTDL-555):
        #   Remove bitcast after changing pop.string.address
        #   return type.
        return ptr.bitcast[Byte]().origin_cast[False, StaticConstantOrigin]()

    @always_inline
    fn unsafe_cstr_ptr(
        self,
    ) -> UnsafePointer[c_char, mut=False, origin=StaticConstantOrigin]:
        """Retrieves a C-string-compatible pointer to the underlying memory.

        The returned pointer is guaranteed to be NUL terminated, and not null.

        Returns:
            The pointer to the underlying memory.
        """
        return self.unsafe_ptr().bitcast[c_char]()

    @always_inline("nodebug")
    fn as_string_slice(self) -> StaticString:
        """Returns a string slice of this static string literal.

        Returns:
            A string slice pointing to this static string literal.
        """

        # FIXME(MSTDL-160):
        #   Enforce UTF-8 encoding in StringLiteral so this is actually
        #   guaranteed to be valid.
        return StaticString(ptr=self.unsafe_ptr(), length=self.byte_length())

    @always_inline("nodebug")
    fn as_bytes(self) -> Span[Byte, StaticConstantOrigin]:
        """
        Returns a contiguous Span of the bytes owned by this string.

        Returns:
            A contiguous slice pointing to the bytes owned by this string.
        """

        return Span[Byte, StaticConstantOrigin](
            ptr=self.unsafe_ptr(), length=self.byte_length()
        )

    @always_inline
    fn format[*Ts: _CurlyEntryFormattable](self, *args: *Ts) raises -> String:
        """Format a template with `*args`.

        Args:
            args: The substitution values.

        Parameters:
            Ts: The types of substitution values that implement `Representable`
                and `Stringable` (to be changed and made more flexible).

        Returns:
            The template with the given values substituted.

        Examples:

        ```mojo
        # Manual indexing:
        print("{0} {1} {0}".format("Mojo", 1.125)) # Mojo 1.125 Mojo
        # Automatic indexing:
        print("{} {}".format(True, "hello world")) # True hello world
        ```
        .
        """
        return _FormatCurlyEntry.format(self, args)

    fn write_to[W: Writer](self, mut writer: W):
        """
        Formats this string literal to the provided Writer.

        Parameters:
            W: A type conforming to the Writable trait.

        Args:
            writer: The object to write to.
        """

        writer.write(self.as_string_slice())

    fn find(self, substr: StringLiteral, start: Int = 0) -> Int:
        """Finds the offset of the first occurrence of `substr` starting at
        `start`. If not found, returns -1.

        Args:
          substr: The substring to find.
          start: The offset from which to find.

        Returns:
          The offset of `substr` relative to the beginning of the string.
        """
        return self.as_string_slice().find(substr, start=start)

    fn rfind(self, substr: StringLiteral, start: Int = 0) -> Int:
        """Finds the offset of the last occurrence of `substr` starting at
        `start`. If not found, returns -1.

        Args:
          substr: The substring to find.
          start: The offset from which to find.

        Returns:
          The offset of `substr` relative to the beginning of the string.
        """
        return self.as_string_slice().rfind(substr, start=start)

    fn replace(self, old: StringLiteral, new: StringLiteral) -> StringLiteral:
        """Return a copy of the string with all occurrences of substring `old`
        if replaced by `new`. This operation only works in the param domain.

        Args:
            old: The substring to replace.
            new: The substring to replace with.

        Returns:
            The string where all occurrences of `old` are replaced with `new`.
        """
        return __mlir_op.`pop.string.replace`(self.value, old.value, new.value)

    fn join[T: WritableCollectionElement](self, elems: List[T, *_]) -> String:
        """Joins string elements using the current string as a delimiter.

        Parameters:
            T: The types of the elements.

        Args:
            elems: The input values.

        Returns:
            The joined string.
        """
        var string = String()
        var buffer = _WriteBufferStack(string)
        for i in range(len(elems)):
            buffer.write(elems[i])
            if i < len(elems) - 1:
                buffer.write(self)
        buffer.flush()
        return string

    fn join[*Ts: Writable](self, *elems: *Ts) -> String:
        """Joins string elements using the current string as a delimiter.

        Parameters:
            Ts: The types of the elements.

        Args:
            elems: The input values.

        Returns:
            The joined string.
        """
        return String(elems, sep=self)

    fn split(self, sep: StringSlice, maxsplit: Int = -1) raises -> List[String]:
        """Split the string literal by a separator.

        Args:
            sep: The string to split on.
            maxsplit: The maximum amount of items to split from String.
                Defaults to unlimited.

        Returns:
            A List of Strings containing the input split by the separator.

        Examples:

        ```mojo
        # Splitting a space
        _ = "hello world".split(" ") # ["hello", "world"]
        # Splitting adjacent separators
        _ = "hello,,world".split(",") # ["hello", "", "world"]
        # Splitting with maxsplit
        _ = "1,2,3".split(",", 1) # ['1', '2,3']
        ```
        .
        """
        return String(self).split(sep, maxsplit)

    fn split(self, sep: NoneType = None, maxsplit: Int = -1) -> List[String]:
        """Split the string literal by every whitespace separator.

        Args:
            sep: None.
            maxsplit: The maximum amount of items to split from string. Defaults
                to unlimited.

        Returns:
            A List of Strings containing the input split by the separator.

        Examples:

        ```mojo
        # Splitting an empty string or filled with whitespaces
        _ = "      ".split() # []
        _ = "".split() # []

        # Splitting a string with leading, trailing, and middle whitespaces
        _ = "      hello    world     ".split() # ["hello", "world"]
        # Splitting adjacent universal newlines:
        _ = "hello \\t\\n\\v\\f\\r\\x1c\\x1d\\x1e\\x85\\u2028\\u2029world".split()
        # ["hello", "world"]
        ```
        .
        """
        return String(self).split(sep, maxsplit)

    fn splitlines(self, keepends: Bool = False) -> List[String]:
        """Split the string literal at line boundaries. This corresponds to Python's
        [universal newlines:](
            https://docs.python.org/3/library/stdtypes.html#str.splitlines)
        `"\\r\\n"` and `"\\t\\n\\v\\f\\r\\x1c\\x1d\\x1e\\x85\\u2028\\u2029"`.

        Args:
            keepends: If True, line breaks are kept in the resulting strings.

        Returns:
            A List of Strings containing the input split by line boundaries.
        """
        return _to_string_list(self.as_string_slice().splitlines(keepends))

    fn count(self, substr: StringSlice) -> Int:
        """Return the number of non-overlapping occurrences of substring
        `substr` in the string literal.

        If sub is empty, returns the number of empty strings between characters
        which is the length of the string plus one.

        Args:
          substr: The substring to count.

        Returns:
          The number of occurrences of `substr`.
        """
        return String(self).count(substr)

    fn lower(self) -> String:
        """Returns a copy of the string literal with all cased characters
        converted to lowercase.

        Returns:
            A new string where cased letters have been converted to lowercase.
        """

        return String(self).lower()

    fn upper(self) -> String:
        """Returns a copy of the string literal with all cased characters
        converted to uppercase.

        Returns:
            A new string where cased letters have been converted to uppercase.
        """

        return String(self).upper()

    fn rjust(self, width: Int, fillchar: StringLiteral = " ") -> String:
        """Returns the string right justified in a string literal of specified width.

        Args:
            width: The width of the field containing the string.
            fillchar: Specifies the padding character.

        Returns:
            Returns right justified string, or self if width is not bigger than self length.
        """
        return String(self).rjust(width, fillchar)

    fn ljust(self, width: Int, fillchar: StringLiteral = " ") -> String:
        """Returns the string left justified in a string literal of specified width.

        Args:
            width: The width of the field containing the string.
            fillchar: Specifies the padding character.

        Returns:
            Returns left justified string, or self if width is not bigger than self length.
        """
        return String(self).ljust(width, fillchar)

    fn center(self, width: Int, fillchar: StringLiteral = " ") -> String:
        """Returns the string center justified in a string literal of specified width.

        Args:
            width: The width of the field containing the string.
            fillchar: Specifies the padding character.

        Returns:
            Returns center justified string, or self if width is not bigger than self length.
        """
        return String(self).center(width, fillchar)

    fn startswith(
        self, prefix: StringSlice, start: Int = 0, end: Int = -1
    ) -> Bool:
        """Checks if the string literal starts with the specified prefix between
        start and end positions. Returns True if found and False otherwise.

        Args:
            prefix: The prefix to check.
            start: The start offset from which to check.
            end: The end offset from which to check.

        Returns:
            True if the `self[start:end]` is prefixed by the input prefix.
        """
        return self.as_string_slice().startswith(prefix, start, end)

    fn endswith(
        self, suffix: StringSlice, start: Int = 0, end: Int = -1
    ) -> Bool:
        """Checks if the string literal end with the specified suffix between
        start and end positions. Returns True if found and False otherwise.

        Args:
            suffix: The suffix to check.
            start: The start offset from which to check.
            end: The end offset from which to check.

        Returns:
            True if the `self[start:end]` is suffixed by the input suffix.
        """
        return self.as_string_slice().endswith(suffix, start, end)

    fn isdigit(self) -> Bool:
        """Returns True if all characters in the string literal are digits.

        Note that this currently only works with ASCII strings.

        Returns:
            True if all characters are digits else False.
        """
        return String(self).isdigit()

    fn isupper(self) -> Bool:
        """Returns True if all cased characters in the string literal are
        uppercase and there is at least one cased character.

        Note that this currently only works with ASCII strings.

        Returns:
            True if all cased characters in the string literal are uppercase
            and there is at least one cased character, False otherwise.
        """
        return String(self).isupper()

    fn islower(self) -> Bool:
        """Returns True if all cased characters in the string literal
        are lowercase and there is at least one cased character.

        Note that this currently only works with ASCII strings.

        Returns:
            True if all cased characters in the string literal are lowercase
            and there is at least one cased character, False otherwise.
        """
        return String(self).islower()

    fn strip(self) -> String:
        """Return a copy of the string literal with leading and trailing
        whitespaces removed. This only takes ASCII whitespace into account:
        `" \\t\\n\\v\\f\\r\\x1c\\x1d\\x1e"`.

        Returns:
            A string with no leading or trailing whitespaces.
        """
        return String(self.lstrip().rstrip())

    fn strip(self, chars: StringSlice) -> String:
        """Return a copy of the string literal with leading and trailing characters
        removed.

        Args:
            chars: A set of characters to be removed. Defaults to whitespace.

        Returns:
            A string with no leading or trailing characters.
        """

        return String(self.lstrip(chars).rstrip(chars))

    fn rstrip(self, chars: StringSlice) -> String:
        """Return a copy of the string literal with trailing characters removed.

        Args:
            chars: A set of characters to be removed. Defaults to whitespace.

        Returns:
            A string with no trailing characters.
        """
        return String(String(self).rstrip(chars))

    fn rstrip(self) -> String:
        """Return a copy of the string with trailing whitespaces removed. This
        only takes ASCII whitespace into account:
        `" \\t\\n\\v\\f\\r\\x1c\\x1d\\x1e"`.

        Returns:
            A copy of the string with no trailing whitespaces.
        """
        return String(self.as_string_slice().rstrip())

    fn lstrip(self, chars: StringSlice) -> String:
        """Return a copy of the string with leading characters removed.

        Args:
            chars: A set of characters to be removed. Defaults to whitespace.

        Returns:
            A copy of the string with no leading characters.
        """
        return String(self.as_string_slice().lstrip(chars))

    fn lstrip(self) -> String:
        """Return a copy of the string with leading whitespaces removed. This
        only takes ASCII whitespace into account:
        `" \\t\\n\\v\\f\\r\\x1c\\x1d\\x1e"`.

        Returns:
            A copy of the string with no leading whitespaces.
        """
        return String(String(self).lstrip())


# FIXME(MOCO-1707): This should be named get_string_literal[value: StringSlice],
# but Mojo isn't picking the most specific overload correctly.
@always_inline("nodebug")
fn get_string_literal_slice[value: StringSlice]() -> StringLiteral:
    """Form a string literal from an arbitrary compile-time StringSlice value.

    Parameters:
        value: The value to convert to StringLiteral.

    Returns:
        The string value as a StringLiteral.
    """
    return __mlir_attr[
        `#kgen.param.expr<data_to_str,`,
        value.byte_length().value,
        `,`,
        value.unsafe_ptr().address,
        `> : !kgen.string`,
    ]


# TODO(MOCO-1460): get_string_literal should be an initializer, but Mojo tries
# to bind the parameter in `StringLiteral["foo"]()` to the type instead of the
# initializer.   Use a global function to work around this for now.
@always_inline("nodebug")
fn get_string_literal[value: String]() -> StringLiteral:
    """Form a string literal from an arbitrary compile-time String value.

    Parameters:
        value: The value to convert to StringLiteral.

    Returns:
        The string value as a StringLiteral.
    """
    return get_string_literal_slice[value]()


@always_inline("nodebug")
fn get_string_literal[type: Stringable, //, value: type]() -> StringLiteral:
    """Form a string literal from an arbitrary compile-time stringable value.

    Parameters:
        type: The type of the value.
        value: The value to serialize.

    Returns:
        The string value as a StringLiteral.
    """
    return get_string_literal_slice[String(value)]()


fn _base64_encode[str: StringLiteral]() -> StringLiteral:
    """Encode the string literal using Base64 encoding.

    Returns:
        A new string literal with the Base64 encoded string.
    """
    return __mlir_op.`pop.string.base64.encode`(str.value)


fn _base64_decode[str: StringLiteral]() -> StringLiteral:
    """Decode the string literal using Base64 encoding.

    Returns:
        A new string literal with the Base64 decoded string.
    """
    return __mlir_op.`pop.string.base64.decode`(str.value)


fn _compress[str: StringLiteral]() -> StringLiteral:
    """Compress the string literal using zlib.

    Returns:
        A new string literal with the compressed string.
    """
    return __mlir_op.`pop.string.compress`(str.value)


fn _decompress[str: StringLiteral]() -> StringLiteral:
    """Decompress the string literal using zlib.

    Returns:
        A new string literal with the decompressed string.
    """
    return __mlir_op.`pop.string.decompress`(str.value)
