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
#   Path:   src/black/mode.py
#
# ===----------------------------------------------------------------------=== #

"""Data structures configuring Black behavior.

Mostly around Python language feature support per version and Black configuration
chosen by the user.
"""

from dataclasses import dataclass, field
from enum import Enum, auto
from hashlib import sha256
from warnings import warn

from mblack.const import DEFAULT_LINE_LENGTH


class TargetVersion(Enum):
    MOJO = 99


class Feature(Enum):
    TRAILING_COMMA_IN_CALL = 4
    TRAILING_COMMA_IN_DEF = 5
    FORCE_OPTIONAL_PARENTHESES = 50


class Preview(Enum):
    """Individual preview style features."""

    annotation_parens = auto()
    empty_lines_before_class_or_def_with_leading_comments = auto()
    handle_trailing_commas_in_head = auto()
    long_docstring_quotes_on_newline = auto()
    normalize_docstring_quotes_and_prefixes_properly = auto()
    one_element_subscript = auto()
    remove_block_trailing_newline = auto()
    remove_redundant_parens = auto()
    string_processing = auto()
    skip_magic_trailing_comma_in_subscript = auto()


class Deprecated(UserWarning):
    """Visible deprecation warning."""


@dataclass
class Mode:
    target_versions: set[TargetVersion] = field(default_factory=set)
    line_length: int = DEFAULT_LINE_LENGTH
    string_normalization: bool = True
    is_pyi: bool = False
    is_ipynb: bool = False
    is_mojo: bool = False
    skip_source_first_line: bool = False
    magic_trailing_comma: bool = True
    experimental_string_processing: bool = False
    python_cell_magics: set[str] = field(default_factory=set)
    preview: bool = False

    def __post_init__(self) -> None:
        if self.experimental_string_processing:
            warn(
                "`experimental string processing` has been included in"
                " `preview` and deprecated. Use `preview` instead.",
                Deprecated,
            )

    def __contains__(self, feature: Preview) -> bool:
        """
        Provide `Preview.FEATURE in Mode` syntax that mirrors the ``preview`` flag.

        The argument is not checked and features are not differentiated.
        They only exist to make development easier by clarifying intent.
        """
        if feature is Preview.string_processing:
            return self.preview or self.experimental_string_processing
        # In Mojo mode, always respect trailing commas in the head component
        # of bracket splits. Without this, trailing commas in struct
        # parameters like `struct S[A,](T):` are ignored when conformances
        # cause the first split to put parameters in the head.
        if feature is Preview.handle_trailing_commas_in_head:
            return (
                self.preview
                or self.is_mojo
                or TargetVersion.MOJO in self.target_versions
            )
        return self.preview

    def get_cache_key(self) -> str:
        parts = [
            str(self.line_length),
            str(int(self.string_normalization)),
            str(int(self.is_pyi)),
            str(int(self.is_ipynb)),
            str(int(self.skip_source_first_line)),
            str(int(self.magic_trailing_comma)),
            str(int(self.experimental_string_processing)),
            str(int(self.preview)),
            sha256(
                (",".join(sorted(self.python_cell_magics))).encode()
            ).hexdigest(),
        ]
        return ".".join(parts)
