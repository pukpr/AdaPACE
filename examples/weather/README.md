*Fetches NWS current observation XML via `Pace.Tcp.Http.Get` (plain HTTP, port 80); falls back to `curl` over HTTPS when the server redirects.*

# Weather Reporting Agent

A PACE example that fetches current weather data from the National Weather
Service (NWS) and stores it as Prolog functors in a GKB knowledge base that
can then be queried by a PACE program.

## What it demonstrates

| PACE feature | Where used |
|---|---|
| `Pace.Tcp.Http.Get` | Primary fetch of raw XML from the NWS HTTP endpoint |
| `Gnu.Pipe_Commands` + `curl` | HTTPS fallback when the HTTP response is empty |
| `Pace.Xml_Tree.Search_Xml` | Extracts individual leaf values from the XML |
| `Pace.Server.Kbase_Utilities.Xml_To_Kbase` | Converts the full XML tree to a nested Prolog functor (PACE XML-to-KBASE) |
| `Pace.Rule_Process.Agent_Type.Assert` | Asserts flat single-argument facts for easy rule matching |
| `Pace.Rule_Process.Agent_Type.Query` | Executes Prolog rules defined in `weather.pro` |
| Generic `Gkb` package (`wkb.ads`) | Knowledge-base instance wrapping the Prolog agent |
| WMI / `Uio.Server` (`Wmi.Create`) | Starts the PACE server; triggers GKB elaboration |

## Architecture

```
NWS endpoint                PACE program
forecast.weather.gov:80 ──► Pace.Tcp.Http.Get
                             (Host: + User-Agent: headers included)
        │
        │  empty (301 redirect to HTTPS)?
        │  yes ──► Gnu.Pipe_Commands: curl -sf https://...
        │
        │  raw XML string
        ▼
Pace.Server.Kbase_Utilities.Xml_To_Kbase          ← PACE XML-to-KBASE
        │
        │  asserta(weather_obs(current_observations(...)))
        ▼
Wkb.Agent  (Prolog engine)
        │
        │  Pace.Xml_Tree.Search_Xml per field
        │  Agent.Assert("station_id('KDAG')")  …
        ▼
weather.pro rules
        │
        │  weather_report(Station, Condition, TempF, Humidity, Wind)
        ▼
Prolog query result ──► Pace.Log.Put_Line (printed to console)
```

### NWS observation XML

The XML feed for station KDAG (Death Valley National Park, CA) is served at:

```
https://forecast.weather.gov/xml/current_obs/KDAG.xml
```

The program first tries the plain-HTTP URL on port 80.  If the server
returns an empty response (e.g. a 301 redirect to HTTPS), it retries
automatically using `curl` with the `https://` URL.

Replace `KDAG` with any NWS four-character ICAO station identifier.  A full
list of stations and their XML URLs is available at:
<https://w1.weather.gov/xml/current_obs/>

> **Note:** `curl` must be installed on the host system for the HTTPS
> fallback to succeed.  The PACE TCP client (`Pace.Tcp.Http.Get`) does not
> support TLS.

### XML-to-KBASE conversion

`Pace.Server.Kbase_Utilities.Xml_To_Kbase` performs the PACE XML-to-KBASE
conversion.  Internally it:

1. Strips XML processing instructions (`<?...?>`) using `Pace.Server.Html.Template`.
2. Parses the XML document into a `Pace.Xml_Tree.Kbase.Kb_Fact` tree.
3. Traverses the tree with `Search`, calling `Callback` for each node to
   accumulate a hierarchical Prolog term string.
4. Asserts the resulting term:
   ```prolog
   weather_obs(current_observations(
       station_id('KDAG'),
       weather('Fair'),
       temp_f('73.0'),
       ...))
   ```
   via `Agent.Parse("asserta(weather_obs(...))")`.

This is equivalent to the HTTP dispatch action:
```
Wmi.Call("wkb.assert_xml",
         Wmi.P("set", Xml) + Wmi.P("functor", "weather_obs"))
```

### Flat Prolog facts

To make the data easy to query with simple Prolog rules, the program also
asserts individual facts using `Pace.Xml_Tree.Search_Xml`:

```prolog
station_id('KDAG')
obs_condition('Fair')
obs_temp_f('73.0')
obs_temp_c('22.8')
obs_humidity('13')
obs_wind('CALM')
obs_pressure_mb('989.2')
obs_visibility('10.00')
obs_dewpoint_f('30.9')
obs_obs_time('Last Updated on ...')
obs_location('Death Valley, Death Valley National Park Airport, CA')
```

### Prolog rules (`kbase/weather.pro`)

```prolog
weather_report(Station, Condition, TempF, Humidity, Wind) :-
    station_id(Station),
    obs_condition(Condition),
    obs_temp_f(TempF),
    obs_humidity(Humidity),
    obs_wind(Wind).
```

## Files

| File | Description |
|---|---|
| `weather_main.adb` | Main Ada program (fetch → convert → assert → query) |
| `wkb.ads` | Generic GKB instantiation for weather observation data |
| `weather.gpr` | GNAT project file |
| `BUILD` | Build script |
| `RUN` | Run script |
| `../../kbase/weather.pro` | Prolog rules for weather observation queries |

## Build

```bash
cd examples/weather
gprbuild -P weather.gpr
```

## Run

```bash
env PACE=../.. PACE_SIM=1 PACE_NODE=0 obj/weather_main
```

`PACE=../..` points to the PACE root so `Pace.Config.Find_File` can locate
`kbase/weather.pro`.  `PACE_SIM=1` disables the HTTP reader threads (the
agent only makes outbound HTTP requests; no inbound serving is needed).

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `PACE` | `.` | Path to PACE root; used to locate `kbase/weather.pro` |
| `WKB_FILE` | `/kbase/weather.pro` | Override path to weather knowledge-base file |
| `PACE_NODE` | `0` | PACE node identifier |
| `PACE_SIM` | `0` | Set to `1` to disable HTTP server reader threads |
| `GKB_DEBUG` | `0` | Set to `1` to enable verbose Prolog engine output |

## Expected output

```
Weather Agent: fetching current observation for KDAG...
Received 2341 bytes of observation XML
ASSERTING:current_observations(...)
Asserted weather_obs/1 nested functor into Prolog KB
Asserted individual weather observation facts

=== Current Observation: KDAG ===
Condition:   Fair
Temperature: 73.0 F
Humidity:    13 %
Wind:        CALM
```

## Extending the example

* Change the station identifier in `NWS_Item` from `KDAG.xml` to any other
  NWS four-character ICAO code to observe a different location.
* Add more `Assert_Fact` calls in `weather_main.adb` to expose additional
  XML fields (e.g. `dewpoint_f`, `visibility_mi`) as queryable Prolog facts.
* Add rules to `kbase/weather.pro` to derive higher-level facts, for example
  a heat-index alert or a "`cold_day`" predicate.
* Use `Wkb.Find_All` to iterate over a list of stations asserted under
  different functor names.
