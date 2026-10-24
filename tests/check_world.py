"""Run placement/collision checks without claiming to emulate Roblox physics."""
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
harness = (root / 'tests/world.luau').read_text()
source = (root / 'src/server/World.luau').read_text()
assert ']====]' not in source
with tempfile.TemporaryDirectory() as directory:
    script = Path(directory) / 'check.luau'
    script.write_text('local run = (function()\n' + harness + '\nend)()\nrun([====[' + source + ']====])\n')
    subprocess.run([os.environ.get('LUAU_BIN', 'luau'), str(script)], check=True)
