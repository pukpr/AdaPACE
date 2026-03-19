# Humanoid Walking Robot with Gazebo

This example demonstrates a humanoid robot performing a walking gait in real-time using PACE and Gazebo.

## Components

-   **Ada Walking Agent (`walk_main.adb`)**: A real-time PACE agent that implements a simplified human walking gait using sinusoidal control for various joints.
-   **Humanoid SDF (`aRobot.sdf`)**: Defines the physical model of the robot with torso, neck, head, and four limbs.
-   **HAL Integration**: Uses the `HAL.Gazebo_Commands` generic package to map the robot's links to control commands.

## SDF Preparation and Fixes

To enable the humanoid simulation, several modifications were made to the original `aRobot.sdf`:

1.  **Lower-case Link Names**: Converted all `link name` attributes and joint `child`/`parent` references to lower-case to match the PACE library's enumeration imaging (e.g., `Torso` becomes `torso`).
2.  **Disabled Static Mode**: Changed `<static>true</static>` to `<static>false</static>` to allow the model to move.
3.  **Removed Fixed World Joint**: Deleted the fixed joint that pinned the `torso` to the global origin, enabling the robot to walk freely.
4.  **Zero Gravity**: Set `<gravity>0 0 0</gravity>` to prevent the robot from accelerating downwards in the -Z direction, as it is currently controlled via direct rotation commands without explicit clamping or ground friction management.
5.  **XML Repair**: Restored the `neck` link structure which was inadvertently affected during the removal of the fixed joints.

## Walking Gait Logic

The control agent implements a cyclic gait with the following characteristics:
-   **Hip Pitch**: Alternating sinusoidal motion for left and right legs.
-   **Knee Pitch**: Synchronized bend during the swing phase.
-   **Shoulder Swing**: Arms swing out-of-phase with the hips (left arm swings with right leg).
-   **Torso Roll**: Subtle swaying to mimic balance adjustments.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
The example uses the `P4` driver to launch both Gazebo and the walking agent:
```bash
sh RUN
```

Once running, the robot in Gazebo will perform a continuous walking motion. Type `-999` in the P4 console to shut down both processes.
