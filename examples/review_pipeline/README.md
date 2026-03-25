# Review Pipeline Example

This example implements a **Composer → Checker → Critic** agent coordination
pipeline in a single executable, using local (`Pace.Dispatching.Input`) dispatch
throughout.  It demonstrates the following typed agent-coordination logic:

```
type Verdict = { verdict: bool, commentary: string, draft: string }
type Review  = { score: int,  review: string,  draft: string }

let composer : !string  -> !string  = agent { ... }
let checker  : !string  -> !Verdict = agent { ... }
let critic   : !Verdict -> !Review  = agent { ... }

let main : !string -> !string = plumb(input, output) {
  input   ; composer ; checker
  checker ; filter(verdict = false)
          ; map({verdict, commentary}) ; composer
  checker ; filter(verdict = true) ; critic
  critic  ; filter(score < 85)
          ; map({score, review}) ; composer
  critic  ; filter(score >= 85).draft ; output
}
```

## Architecture

```
main.adb
  |
  | Pace.Dispatching.Input(Request)
  v
Review_Pipeline          <-- routing hub (review_pipeline.adb)
  |  Input(Request) --> Composer.Handle --> [task Agent]
  |  Input(Draft)   --> Checker.Handle  --> [task Agent]
  |  Input(Verdict) --> Critic.Handle   --> [task Agent]
  |
  +-- Pipeline_Output.Collect  (main blocks here until score >= 85)
```

The three agents run as Ada task singletons.  All message types (`Request`,
`Draft`, `Verdict`) are declared in the root `Review_Pipeline` package so that:

* agent specs each carry only a single `with Review_Pipeline;` — no
  cross-agent `with` statements appear in any spec;
* `review_pipeline.adb` is the **only** unit that `with`-s all three agents,
  acting as the sole routing hub.

This fully eliminates circular `with` dependencies while following the
pace.pdf **Elaboration Order Pattern**:

> *"Add `pragma Elaborate_Body;` in every package specification …*
> *Avoid placing `with`-dependencies in package spec."*

## Pipeline Walkthrough (simulated)

| Iteration | Agent    | Action                                            |
|-----------|----------|---------------------------------------------------|
| 0         | Composer | Produces draft v0                                 |
| 0         | Checker  | Verdict **false** — too brief → feedback to Composer |
| 1         | Composer | Produces draft v1 (expanded)                      |
| 1         | Checker  | Verdict **true** → forwards to Critic             |
| 1         | Critic   | Score **70** — needs work → feedback to Composer  |
| 2         | Composer | Produces draft v2 (polished)                      |
| 2         | Checker  | Verdict **true** → forwards to Critic             |
| 2         | Critic   | Score **85** — approved → publishes draft to output |

## PACE Patterns Demonstrated

| Pattern              | Where used                                         |
|----------------------|----------------------------------------------------|
| **Singleton / Agent**    | `task Agent` in each agent body                |
| **Elaboration Order**    | `pragma Elaborate_Body` in every spec; no cross-agent `with` in specs |
| **Command / Dispatch**   | `Pace.Dispatching.Input` for all routing       |
| **Rendezvous**           | Short `accept` sections — caller unblocked immediately after copy |
| **Execute-Once / Protected** | `Pipeline_Output` — blocks main until Critic approves |

## Building and Running

```bash
# Build
sh BUILD

# Run (single executable)
sh RUN
```

## Extending to Distributed Execution

To distribute across nodes later, replace `Pace.Dispatching.Input` calls in
the agent bodies with `Pace.Socket.Send`, add a `nodes.pro` routing table, and
a `session.pro` multi-node topology — the agent and message-type structure
requires no changes.
