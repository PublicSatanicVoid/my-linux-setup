#!/usr/bin/env python3

import sqlite3
import random
import typing as t
import time
import multiprocessing as mp
import threading
import os

def gen_random_data(k: int, n: int) -> t.List[t.List[int]]:
    return [[random.random() for col in range(k)] for row in range(n)]


print_lock = mp.RLock()


def safe_print(*args, **kwargs):
    with print_lock:
        print(f"{os.getpid()}:", *args, **(kwargs | {"flush": True}))


def bench(
    k: int,
    n: int,
    start_barrier: threading.Barrier,
    write_barrier: threading.Barrier,
    read10_barrier: threading.Barrier,
    read1_barrier: threading.Barrier,
):
    db = sqlite3.connect("bench.db", isolation_level="IMMEDIATE")
    while True:
        try:
            db.execute("PRAGMA journal_mode = 'WAL'")
        except sqlite3.OperationalError:
            # print("OOF")
            pass
        else:
            break
    # db.execute("PRAGMA synchronous = 1")
    # db.execute("PRAGMA cache_size = -64000")

    cur = db.cursor()

    col_spec = ", ".join([f"col{i}" for i in range(N_COLS)])
    cur.execute(f"CREATE TABLE IF NOT EXISTS data ({col_spec})")
    insert_cmd = (
        f"INSERT INTO data ({col_spec}) VALUES " f"({', '.join('?' for _ in range(k))})"
    )

    start = time.perf_counter()
    data = gen_random_data(k, n)
    stop = time.perf_counter()
    safe_print(f"gen random data:         {stop-start:.03f}s")

    start_barrier.wait()

    start = time.perf_counter()
    for row in data:
        for _ in range(10):
            try:
                cur.execute(insert_cmd, row)
            except sqlite3.OperationalError:
                # print("OOF")
                pass
            else:
                break
    db.commit()
    stop = time.perf_counter()
    safe_print(
        f"write to db:             {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )

    write_barrier.wait()

    start = time.perf_counter()
    cur.execute(f"SELECT * FROM data WHERE col{N_COLS-1} > 0.9")
    stop = time.perf_counter()
    safe_print(
        f"read 10% (cmd):          {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )
    start = time.perf_counter()
    results = cur.fetchall()
    stop = time.perf_counter()
    safe_print(
        f"read 10% (fetchall):     {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )
    start = time.perf_counter()
    for row in results:
        if row[-1] > 1:
            safe_print("whoops!")
    stop = time.perf_counter()
    safe_print(
        f"read 10% (iter):         {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )

    read10_barrier.wait()

    start = time.perf_counter()
    cur.execute(f"SELECT * FROM data WHERE col{N_COLS-1} > 0.99")
    stop = time.perf_counter()
    safe_print(
        f"read 1% (cmd):           {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )
    start = time.perf_counter()
    results = cur.fetchall()
    stop = time.perf_counter()
    safe_print(
        f"read 1% (fetchall):      {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )
    start = time.perf_counter()
    for row in results:
        if row[-1] > 1:
            safe_print("whoops!")
    stop = time.perf_counter()
    safe_print(
        f"read 1% (iter):          {stop-start:.03f}s,  {n/(stop-start):.03f} row/s"
    )

    read1_barrier.wait()


N_PROC = 12
N_COLS = 10
N_ROWS = int(10_000_000 / N_PROC)

start_barrier, write_barrier, read10_barrier, read1_barrier = (
    mp.Barrier(N_PROC),
    mp.Barrier(N_PROC),
    mp.Barrier(N_PROC),
    mp.Barrier(N_PROC),
)


def worker():
    bench(
        N_COLS,
        N_ROWS,
        start_barrier,
        write_barrier,
        read10_barrier,
        read1_barrier,
    )


workers = [mp.Process(target=worker) for _ in range(N_PROC)]
[worker.start() for worker in workers]
[worker.join() for worker in workers]
