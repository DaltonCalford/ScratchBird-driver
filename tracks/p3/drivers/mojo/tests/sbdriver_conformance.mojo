# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

from python import Python


fn main() raises:
    var os = Python.import_module("os")
    var runpy = Python.import_module("runpy")
    var candidates = Python.list()
    _ = candidates.append("tests/sbdriver_conformance.py")
    _ = candidates.append("sbdriver_conformance.py")
    _ = candidates.append("tracks/p3/drivers/mojo/tests/sbdriver_conformance.py")
    for path in candidates:
        if os.path.exists(path):
            _ = runpy.run_path(path, run_name="__main__")
            return
    raise Error("sbdriver_conformance.py not found; run from mojo lane root or tests directory")
