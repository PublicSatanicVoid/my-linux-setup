# Test file to quickly test LSP functionality in NeoVim

import os
import sys

sys.path.append("/tmp")

import functools


def foo(x, y):
    """return x + y"""
    return x + y


def foobar(x, y):
    """don't return x + y"""
    return None


def baz(x, y, z):
    return None


try:
    x = 5
    y = 3
    z = 12
except:
    pass

q = enumerate([10, 20, 30])


### Test cases for string reflow macro

s1 = "another very long string foo bar baz qux quux the quick brown fox jumps over the lazy dog sally sells seashells by the seashore"

baz(
    "a",
    "another very long string foo bar baz qux quux the quick brown fox jumps over the lazy dog sally sells seashells by the seashore",
    "b",
)

print(
    "another very long string foo bar baz qux quux the quick brown fox jumps over the lazy dog sally sells seashells by the seashore"
)

s2 = "another very long string foo bar baz qux quux the quick brown fox jumps over the lazy dog sally sells seashells by the seashore do it just do it dont let your dreams be dreams yesterday you said tomorrow so just do it"

s3 = "abc"

s4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa = (
    "abcdefghi"
)

s5 = f"another very long string foo bar baz qux quux the quick {12345678901234567} brown fox jumps over the lazy dog sally sells seashells by the seashore"

s6 = f"another very long string foo bar baz qux quux the quick {123456789012345678901234567890} brown fox jumps over the lazy dog sally sells seashells by the seashore"


### Test case for auto indent

p = "("


### Test case for pinned context lines while scrolling


def bigfunction():
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 3
    x = 3
    x = 1
    x = 2
    x = 3
    x = 1
    x = 2
    x = 1
    x = 2
    x = 3
    x = 3
