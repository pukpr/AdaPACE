# PACE Scripts

This directory contains utility scripts for processing and visualizing PACE simulation data.

## Trace Visualization (`trace_viz.py`)

A Python-based replacement for the original Shell/AWK/DOT pipeline. It converts a PACE trace file into a directed graph visualizing process interactions.

### Features
- Support for multiple output formats (PDF, PNG, SVG, DOT).
- Color-coded edges based on message type:
  - **Black**: Synchronized (`>>`)
  - **Red**: Asynchronous (`->`)
  - **Blue**: Simple (`=>`)
  - **Green**: Blocking (`<>`)
- Automatic node formatting (replaces `.` with `:` and `_` with newlines).
- Optional direct display using system viewers.

### Requirements
- **Graphviz**: The `dot` command must be in your system path.

### Usage

```bash
# Generate a PDF (default)
./scripts/trace_viz.py examples/delivery_vehicle/trace.out

# Generate a PNG and display it immediately
./scripts/trace_viz.py examples/delivery_vehicle/trace.out -f png -d

# Custom output file and landscape orientation
./scripts/trace_viz.py examples/delivery_vehicle/trace.out -o my_trace.pdf -l
```

### Command Line Options
- `input`: Path to the `trace.out` file.
- `-o`, `--output`: Output file path.
- `-f`, `--format`: Output format (`pdf`, `png`, `svg`, `dot`).
- `-l`, `--landscape`: Use landscape orientation.
- `-d`, `--display`: Open the generated file with the default system viewer.
