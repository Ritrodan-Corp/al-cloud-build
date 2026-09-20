#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

request_path, variant_id, target_path, provenance_path = sys.argv[1:5]
request = json.loads(Path(request_path).read_text())
variants = {v["id"]: v for v in request.get("variants", [])}
assert variant_id in variants, f"unknown variant: {variant_id}"

allowed = {
    "SCCP": "createSCCPPass",
    "SimplifyCFG": "createCFGSimplificationPass",
    "EarlyCSE": "createEarlyCSEPass",
    "ADCE": "createAggressiveDCEPass",
    "DSE": "createDeadStoreEliminationPass",
}
passes = variants[variant_id].get("passes", [])
assert isinstance(passes, list) and len(passes) <= 8
assert all(p in allowed for p in passes), passes
assert re.fullmatch(r"[A-Za-z0-9._-]+", variant_id)

path = Path(target_path)
text = path.read_text()

old = r'''\t\tpassManager.add(llvm::createSROAPass());
\t\tpassManager.add(llvm::createSCCPPass());
\t\tpassManager.add(llvm::createCFGSimplificationPass());
\t\tpassManager.add(llvm::createEarlyCSEPass());
\t\tpassManager.add(llvm::createCFGSimplificationPass());
\t\tpassManager.add(llvm::createInstructionCombiningPass());'''

factories = ["createSROAPass", *(allowed[p] for p in passes),
             "createInstructionCombiningPass"]
new = "\n".join(
    r"\t\tpassManager.add(llvm::%s());" % factory
    for factory in factories
)
assert text.count(old) == 1, "expected exactly one validated full-cleanup template"
text = text.replace(old, new, 1)

old_checks = """    grep -Fq 'int optimizationLevel = 2;  // Default' external/swiftshader/src/Reactor/Pragma.cpp
    grep -Fq 'passManager.add(llvm::createSCCPPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'passManager.add(llvm::createEarlyCSEPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp
    test "$(grep -c 'passManager.add(llvm::createCFGSimplificationPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq 2
    VARIANT_DESC='AOT Neoverse-N1 plus historical SwiftShader Vulkan LLVM10 IR cleanup: SROA/SCCP/SimplifyCFG/EarlyCSE/SimplifyCFG/InstCombine; backend Default'
"""

counts = {name: passes.count(name) for name in allowed}
chain = ["SROA", *passes, "InstCombine"]
chain_text = " -> ".join(chain)

new_checks = f"""    grep -Fq 'int optimizationLevel = 2;  // Default' external/swiftshader/src/Reactor/Pragma.cpp
    test "$(grep -c 'passManager.add(llvm::createSCCPPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {counts['SCCP']}
    test "$(grep -c 'passManager.add(llvm::createEarlyCSEPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {counts['EarlyCSE']}
    test "$(grep -c 'passManager.add(llvm::createCFGSimplificationPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {counts['SimplifyCFG']}
    test "$(grep -c 'passManager.add(llvm::createAggressiveDCEPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {counts['ADCE']}
    test "$(grep -c 'passManager.add(llvm::createDeadStoreEliminationPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {counts['DSE']}
    VARIANT_DESC='AOT Neoverse-N1 delegated Reactor IR variant {variant_id}: {chain_text}; backend Default'
"""
assert text.count(old_checks) == 1, "expected exactly one full-cleanup validation block"
text = text.replace(old_checks, new_checks, 1)

path.write_text(text)
Path(provenance_path).write_text(chain_text + "\n")
print(f"{variant_id}: {chain_text}")
