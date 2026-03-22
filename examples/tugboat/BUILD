#!/usr/bin/env bash
# BUILD -- compile the Tugbot simulation
# Follows the same pattern as joint_position_controller/BUILD and HumanRobot/BUILD

gprbuild -aP../.. tugboat.gpr

# Clear any stale shared memory segment (Key: 123456) left from a previous run
ipcrm -M 123456 2>/dev/null
