#!/bin/sh
test -z "$1" -o -z "$2" && {
  echo "Syntax: $0 [-g|-c] queue-dir cmd"
  echo
  echo "this generates the coverage information."
  echo "must be run in the top source code directory"
  echo "Specify -g if gcc/g++ was used to compile the target"
  echo "Specify -c if clang/clang++ was used to compile the target (default)"
  echo "qeueu-dir - queue directory of libfuzzer"
  echo "cmd - the cov command compiled with cov-compile.sh"
  exit 1
}

CLANG=yes
echo " $CC $CXX" | grep -q clang && CLANG=yes
test "$1" = "-g" && { CLANG= ; shift ; }
test "$1" = "-c" && { CLANG=yes ; shift ; }
test "$1" = "-g" && { CLANG= ; shift ; }

test -d "$1" || { echo Error: directory $1 does not exist; exit 1; }
test -x "$2" || { echo Error: $2 is not an executable; exit 1; }

OPT=
test -n "$CLANG" && OPT="--gcov-tool $PWD/cov-clang.sh"

DIR=`dirname $0`
test -n "$DIR" && export PATH=$PATH:$DIR

mkdir report 2> /dev/null
lcov $OPT --no-checksum --ignore-errors inconsistent,unsupported --zerocounters --directory . || exit
lcov $OPT --no-checksum --ignore-errors inconsistent,unsupported --capture --initial --directory . --output-file report/trace.lcov_base || exit 1
"$2" "$1"/*
lcov $OPT --no-checksum --ignore-errors inconsistent,unsupported --capture --directory . --output-file report/trace.lcov_info || exit 1
lcov $OPT --no-checksum --ignore-errors inconsistent,unsupported -a report/trace.lcov_base -a report/trace.lcov_info --output-file report/trace.lcov_tmp || exit 1
lcov $OPT --no-checksum --ignore-errors inconsistent,unsupported -r report/trace.lcov_tmp /usr/include/\*  --output-file report/trace.lcov_info_final || exit 1
genhtml --ignore-errors source,format --output-directory report report/trace.lcov_info_final
echo
echo Report: `pwd`/report/index.html
