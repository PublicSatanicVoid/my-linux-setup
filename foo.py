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


try:
    x = 5
    y = 3
    z = 12
except:
    pass


x = 1
y = 2
z = foo(x, y)
