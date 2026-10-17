#!/bin/bash
# One-time install of Verilator + UVM + z3 into $EDA_TOOLS (default ~/eda_tools).
set -e

TOOLS=${EDA_TOOLS:-$HOME/eda_tools}
BUILD=${EDA_BUILD:-$TOOLS/build}
JOBS=$(sysctl -n hw.ncpu 2>/dev/null || nproc)
mkdir -p "$TOOLS/bin" "$TOOLS/uvm" "$BUILD"
export PATH=$TOOLS/bin:$PATH

gnu_build() {
  local name=$1 ver=$2
  [ -x "$TOOLS/bin/$name" ] && { echo "$name: already installed"; return; }
  cd "$BUILD"
  [ -f "$name-$ver.tar.gz" ] || curl -sSfLO "https://ftp.gnu.org/gnu/$name/$name-$ver.tar.gz"
  [ -d "$name-$ver" ] || tar xzf "$name-$ver.tar.gz"
  cd "$name-$ver"
  ./configure --prefix="$TOOLS" > /dev/null
  make -j"$JOBS" > /dev/null 2>&1
  make install > /dev/null 2>&1
  echo "$name $ver: installed"
}

# macOS ships no autoconf and a too-old bison (2.3); autoconf needs a newer m4
gnu_build m4 1.4.19
gnu_build autoconf 2.72
gnu_build bison 3.8.2

if [ ! -x "$TOOLS/bin/verilator" ]; then
  cd "$BUILD"
  [ -d verilator ] || git clone -q --depth 1 -b stable https://github.com/verilator/verilator.git
  # help2man is only needed for man pages; stub it so make doesn't fail
  mkdir -p stub
  printf '#!/bin/sh\nwhile [ $# -gt 0 ]; do [ "$1" = "-o" ] && touch "$2"; shift; done\n' > stub/help2man
  chmod +x stub/help2man
  cd verilator
  autoconf
  PATH=$BUILD/stub:$PATH ./configure --prefix="$TOOLS" > "$BUILD/verilator_configure.log" 2>&1
  PATH=$BUILD/stub:$PATH make -j"$JOBS" > "$BUILD/verilator_build.log" 2>&1
  PATH=$BUILD/stub:$PATH make install >> "$BUILD/verilator_build.log" 2>&1
  echo "verilator: installed"
else
  echo "verilator: already installed"
fi

# UVM 2020.3.2 patched for Verilator, single file, no DPI
if [ ! -f "$TOOLS/uvm/uvm_pkg_all_v2020_3_2_nodpi.svh" ]; then
  cp "$BUILD/verilator/test_regress/t/uvm/uvm_pkg_all_v2020_3_2_nodpi.svh" "$TOOLS/uvm/"
  echo "uvm: installed"
fi

# z3 = constraint solver Verilator calls for randomize()
if [ ! -x "$TOOLS/bin/z3" ]; then
  python3 -m venv "$TOOLS/z3venv"
  "$TOOLS/z3venv/bin/pip" install -q z3-solver
  ln -sf "$TOOLS/z3venv/bin/z3" "$TOOLS/bin/z3"
  echo "z3: installed"
fi

echo "done: tools in $TOOLS"
"$TOOLS/bin/verilator" --version
