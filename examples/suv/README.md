# SUV Control Simulation

This example demonstrates a vehicle control system for an SUV, utilizing the Singleton and Command patterns within the PACE library.

## Architecture

- **Suv.Controller**: A singleton agent that manages the overall control flow of the vehicle.
- **Suv.Gyrator**: A component that simulates the mechanical orientation and motion of the SUV.
- **Suv.Assembly**: Manages the integration of various vehicle components.

## PACE Patterns Demonstrated

- **Singleton Object**: Each major vehicle system is represented as a singly-instantiated Ada package.
- **Command Pattern**: Discrete control actions (like `Start_Control`) are defined as messages derived from `Pace.Msg`.
- **Active Objects**: The simulation uses internal tasks to model concurrent physical processes.

## Building and Running

The project can be built using the provided GNAT project file `suv.gpr`.
