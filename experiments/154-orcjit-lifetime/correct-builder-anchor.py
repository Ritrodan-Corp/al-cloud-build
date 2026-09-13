from pathlib import Path

path = Path('experiments/154-orcjit-lifetime/build-lifetime.sh')
text = path.read_text()

label = "    'lookup begin')"
label_end = text.find(label)
if label_end < 0:
    raise SystemExit('lookup instrumentation label not found')
label_end += len(label)
block_start = text.rfind('replace_once(', 0, label_end)
if block_start < 0:
    raise SystemExit('lookup replace_once block start not found')

replacement = '''replace_once(
    "      LPJit* jit = get_instance();\\n      auto &ircl = jit->lljit->getIRCompileLayer();\\n",
    "      LPJit* jit = get_instance();\\n      alcloud_lifetime_log(\\\"LOOKUP_BEGIN\\\", jit, jit->lljit.get(), JD, func_name);\\n      auto &ircl = jit->lljit->getIRCompileLayer();\\n",
    'lookup begin')'''

text = text[:block_start] + replacement + text[label_end:]
path.write_text(text)
print('Corrected lookup instrumentation anchor in build-lifetime.sh')
