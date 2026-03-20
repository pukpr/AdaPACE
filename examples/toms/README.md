# TOMS (Total Object Messaging System) Example

This example demonstrates the **Publish/Subscribe** pattern in PACE, specifically focusing on status updates across multiple distributed agents.

## Components

- **Status_Publisher**: A centralized service that manages the distribution of status messages.
- **Publisher_1**: An agent that generates status updates.
- **Subscriber_1 & Subscriber_2**: Agents that subscribe to and receive status updates from the publisher.

## PACE Patterns Demonstrated

- **Publish/Subscribe**: Demonstrates how `Pace.Notify` or custom publishing logic can be used to broadcast state changes to multiple listeners.
- **Distributed Agents**: Shows multiple processes (managed via `session.pro`) interacting over the network.

## Building and Running

The example uses a `session.pro` file to orchestrate the launch of the publisher and multiple subscriber nodes.
