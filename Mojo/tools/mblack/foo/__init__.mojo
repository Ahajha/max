# error: list comprehension must execute in runtime contexts; remove 'comptime' and move this into a function body
# comptime foo = [1 for _ in range(5)]

from std.python import PythonObject


def _make_foo() -> List[Int]:
    return [1 for _ in range(5)]


# Oh... But I think this is actually just a macro for _make_foo()? Hrm.
comptime foo = _make_foo()


def py(uh: PythonObject):
    Int(uh)
