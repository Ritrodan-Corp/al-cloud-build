#!/usr/bin/env python3
import sys
from pathlib import Path

variant, filename = sys.argv[1:]
path = Path(filename)
text = path.read_text()

old = r'''\t\tpassManager.add(llvm::createSROAPass());
\t\tpassManager.add(llvm::createSCCPPass());
\t\tpassManager.add(llvm::createCFGSimplificationPass());
\t\tpassManager.add(llvm::createEarlyCSEPass());
\t\tpassManager.add(llvm::createCFGSimplificationPass());
\t\tpassManager.add(llvm::createInstructionCombiningPass());'''

chains = {
    "e": ["createEarlyCSEPass"],
    "se": ["createSCCPPass", "createEarlyCSEPass"],
    "ce": ["createCFGSimplificationPass", "createEarlyCSEPass"],
    "sce": ["createSCCPPass", "createCFGSimplificationPass", "createEarlyCSEPass"],
}
human = {
    "createSROAPass": "SROA",
    "createSCCPPass": "SCCP",
    "createCFGSimplificationPass": "SimplifyCFG",
    "createEarlyCSEPass": "EarlyCSE",
    "createInstructionCombiningPass": "InstCombine",
}

assert variant in chains
passes = ["createSROAPass", *chains[variant], "createInstructionCombiningPass"]
new = "\n".join(
    r"\t\tpassManager.add(llvm::%s());" % p
    for p in passes
)
assert text.count(old) == 1, "expected exactly one full-cleanup pass template"
text = text.replace(old, new, 1)

old_checks = """    grep -Fq 'int optimizationLevel = 2;  // Default' external/swiftshader/src/Reactor/Pragma.cpp
    grep -Fq 'passManager.add(llvm::createSCCPPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'passManager.add(llvm::createEarlyCSEPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp
    test "$(grep -c 'passManager.add(llvm::createCFGSimplificationPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq 2
    VARIANT_DESC='AOT Neoverse-N1 plus historical SwiftShader Vulkan LLVM10 IR cleanup: SROA/SCCP/SimplifyCFG/EarlyCSE/SimplifyCFG/InstCombine; backend Default'
"""

mid = chains[variant]
sccp_count = sum(p == "createSCCPPass" for p in mid)
early_count = sum(p == "createEarlyCSEPass" for p in mid)
cfg_count = sum(p == "createCFGSimplificationPass" for p in mid)
chain_text = " -> ".join(human[p] for p in passes)

new_checks = f"""    grep -Fq 'int optimizationLevel = 2;  // Default' external/swiftshader/src/Reactor/Pragma.cpp
    test "$(grep -c 'passManager.add(llvm::createSCCPPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {sccp_count}
    test "$(grep -c 'passManager.add(llvm::createEarlyCSEPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {early_count}
    test "$(grep -c 'passManager.add(llvm::createCFGSimplificationPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq {cfg_count}
    VARIANT_DESC='AOT Neoverse-N1 Reactor IR ablation {variant}: {chain_text}; backend Default'
"""
assert text.count(old_checks) == 1, "expected exactly one full-cleanup validation block"
text = text.replace(old_checks, new_checks, 1)

path.write_text(text)
print(f"{variant}: {chain_text}")
