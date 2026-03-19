# Real-Time 3D Robotic Arm Control with Gazebo

This example demonstrates how to use the PACE library to control a 3D robotic mechanism in real-time using the Gazebo simulator.

## Components

-   **Ada Control Agent (`arm_control.adb`)**: A real-time PACE agent that generates sinusoidal motions for a 2-joint robotic arm.
-   **Gazebo SDF (`robotic_arm.sdf`)**: Defines the physical model of the arm, consisting of a base, lower arm, upper arm, and gripper.
-   **HAL Integration**: Uses the `HAL.Gazebo_Commands` generic package to send rotation commands to specific links in the SDF model.
-   **Gazebo Plugin**: The SDF model includes `libTablePlugin.so`, which facilitates the communication between the Ada application and the Gazebo simulation engine via shared memory (Key: 123456).

## PACE Patterns Demonstrated

-   **Real-Time Tasking**: Uses an Ada task to periodically update the robot's state.
-   **Simulation Awareness**: Uses `Pace.Log.Wait` for timing, allowing the code to potentially run in discrete-event simulation mode.
-   **HAL Generic Instantiation**: Shows how to map an Ada enumeration to SDF link names via `HAL.Gazebo_Commands`.

## Building and Running

### Build
```bash
sh BUILD
```

### Run
1.  **Start Gazebo** (requires Gazebo Sim installed):
    ```bash
    gz sim robotic_arm.sdf
    ```
2.  **Run the Control Application**:
    ```bash
    sh RUN
    ```
    (Note: `RUN` simply executes `./obj/arm_control`)

Once both are running, you should see the robotic arm in Gazebo performing a continuous waving/sinusoidal motion. Type `-999` in the Ada application console to shut it down.
