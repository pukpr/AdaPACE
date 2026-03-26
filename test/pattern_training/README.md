# PACE Pattern Training

This directory contains a self-contained training sequence that demonstrates all
fourteen PACE messaging patterns described in `pace.pdf`.  The patterns are
implemented in:

| File | Role |
|------|------|
| `pattern.ads` | Type declarations and subprogram specs for each pattern |
| `pattern.adb` | Pattern implementations (agents, queues, signals, …) |
| `call_patterns.adb` | Main routine that exercises patterns 1–14 in order |

## Building and Running

```bash
# Build
gprbuild -aP../.. main.gpr

# Run (PACE_RUN_TIME=20 s, debug output on)
env PACE=../.. PACE_DISPLAY_DEBUG=1 PACE_RUN_TIME=020.0 PACE_DEBUG_LEVEL=1 \
    PACE_NODE=0 ./call_patterns
```

`./call_patterns` exits **0** on success and **1** on failure, and prints a
one-line `PASS` or `FAIL` message to the log after comparing an accumulated
checksum against the expected regression value.

---

## Pattern Catalogue

### Pattern 1 — Command

**Type:** `Pattern.Command` (extends `Pace.Msg`)

The simplest pattern.  A plain message object is passed directly to the three
canonical PACE dispatch primitives:

* `Input`  — the sender delivers the command to a receiver.
* `Inout`  — the message is both consumed and updated in-place.
* `Output` — the receiver produces a result back into the message.

```ada
Msg : Pattern.Command;
Pattern.Input (Msg);
Pattern.Inout (Msg);
Pattern.Output (Msg);
```

### Pattern 1a — Dispatching Command

Same message type as Pattern 1 but dispatched through `Pace.Dispatching.Input`,
which uses Ada class-wide (tag-based) dispatch.  This decouples the caller from
the concrete type at the call site.

```ada
Pace.Dispatching.Input (Msg);   -- routes to Pattern.Input via tag
```

### Pattern 1b — Synchronized (Rendezvous) Command

**Type:** `Pattern.Synch_Command`

The `Input` procedure performs an Ada task rendezvous (`Agent.Input(Obj)`).
The caller blocks until the background `Agent` task accepts the entry.  This
provides a guaranteed handshake before both sides continue.

```ada
Pattern.Input (Msg);   -- blocks until Agent task accepts the entry
```

### Pattern 1c — Asynchronous Command

**Type:** `Pattern.Asynch_Command`

Dispatched with `Pace.Surrogates.Input`, which queues the message for delivery
by a surrogate task.  The caller returns immediately without waiting for the
receiver.

```ada
Pace.Surrogates.Input (Msg);   -- non-blocking; surrogate delivers later
```

---

### Pattern 2 — Msg_IO

**Type:** `Pattern.Msg_IO` (carries an `Integer` payload)

Uses the generic `Pace.Msg_Io` package instantiated over a connection-range
type.  `Input` calls `M_IO.Send`; the Agent task calls `M_IO.Await` with
`Wait => True` to block until the message arrives.  This is the basic
buffered-message I/O channel.

```ada
Msg.Data := 42;
Pattern.Input (Msg);          -- enqueues via M_IO.Send
-- Agent: M_IO.Await (Msg, Recv, Wait => True);
```

---

### Pattern 3 — Notify Subscription

**Type:** `Pattern.Sub` (extends `Pace.Notify.Subscription`, carries `Integer`)

Uses `Pace.Notify.Publish` / `Pace.Notify.Subscribe`.  The main task publishes
a value; any task that has called `Subscribe` receives a copy.  This is a
lightweight in-process pub/sub mechanism.

```ada
Msg.Data := 100;
Pattern.Input (Msg);          -- calls Pace.Notify.Publish
-- Agent: Pace.Notify.Subscribe (S);
```

---

### Pattern 4 — Guarded Queue

**Type:** `Pattern.GC` (carries `Integer`)

Instantiates `Pace.Queue` and `Pace.Queue.Guarded`.  The message is converted
to a `Channel_Msg` and placed on the thread-safe queue with `Q.Put`; the Agent
retrieves it with `Q.Get`.  The guard ensures mutual exclusion without explicit
locking by the caller.

```ada
Msg.Data := 200;
Pattern.Input (Msg);          -- Q.Put (To_Channel_Msg (Obj))
-- Agent: Q.Get (C_Msg);
```

---

### Pattern 5 — Signals Event

**Types:** `Pattern.Suspend`, `Pattern.Wakeup`

Uses a `Pace.Signals.Event` object (`Ev`).  The Agent calls `Ev.Suspend` to
block; the `Wakeup.Input` procedure spins until `Ev.Waiting` becomes true and
then calls `Ev.Signal`.  This is a binary semaphore-style event.

```ada
Pattern.Input (Wakeup_Msg);   -- signals Ev after Agent is suspended
-- Agent: Ev.Suspend; … Ev.Signal;
```

---

### Pattern 6 — Signals Multiple

**Types:** `Pattern.Await`, `Pattern.Signal`

Instantiates `Pace.Signals.Multiple` over an enumeration `(S1, S2)`.
`Await.Input` calls `M_Sig.Await(S1)`; `Signal.Input` calls `M_Sig.Signal(S2)`.
The Agent waits on `S2`.  Multiple independent signals can coexist in one
object.

```ada
Pattern.Input (Signal_Msg);   -- M_Sig.Signal (S2)
-- Agent: M_Sig.Await (S2);
```

---

### Pattern 7 — Signals Shared

**Type:** `Pattern.Shared_Wakeup`

Uses `Pace.Signals.Shared_Data` wrapping a shared `Shared_Wakeup` object.
`Input` calls `Shared.Write`; `Inout` or the Agent calls `Shared.Read`.
Read blocks until a new value has been written, providing a wait-free
hand-off of shared state.

```ada
Pattern.Input (Msg);          -- Shared.Write (Obj)
-- Agent: Shared.Read (Msg);
```

---

### Pattern 8 — Signals TID

**Type:** `Pattern.Task_Wakeup`

Uses `Pace.Signals.TID`.  The Agent records its `Task_ID := Pace.Current` at
startup and then calls `Pace.Signals.Tid.Wait`.  `Task_Wakeup.Input` calls
`Pace.Signals.TID.Signal(Task_ID)` to wake that specific task.  Enables
targeted per-task wakeups.

```ada
Pattern.Input (Msg);          -- Pace.Signals.TID.Signal (Task_ID)
-- Agent: Pace.Signals.Tid.Wait;
```

---

### Pattern 9 — Channel

**Type:** `Pattern.Chan`

Reuses the `Pace.Msg_Io` channel from Pattern 2 to send a typeless channel
message.  The Agent awaits it through the same `M_IO.Await` call.  This
illustrates that a single Msg_IO instance can multiplex different message
types.

```ada
Pattern.Input (Msg);          -- M_IO.Send (Obj)
-- Agent: M_IO.Await (Msg, Recv, Wait => True);
```

---

### Pattern 10 — Buffered Command

**Type:** `Pattern.Buffer` (carries `Character`)

Uses `Pace.Signals.Buffers`.  The message is converted to a `Channel_Msg` and
pushed onto `B_Queue` with `Buffers.Put`; the Agent retrieves it with
`Buffers.Get`.  An unbounded FIFO buffer decouples producer from consumer.

```ada
Msg.Char := 'A';
Pattern.Input (Msg);          -- Pace.Signals.Buffers.Put (B_Queue, Obj)
-- Agent: Pace.Signals.Buffers.Get (B_Queue, C_Msg);
```

---

### Pattern 11 — Surrogate (Asynchronous Proxy)

**Type:** `Pattern.Proxy` (carries `Integer`)

Instantiates `Pace.Surrogates.Asynchronous(Pattern.Proxy)`.  The main task
calls `Proxy_S.Surrogate.Input(Msg)`, which dispatches asynchronously to
`Pattern.Proxy.Input` in a background surrogate task.  The pattern isolates
the caller from blocking or distributed delivery.

```ada
Proxy_S.Surrogate.Input (Msg);   -- async dispatch; returns immediately
```

---

### Pattern 12 — Publish-Subscribe

**Types:** `Pattern.Status` / `Pattern.My_Status`

Uses `Pace.Socket.Publisher` with a `Subscription_List(10)`.  The Agent
subscribes `My_Status` to the list; the Agent itself later publishes
`Local_Status` values via `Publisher.Publish`.  Any subscriber whose tag
matches receives the published message, demonstrating the full pub/sub
lifecycle.

```ada
Pattern.Input (Status(Msg));  -- Publisher.Subscribe (List, Obj)
-- Agent: Publisher.Publish (List, Local_Status);
-- → routed to My_Status.Input on subscribers
```

---

### Pattern 13 — Callback Command

**Type:** `Pattern.CB` (carries a `Pace.Channel_Msg` callback)

A command that carries its own reply address.  The caller converts a
`Command` object to a callback channel message with `Pace.To_Callback` and
embeds it in the `CB` message.  `CB.Input` calls
`Pace.Dispatching.Input(+Obj.Callback)`, which dispatches back to the
original caller's `Input` procedure.

```ada
Msg.Callback := Pace.To_Callback (CB_Obj);
Pattern.Input (Msg);          -- Pace.Dispatching.Input (+Obj.Callback)
```

---

### Pattern 14 — Persistent Command

**Type:** `Pattern.Store`

Uses `Pace.Persistent`.  `Input` calls `Persistent.Put(Obj)` to store the
message and immediately reads it back with `Persistent.Get(Copy)`.  This
demonstrates durable, retrievable storage of a PACE message across the
lifetime of a session.

```ada
Pattern.Input (Msg);          -- Persistent.Put / Persistent.Get
```

---

## Checksum and PASS/FAIL

Each pattern that transfers data contributes to a running `Checksum` integer
(protected by a mutex).  After the full sequence completes, the main routine
reads the checksum via `Pattern.CS.Output` and compares it against a known
regression value:

```ada
Regression : constant Integer := 1_002_341;
Pattern.Output (Msg);
Pace.Log.Put_Line ("Checksum match" & Regression'Img & Msg.N'Img);
if Regression = Msg.N then
   Pace.Log.Put_Line ("PASS");
   Pace.Log.Os_Exit (0);
else
   Pace.Log.Put_Line ("FAIL");
   Pace.Log.Os_Exit (1);
end if;
```

A `PASS` line in the log confirms all patterns executed correctly and produced
the expected aggregate value.  A `FAIL` line indicates a regression.
