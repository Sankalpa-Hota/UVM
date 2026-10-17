#!/bin/bash
# Compile + run the async FIFO UVM test with Verilator, store logs and waveform in results/.
# Usage: ./run.sh [test_name]      (default: async_fifo_tests)
set -e
set -o pipefail

cd "$(dirname "$0")"

TEST=${1:-async_fifo_tests}
TOOLS=${EDA_TOOLS:-$HOME/eda_tools}
UVM=$TOOLS/uvm/uvm_pkg_all_v2020_3_2_nodpi.svh
BUILD=build
RESULTS=results
export PATH=$TOOLS/bin:$PATH

for need in "$TOOLS/bin/verilator" "$TOOLS/bin/z3" "$UVM"; do
  [ -e "$need" ] || { echo "missing $need - run ../ADDER/setup_tools.sh first"; exit 1; }
done

rm -rf "$BUILD"
mkdir -p "$BUILD" "$RESULTS"

# this UVM build defines its macros inside the package file, so uvm_macros.svh is an empty stub
echo "// macros come from $(basename "$UVM")" > "$BUILD/uvm_macros.svh"

echo "== compile"
verilator --binary --timing --assert --trace -j 0 --CFLAGS -O0 \
  -Wno-fatal -Wno-lint -Wno-style \
  --top-module tb_top -Mdir "$BUILD/obj_dir" \
  +incdir+"$BUILD" +incdir+. \
  "$UVM" async_fifo.sv testbench.sv 2>&1 | tee "$RESULTS/compile.log"

echo "== run $TEST"
(cd "$BUILD" && ./obj_dir/Vtb_top +UVM_TESTNAME="$TEST" +UVM_NO_RELNOTES) 2>&1 | tee "$RESULTS/sim.log"

mv "$BUILD/dump.vcd" "$RESULTS/dump.vcd"

echo "== summary"
grep -E "\[SB\]|\[COV\]|UVM_ERROR :|UVM_FATAL :|Assertion" "$RESULTS/sim.log" || true
echo "results: $(pwd)/$RESULTS (compile.log, sim.log, dump.vcd)"
