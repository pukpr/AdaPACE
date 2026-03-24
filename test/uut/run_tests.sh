# Updated run_tests.sh for modern project structure
# Removed degas dependency as requested and corrected executable path

env PACE=../../ PACE_MAX_SURROGATES=30 USING_CTDB=0 PACE_SIM=2 PACE_NODE=0 ./test_harness
