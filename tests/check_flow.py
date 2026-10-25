"""Simulate one full episode of the server script on stand-in engine objects."""
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
def lua_string(text):
    assert ']=====]' not in text
    return '[=====[' + text + ']=====]'
shared = {p.stem: p.read_text() for p in (root / 'src/shared').glob('*.luau')}
server = {p.stem: p.read_text() for p in (root / 'src/server').glob('*.luau') if p.name != 'init.server.luau'}
main = (root / 'src/server/init.server.luau').read_text()
client = {('init' if p.name == 'init.client.luau' else p.stem): p.read_text() for p in (root / 'src/client').glob('*.luau')}
def table(mapping):
    return '{' + ','.join('[' + repr(k).replace("'", '"') + ']=' + lua_string(v) for k, v in mapping.items()) + '}'
harness = (root / 'tests/flow.luau').read_text()
with tempfile.TemporaryDirectory() as directory:
    script = Path(directory) / 'flow.luau'
    script.write_text('local run = (function()\n' + harness + '\nend)()\nrun({ shared = ' + table(shared) + ', server = ' + table(server) + ', client = ' + table(client) + ', main = ' + lua_string(main) + ' })\n')
    subprocess.run([os.environ.get('LUAU_BIN', 'luau'), str(script)], check=True)
