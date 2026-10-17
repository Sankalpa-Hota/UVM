#!/bin/bash
# Compile once + run the UART RX UVM tests with Verilator, store logs and waveforms in results/<test>/.
# Usage: ./run.sh [test_name ...]  (default: uart_rx_tests uart_rx_err_test)
set -e
set -o pipefail

cd "$(dirname "$0")"

TESTS=${*:-"uart_rx_tests uart_rx_err_test"}
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
  "$UVM" uart_rx.sv testbench.sv 2>&1 | tee "$RESULTS/compile.log"

for TEST in $TESTS; do
  echo "== run $TEST"
  mkdir -p "$RESULTS/$TEST"
  (cd "$BUILD" && ./obj_dir/Vtb_top +UVM_TESTNAME="$TEST" +UVM_NO_RELNOTES) 2>&1 | tee "$RESULTS/$TEST/sim.log"
  mv "$BUILD/dump.vcd" "$RESULTS/$TEST/dump.vcd"
done

echo "== summary"
for TEST in $TESTS; do
  echo "-- $TEST"
  grep -E "\[SB\] (good|Test)|\[VSEQ\]|\[COV\]|UVM_ERROR :|UVM_FATAL :|Assertion" "$RESULTS/$TEST/sim.log" || true
done
echo "results: $(pwd)/$RESULTS"
