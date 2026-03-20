# Panda Robot Joint Position Control with Gazebo

This example demonstrates how to control a Franka Emika Panda robot model in Gazebo using PACE and the Joint control API.

## Components

-   **Ada Panda Controller (`panda_control.adb`)**: A real-time PACE agent that exercises the 7 arm joints and 2 gripper finger joints of the Panda robot.
-   **Gazebo SDF (`jpc.sdf`)**: Includes the Panda model from Open Robotics Fuel and attaches the `libTablePlugin.so`.
-   **HAL Integration**: Uses the `HAL.Gazebo_Commands` generic package to map joint names to position commands.

## Control Logic

The controller implements:
-   **Sinusoidal Motion**: Each of the 7 arm joints moves in a sinusoidal pattern with varying frequencies.
-   **Gripper Cycle**: The two finger joints open and close periodically.
-   **Joint Position API**: Uses the enhanced `Set_Pose` command in the Gazebo plugin which now maps to `JointPosition` for entities identified as joints.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
The example uses the `P4` driver to launch both Gazebo and the Ada controller:
```bash
sh RUN
```

Once running, you should see the Panda robot in Gazebo moving its arm joints and opening/closing its gripper. Type `-999` in the P4 console to shut down both processes.


https://github.com/user-attachments/assets/6590e3e4-d3c2-4993-87bc-0b9b57978583

*what Gemini generated*


https://github.com/user-attachments/assets/4e2bb8cc-a83b-4e34-b099-41f48b6831ff

