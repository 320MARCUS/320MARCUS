#!/usr/bin/env python3
"""Batch regression for the Verilog RTL lab (Icarus Verilog).

Compiles every design with its self-checking testbench, runs the
simulation, and reports PASS / FAIL per test. Exit code is non-zero
when any test fails.

Usage:
    python3 sim/run_regression.py
"""
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl"
TB = ROOT / "tb"
BUILD = ROOT / "build"

# (testbench file, RTL source files)
TESTS = [
    ("tb_counter_bin.v", ["counter_bin.v"]),
    ("tb_cnt60_bcd.v", ["cnt60_bcd.v"]),
    ("tb_modn.v", ["modn.v"]),
    ("tb_shift_sipo.v", ["shift_sipo.v"]),
    ("tb_shift_piso.v", ["shift_piso.v"]),
    ("tb_div_even.v", ["div_even.v"]),
    ("tb_fsm_det1011.v", ["fsm_det1011.v"]),
    ("tb_fsm_det1011_mealy.v", ["fsm_det1011_mealy.v"]),
]


def main() -> int:
    if shutil.which("iverilog") is None:
        print("ERROR: iverilog not found in PATH (install: apt install iverilog)")
        return 2

    BUILD.mkdir(exist_ok=True)
    results = []

    for tb_name, rtl_names in TESTS:
        vvp = BUILD / tb_name.replace(".v", ".vvp")
        cmd = ["iverilog", "-g2012", "-o", str(vvp)]
        cmd += [str(RTL / name) for name in rtl_names]
        cmd.append(str(TB / tb_name))

        comp = subprocess.run(cmd, capture_output=True, text=True)
        if comp.returncode != 0:
            tail = (comp.stderr or comp.stdout).strip().splitlines()[-2:]
            results.append((tb_name, "COMPILE-FAIL", tail))
            continue

        run = subprocess.run(["vvp", str(vvp)], capture_output=True, text=True)
        out = run.stdout + run.stderr
        notes = [l for l in out.splitlines() if l.startswith(("PASS:", "FAIL:"))]
        verdict = "PASS" if "PASS:" in out and "FAIL:" not in out else "FAIL"
        results.append((tb_name, verdict, notes))

    width = max(len(r[0]) for r in results) if results else 10
    print("=" * 64)
    print("Verilog RTL Lab - regression summary")
    print("=" * 64)
    passed = 0
    for name, verdict, notes in results:
        print(f"{name:<{width}}  {verdict}")
        for note in notes:
            print(f"    {note}")
        if verdict == "PASS":
            passed += 1
    print("-" * 64)
    print(f"result: {passed}/{len(results)} PASS")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
