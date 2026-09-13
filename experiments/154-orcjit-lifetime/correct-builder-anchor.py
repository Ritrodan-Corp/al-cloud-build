from pathlib import Path

path = Path('experiments/154-orcjit-lifetime/build-lifetime.sh')
text = path.read_text()

old = r'''replace_once(
    '''      JITDylib* JD = ::unwrap(jd);\n      LPJit* jit = get_instance();\n      auto &ircl = jit->lljit->getIRCompileLayer();\n''',
    '''      JITDylib* JD = ::unwrap(jd);\n      LPJit* jit = get_instance();\n      alcloud_lifetime_log("LOOKUP_BEGIN", jit, jit->lljit.get(), JD, func_name);\n      auto &ircl = jit->lljit->getIRCompileLayer();\n''',
    'lookup begin')'''

new = r'''replace_once(
    '''      LPJit* jit = get_instance();\n      auto &ircl = jit->lljit->getIRCompileLayer();\n''',
    '''      LPJit* jit = get_instance();\n      alcloud_lifetime_log("LOOKUP_BEGIN", jit, jit->lljit.get(), JD, func_name);\n      auto &ircl = jit->lljit->getIRCompileLayer();\n''',
    'lookup begin')'''

if old not in text:
    raise SystemExit('expected original lookup instrumentation block not found')

path.write_text(text.replace(old, new, 1))
print('Corrected lookup instrumentation anchor in build-lifetime.sh')
