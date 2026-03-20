# Humanoid Walking Robot with Gazebo

This example demonstrates a humanoid robot performing a walking gait in real-time using PACE and Gazebo.

## Components

-   **Ada Multi-Tasking Controller (`walk_main.adb`)**: A real-time PACE agent split into three specialized tasks for coordinated motion.
-   **Humanoid SDF (`aRobot.sdf`)**: Defines the physical model of the robot with torso, neck, head, and four limbs.
-   **HAL Integration**: Uses the `HAL.Gazebo_Commands` generic package to map the robot's links to control commands.

## Multi-Tasking Controller Architecture

The control logic is partitioned into three concurrent Ada tasks:

1.  **Gait_Controller**: Manages the lower body, including hip pitch/roll, knee pitch, and ankle pitch. It implements the primary walking rhythm.
2.  **Arm_Controller**: Orchestrates the upper body limb motion, ensuring arm swings are synchronized (out-of-phase) with the legs for natural motion.
3.  **Posture_Controller**: Handles "micro-motions" such as torso sway, neck stabilization, and head orientation.

## Global Motion Scaling

The constant `Vel_Mult` in `walk_main.adb` serves as a global velocity multiplier.
-   **Unity (1.0)**: Standard human walking speed.
-   **Values > 1.0**: Increases step frequency and overall motion speed.
-   **Values < 1.0**: Slow-motion playback.

## SDF Preparation and Fixes

To enable the humanoid simulation, several modifications were made to the original `aRobot.sdf`:

1.  **Lower-case Link Names**: Converted all `link name` attributes and joint `child`/`parent` references to lower-case.
2.  **Disabled Static Mode**: Changed `<static>true</static>` to `<static>false</static>`.
3.  **Removed Fixed World Joint**: Deleted the fixed joint that pinned the `torso` to the global origin.
4.  **Zero Gravity**: Set `<gravity>0 0 0</gravity>` to prevent uncontrolled Z-axis acceleration.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
```bash
sh RUN
```

Once running, the robot in Gazebo will perform a continuous walking motion. Type `-999` in the P4 console to shut down both processes.




https://github.com/user-attachments/assets/94e5f864-fd3c-449f-a605-af552ce06fcd

*what Gemini generated after prompting for a typical human-like gate*

