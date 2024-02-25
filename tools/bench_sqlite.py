#!/usr/bin/env python3

import sqlite3
import random
import typing as t
import time

db = sqlite3.connect("bench.db")

cur = db.cursor()


def gen_random_data(k: int, n: int) -> t.List[t.List[int]]:
    return [[random.random() for col in range(k)] for row in range(n)]


def bench(k: int, n: int):
    col_spec = ", ".join([f"col{i}" for i in range(N_COLS)])
    cur.execute(f"CREATE TABLE IF NOT EXISTS data ({col_spec})")
    insert_cmd = (
        f"INSERT INTO data ({col_spec}) VALUES " f"({', '.join('?' for _ in range(k))})"
    )

    start = time.perf_counter()
    data = gen_random_data(k, n)
    stop = time.perf_counter()
    print(f"gen random data:         {stop-start:.03f}s")
    print()

    start = time.perf_counter()
    for row in data:
        cur.execute(insert_cmd, row)
    stop = time.perf_counter()
    print(f"write to db:             {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    print()

    start = time.perf_counter()
    cur.execute("SELECT * FROM data")
    stop = time.perf_counter()
    print(f"read 100% (cmd):         {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    start = time.perf_counter()
    results = cur.fetchall()
    stop = time.perf_counter()
    print(f"read 100% (fetchall):    {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    start = time.perf_counter()
    for row in results:
        if row[-1] > 1:
            print("whoops!")
    stop = time.perf_counter()
    print(f"read 100% (iter):        {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    print()

    start = time.perf_counter()
    cur.execute(f"SELECT * FROM data WHERE col{N_COLS-1} > 0.9")
    stop = time.perf_counter()
    print(f"read 10% (cmd):          {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    start = time.perf_counter()
    results = cur.fetchall()
    stop = time.perf_counter()
    print(f"read 10% (fetchall):     {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    start = time.perf_counter()
    for row in results:
        if row[-1] > 1:
            print("whoops!")
    stop = time.perf_counter()
    print(f"read 10% (iter):         {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    print()

    start = time.perf_counter()
    cur.execute(f"SELECT * FROM data WHERE col{N_COLS-1} > 0.99")
    stop = time.perf_counter()
    print(f"read 1% (cmd):           {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    start = time.perf_counter()
    results = cur.fetchall()
    stop = time.perf_counter()
    print(f"read 1% (fetchall):      {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")
    start = time.perf_counter()
    for row in results:
        if row[-1] > 1:
            print("whoops!")
    stop = time.perf_counter()
    print(f"read 1% (iter):          {stop-start:.03f}s,  {n/(stop-start):.03f} row/s")


N_COLS = 1000
N_ROWS = 10000
bench(N_COLS, N_ROWS)
