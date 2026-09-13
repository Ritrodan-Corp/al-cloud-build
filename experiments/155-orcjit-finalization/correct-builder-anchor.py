from pathlib import Path

path = Path('experiments/155-orcjit-finalization/build-finalization.sh')
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
    "      JITDylib* JD = ::unwrap(jd);\\n      LPJit* jit = get_instance();\\n      jit->lookup_mutex.lock();\\n",
    "      JITDylib* JD = ::unwrap(jd);\\n      LPJit* jit = get_instance();\\n      alcloud_finalization_log(\\\"LOOKUP_BEGIN\\\", jit, jit->lljit.get(), JD, func_name);\\n      jit->lookup_mutex.lock();\\n",
    'lookup begin')'''

text = text[:block_start] + replacement + text[label_end:]

# Observation-channel correction only: Android application/graphics processes do
# not provide a reliable capturable stderr stream in this harness. libgallium_dri
# already links liblog, so route the existing diagnostic record to logcat without
# changing any event placement, JIT ownership, teardown, synchronization, or
# pointer access performed by the Experiment 155 instrumentation.
include_old = '#include <unistd.h>'
include_new = '#include <unistd.h>\\n#include <android/log.h>'
if text.count(include_old) != 1:
    raise SystemExit(f'unexpected unistd include anchor count: {text.count(include_old)}')
text = text.replace(include_old, include_new, 1)

sink_old = '(void)write(STDERR_FILENO, buffer, size);'
sink_new = '(void)__android_log_write(ANDROID_LOG_INFO, "ALCLOUD_ORC_FINALIZATION", buffer);'
if text.count(sink_old) != 1:
    raise SystemExit(f'unexpected stderr sink anchor count: {text.count(sink_old)}')
text = text.replace(sink_old, sink_new, 1)

path.write_text(text)
print('Corrected lookup instrumentation anchor and routed finalization markers to Android logcat')
