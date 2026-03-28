# Terminal Flavor Text Kit

---

## Boot/Connect Sequences

The boot sequence needs to feel like you're watching a real device handshake and initialize. The key is **speed and scannability** — most of this scrolls past fast, but a sharp-eyed player might notice useful details buried in the noise.

### Structure

```
[HANDSHAKE LINE]
[DEVICE IDENTIFICATION]
[STATUS BLOCK — 2-3 lines]
[SUBPROCESS MANIFEST — just names, not details]
[PROMPT]
```

### Handshake Lines (pick 1-2, randomize)

```
Establishing tunnel... OK
Negotiating session... OK
Handshake: SYN → SYN-ACK → ACK (██ms)
Routing through proxy chain... 3 hops... connected.
Port scan: ██/tcp open. Establishing link.
Spoofing MAC address... accepted.
TLS downgrade... success. Channel open.
Connecting via relay ████... latency ██ms... OK
Session key exchanged. Encrypted channel active.
Piggyback on maintenance port... accepted.
Auth bypass: null credential injection... OK
Certificate pinning disabled. Proceeding.
Tunneling through ████:██... connected.
```

### Device Identification Block

This is the important line — signal type, model, manufacturer. Should always be visually consistent so players learn to find it.

```
[SESSION: {system_id} — {manufacturer} {model}]
```

Manufacturer and model names by signal type:

**Cameras:**
```
SentinelCorp PTZ-4400
OmniDyne Watchdog Mk3
Krieger Optics KR-90
Fujin FieldEye V2
Panoptik Sentry-7
Daedalus Overwatch D12
```

**Motion Sensors:**
```
Krieger KM-40 Proximity Array
TremaSense FloorNet T7
OmniDyne TripWire Pro
Helix Dynamics MotionMesh 3.1
```

**Doors/Locks:**
```
KranzLock Industrial D-Series
Fortis SecureBolt 800
Aegis Electromagnetic L5
OmniDyne AccessPoint Mk2
VaultTech HeavyGate (blast doors)
```

**Turrets:**
```
Krieger AutoSentry KAS-60
Daedalus Talon T4
OmniDyne Interceptor Mk5
```

**Drones (Spy):**
```
Fujin WhisperWing S2
OmniDyne SkyEye Mk1
SentinelCorp Orbiter-3
```

**Drones (Combat):**
```
Krieger Hornet KH-12
Daedalus StrikeWing D8
OmniDyne Enforcer Mk3
```

**Terminals (Security/Comms/Paydata):**
```
NovaTek Workstation NT-440
Infolex DataPoint 7
CyraCom RelayDesk R3
OmniDyne AdminConsole Mk2
```

### Status Block Lines (pick 2-4 based on signal type)

**Universal:**
```
STATUS: ONLINE
UPTIME: ████h ██m
FIRMWARE: v█.█.█
LAST MAINT: ████-██-██
NETWORK: {subnet_id}
POWER: MAINS | BATTERY (██%) | UPS BACKUP
ASSET TAG: {corp_name}-████████
```

**Camera-specific:**
```
RECORDING: ACTIVE — buffer at ██%
FEED: LIVE | LINKED | OFFLINE
RESOLUTION: 1080p | 4K | THERMAL
NIGHT VISION: ON | OFF | AUTO
MOTION DETECT: ENABLED | DISABLED
PAN CYCLE: ██s
```

**Door-specific:**
```
STATE: LOCKED | UNLOCKED | SEALED | EMERGENCY_LOCKED
BOLT TYPE: ELECTROMAGNETIC | MECHANICAL | DEADBOLT
AUTH: Tier █ clearance required
FIRE PROTOCOL: FAIL-SAFE (unlocks) | FAIL-SECURE (locks)
```

**Sensor-specific:**
```
SENSITIVITY: LOW | MEDIUM | HIGH | ADAPTIVE
TRIGGER MODE: SINGLE | REPEATING | CONTINUOUS
CALIBRATION: ████-██-██ (██ days ago)
FALSE POSITIVE RATE: █.█%
```

**Drone-specific:**
```
PATROL STATUS: ACTIVE | IDLE | RETURNING | CHARGING
BATTERY: ██%
ALTITUDE: ██m
ROUTE: STANDARD | ALERT | CUSTOM
```

**Turret-specific:**
```
TARGETING: AUTO | MANUAL | STANDBY
AMMUNITION: ██/███ | ENERGY (██%)
SAFETIES: ON | OFF | OVERRIDE
TRACKING SPEED: ██°/s
```

**Terminal-specific:**
```
ACCESS LEVEL: PUBLIC | RESTRICTED | CLASSIFIED
LAST LOGIN: ████-██-██ ██:██ ({username})
ACTIVE SESSIONS: █
STORAGE: ██% USED
```

### Flavor/Noise Lines (sprinkle 0-2 based on difficulty, adds character)

```
NOTE: "Cam 7 is flickering again. Put in a ticket." — Facilities
NOTE: "DO NOT reboot during shift change." — B. Torres, Security
NOTE: "Password taped to the underside. Don't tell Frank." — anonymous
WARNING: Firmware update available. 3 updates behind.
WARNING: Certificate expires in ██ days.
WARNING: Scheduled maintenance overdue by ██ days.
ADVISORY: This device is managed by {corp_name} IT Dept.
ADVISORY: Unauthorized access is a Class 3 corporate offense.
ALERT LOG: Last triggered ██m ago (false positive — filed)
DIAGNOSTIC: Self-test passed. Next check in ██h.
TEMP: ██°C (within operating range)
FAN: ████ RPM
```

### Full Boot Example (Medium Difficulty Camera)

```
Negotiating session... OK
Spoofing MAC address... accepted.

[SESSION: cam_01 — SentinelCorp PTZ-4400]
STATUS: ONLINE | RECORDING
FIRMWARE: v2.3.1
NETWORK: sec_subnet_A
RESOLUTION: 1080p
PAN CYCLE: 12s
NOTE: "Cam 7 is flickering again. Put in a ticket." — Facilities
INSTALLED: alarm.sys, record.sys, auth.sys

cam_01> _
```

### Full Boot Example (High Difficulty Turret)

```
Routing through proxy chain... 3 hops... connected.
TLS downgrade... success. Channel open.
Auth bypass: null credential injection... OK

[SESSION: turret_02 — Krieger AutoSentry KAS-60]
STATUS: ONLINE | TARGETING: AUTO
FIRMWARE: v4.1.0
NETWORK: sec_subnet_B
AMMUNITION: ENERGY (87%)
TRACKING SPEED: 45°/s
SAFETIES: ON
UPTIME: 1142h 07m
ADVISORY: Unauthorized access is a Class 3 corporate offense.
WARNING: Firmware update available. 2 updates behind.
INSTALLED: targeting.sys, tracking.sys, alarm.sys, watchdog.sys, iff.sys

turret_02> _
```

---

## PROBE -sub Output

### Structure

```
[SCAN: SUBPROCESSES — {signal_id}]
{noise/preamble lines}
{subprocess listing}
{possible footer noise}
```

### Preamble Noise (pick 1-2)

```
Enumerating running processes...
Scanning process table... ██ entries.
Querying service manifest...
Walking process tree from PID 1...
Reading /proc/services... done.
Dumping active daemon list...
Service heartbeat check: all responding.
Process audit initiated...
```

### Junk Subprocesses by Node Category

These are non-interactive processes that exist purely to make the list feel real. The player learns to ignore them — but they also learn to *read* the list, because the real subprocesses are mixed in.

**Universal (any signal might have these):**

```
kernel.sys          PID 001   RUNNING   [SYSTEM]
clock_sync.sys      PID 003   RUNNING   [SYSTEM]
watchdog_hb.sys     PID 007   RUNNING   [SYSTEM]
power_mgmt.sys      PID 008   RUNNING   [SYSTEM]
temp_monitor.sys    PID 012   RUNNING   [SYSTEM]
error_log.sys       PID 015   RUNNING   [SYSTEM]
diag_report.sys     PID 019   RUNNING   [SYSTEM]
firmware_crc.sys    PID 022   RUNNING   [SYSTEM]
heartbeat.sys       PID 004   RUNNING   [SYSTEM]
event_bus.sys       PID 006   RUNNING   [SYSTEM]
mem_alloc.sys       PID 009   RUNNING   [SYSTEM]
sched.sys           PID 002   RUNNING   [SYSTEM]
```

**Network-attached (cameras, terminals, drones):**

```
net_stack.sys       PID 030   RUNNING   [NETWORK]
dhcp_client.sys     PID 031   RUNNING   [NETWORK]
dns_cache.sys       PID 032   RUNNING   [NETWORK]
tls_handler.sys     PID 034   RUNNING   [NETWORK]
upnp_beacon.sys     PID 036   RUNNING   [NETWORK]
ntp_sync.sys        PID 037   RUNNING   [NETWORK]
bandwidth_mon.sys   PID 038   RUNNING   [NETWORK]
packet_filter.sys   PID 040   RUNNING   [NETWORK]
```

**Camera-specific junk:**

```
codec_h264.sys      PID 050   RUNNING   [VIDEO]
frame_buffer.sys    PID 051   RUNNING   [VIDEO]
exposure_ctrl.sys   PID 052   RUNNING   [VIDEO]
white_balance.sys   PID 053   RUNNING   [VIDEO]
compression.sys     PID 054   RUNNING   [VIDEO]
lens_autofocus.sys  PID 055   RUNNING   [HARDWARE]
ir_filter.sys       PID 057   RUNNING   [HARDWARE]
ptz_motor.sys       PID 058   RUNNING   [HARDWARE]
```

**Door-specific junk:**

```
bolt_driver.sys     PID 050   RUNNING   [HARDWARE]
mag_coil.sys        PID 051   RUNNING   [HARDWARE]
sensor_contact.sys  PID 052   RUNNING   [HARDWARE]
badge_reader.sys    PID 053   RUNNING   [INPUT]
keypad_input.sys    PID 054   RUNNING   [INPUT]
access_log.sys      PID 055   RUNNING   [LOGGING]
fire_protocol.sys   PID 060   RUNNING   [SAFETY]
tamper_sensor.sys   PID 062   RUNNING   [SAFETY]
```

**Drone-specific junk:**

```
nav_controller.sys  PID 050   RUNNING   [FLIGHT]
gyro_stabilize.sys  PID 051   RUNNING   [FLIGHT]
collision_avoid.sys PID 052   RUNNING   [FLIGHT]
altimeter.sys       PID 053   RUNNING   [FLIGHT]
battery_mgmt.sys    PID 054   RUNNING   [POWER]
motor_ctrl_L.sys    PID 055   RUNNING   [HARDWARE]
motor_ctrl_R.sys    PID 056   RUNNING   [HARDWARE]
telemetry_tx.sys    PID 060   RUNNING   [NETWORK]
```

**Turret-specific junk:**

```
servo_azimuth.sys   PID 050   RUNNING   [HARDWARE]
servo_elevate.sys   PID 051   RUNNING   [HARDWARE]
optics_range.sys    PID 052   RUNNING   [TARGETING]
ballistic_calc.sys  PID 053   RUNNING   [TARGETING]
ammo_counter.sys    PID 054   RUNNING   [ORDNANCE]
recoil_comp.sys     PID 055   RUNNING   [HARDWARE]
coolant_pump.sys    PID 056   RUNNING   [THERMAL]
barrel_temp.sys     PID 057   RUNNING   [THERMAL]
```

**Terminal-specific junk:**

```
display_mgr.sys     PID 050   RUNNING   [DISPLAY]
input_handler.sys   PID 051   RUNNING   [INPUT]
session_mgr.sys     PID 052   RUNNING   [AUTH]
file_index.sys      PID 053   RUNNING   [STORAGE]
audit_trail.sys     PID 054   RUNNING   [LOGGING]
print_spool.sys     PID 055   RUNNING   [PERIPHERAL]
screensaver.sys     PID 060   IDLE      [DISPLAY]
```

### Real (Interactive) Subprocesses — Styling Distinction

Here's the key question: **how does the player distinguish interactive subprocesses from noise?**

Options in escalating subtlety:

**Option 1: Tag them differently**

```
alarm.sys           PID 100   RUNNING   [SECURITY]    ← category tag is the tell
record.sys          PID 101   RUNNING   [SECURITY]
codec_h264.sys      PID 050   RUNNING   [VIDEO]
```

The player learns that `[SECURITY]`, `[TARGETING]`, `[ACCESS]` category tags indicate interactive processes. Simple, reliable, maybe too easy.

**Option 2: PID ranges**

Interactive subprocesses always have PIDs in the 100+ range. Junk is in the 001-099 range. This is a pattern the player discovers, not something the game tells them. More elegant, rewards attention.

**Option 3: Status differences**

```
alarm.sys           PID 100   ACTIVE    [SECURITY]    ← ACTIVE not RUNNING
record.sys          PID 101   ACTIVE    [SECURITY]
codec_h264.sys      PID 050   RUNNING   [VIDEO]       ← RUNNING
```

`ACTIVE` vs `RUNNING` is a subtle distinction the player learns to spot. Even subtler: what if hidden subprocesses show as `RUNNING` and only reveal themselves as `ACTIVE` once probed specifically?

**Option 4: Mix of signals, none individually reliable**

Some interactive processes have the `[SECURITY]` tag. Some have high PIDs. Some have `ACTIVE` status. But no single indicator is 100% reliable — high-difficulty signals might have a `watchdog.sys` tagged as `[SYSTEM]` with a low PID and `RUNNING` status, deliberately camouflaged. The player has to use multiple heuristics and experience.

**My recommendation: Start with Option 2 or 3 for clarity, graduate to Option 4 for hard signals.** Early game, the interactive subprocesses are obviously distinct. Late game, they're hiding among the noise and the player needs real pattern recognition to find them. This is your difficulty scaling for the terminal layer specifically.

### Full PROBE -sub Example

```
cam_01> PROBE -sub
[SCAN: SUBPROCESSES — cam_01]
Enumerating running processes...
Scanning process table... 14 entries.

  kernel.sys          PID 001   RUNNING   [SYSTEM]
  sched.sys           PID 002   RUNNING   [SYSTEM]
  clock_sync.sys      PID 003   RUNNING   [SYSTEM]
  heartbeat.sys       PID 004   RUNNING   [SYSTEM]
  power_mgmt.sys      PID 008   RUNNING   [SYSTEM]
  net_stack.sys       PID 030   RUNNING   [NETWORK]
  tls_handler.sys     PID 034   RUNNING   [NETWORK]
  codec_h264.sys      PID 050   RUNNING   [VIDEO]
  frame_buffer.sys    PID 051   RUNNING   [VIDEO]
  exposure_ctrl.sys   PID 052   RUNNING   [VIDEO]
  ptz_motor.sys       PID 058   RUNNING   [HARDWARE]
  alarm.sys           PID 100   ACTIVE    [SECURITY]
  record.sys          PID 101   ACTIVE    [SECURITY]
  auth.sys            PID 102   ACTIVE    [ACCESS]

14 processes. 3 interactive.
```

That last line — `14 processes. 3 interactive.` — could be a feature of your scanning software rather than the signal itself. Maybe a basic deck shows the raw list. An upgraded deck adds the interactive count. A high-end deck highlights interactive processes in a different color.

---

## PROBE -prop Output

### Structure

```
[SCAN: PROPERTIES — {signal_id}]
{preamble noise}
{property listing — mix of interactive and read-only}
```

### Preamble Noise (pick 1-2)

```
Reading device configuration...
Querying property manifest...
Dumping config registers...
Scanning parameter table...
Fetching runtime values...
Loading device profile...
```

### Distinguishing Mutable vs. Read-Only Properties

This is the same problem as subprocesses but trickier because properties are what SPOOF targets. The player needs to figure out which ones they can change.

**My recommendation: surface everything, mark mutability subtly.**

```
cam_01> PROBE -prop
[SCAN: PROPERTIES — cam_01]
Reading device configuration...

  DEVICE
    manufacturer    SentinelCorp              [READONLY]
    model           PTZ-4400                  [READONLY]
    serial          SC-PTZ-00417829           [READONLY]
    firmware        v2.3.1                    [READONLY]
    asset_tag       OMNICORP-CAM-0041         [READONLY]

  OPTICS
    fov             WIDE                      [CONFIGURABLE]
    resolution      1080p                     [READONLY]
    night_vision    OFF                       [CONFIGURABLE]
    ir_filter       AUTO                      [READONLY]
    exposure        0.72                      [READONLY]
    white_balance   5200K                     [READONLY]

  NETWORK
    subnet          sec_subnet_A              [READONLY]
    ip              10.41.3.17                [READONLY]
    mac             A4:7B:2C:██:██:██         [READONLY]
    upstream        sec_hub_01                [READONLY]
    heartbeat_int   5000ms                    [READONLY]

  FEED
    source          cam_01                    [CONFIGURABLE]
    encoding        H.264                     [READONLY]
    bitrate         4800kbps                  [READONLY]
    buffer_size     120s                      [READONLY]

  MOTION
    pan_speed       15°/s                     [READONLY]
    pan_range       -45° / +45°              [READONLY]
    pan_cycle       12s                       [READONLY]
    current_angle   +12°                      [READONLY]
```

`[CONFIGURABLE]` vs `[READONLY]` is the tell. But notice how few are configurable — only `fov`, `night_vision`, and `source` (the feed link target) out of maybe 20 properties. The player scans for `[CONFIGURABLE]` tags and ignores the rest. The read-only properties are still valuable as *information* though:

- `firmware v2.3.1` might be a known vulnerable version (ties into RUN exploits)
- `upstream: sec_hub_01` tells them the network topology without needing TRACE
- `heartbeat_int: 5000ms` tells them how often the signal checks in (timing window for KILL)
- `pan_cycle: 12s` tells them the camera's sweep timing
- `current_angle: +12°` tells them where the camera is pointing RIGHT NOW

So read-only properties aren't noise — they're free intelligence that rewards attentive players. The noise is stuff like serial numbers, MAC addresses, white balance, bitrate — real-sounding but gameplay-irrelevant.

**Scaling difficulty through properties:**

| Difficulty | Property Presentation |
|---|---|
| Easy | Few properties, `[CONFIGURABLE]` clearly marked, obvious names |
| Medium | More noise properties, `[CONFIGURABLE]` still marked |
| Hard | `[CONFIGURABLE]` tag replaced with `[READ/WRITE]` mixed in with `[READ]` — less visually distinct |
| Nightmare | No tags at all. Player has to try SPOOF and see what works, or rely on experience with the device model |

---

## Effective Command Response Messages

These should be punchy and clear. The player just did something — tell them what happened and what it cost.

### KILL Responses

**Signal kill:**
```
[KILL] cam_01 — OFFLINE
All subprocesses terminated: alarm.sys, record.sys, auth.sys
Heat: +8
```

**Subprocess kill:**
```
[KILL] cam_01/alarm.sys — TERMINATED
Alert capability disabled. Recording still active.
Heat: +3
```

**Kill with reboot warning:**
```
[KILL] sensor_01 — OFFLINE
All subprocesses terminated: alarm.sys
WARNING: Reboot cycle detected. Estimated recovery: 30s.
Heat: +6
```

**Kill with consequences:**
```
[KILL] cam_01 — OFFLINE
All subprocesses terminated: alarm.sys, record.sys, watchdog.sys
WARNING: watchdog.sys sent alert to sec_hub_01 before termination.
Heat: +8 (+3 alert penalty)
```

### SPOOF Responses

**Standard:**
```
[SPOOF] cam_01.fov: WIDE → NARROW
Detection arc reduced.
Heat: +3
```

**Feed spoof:**
```
[SPOOF] cam_01.source: cam_01 → cam_01.buffer
Feed switched to stored buffer. Live detection suspended.
Heat: +4
```

**Sensitivity:**
```
[SPOOF] sensor_01.sensitivity: HIGH → LOW
Trigger threshold raised. Runner evasion improved.
Heat: +2
```

### PROBE Responses

**Targeted:**
```
cam_01> PROBE -vuln
[SCAN: VULNERABILITIES — cam_01]
Checking firmware against known exploit database...
  firmware v2.3.1 — KNOWN EXPLOIT: buffer overflow (CVE-2087-4412)
  Exploit available: RUN overflow -target firmware
  Estimated success: 85%
  Heat on attempt: +4
```

```
cam_01> PROBE -net
[SCAN: NETWORK — cam_01]
Tracing network adjacency...
  Subnet:     sec_subnet_A
  Upstream:   sec_hub_01 (SECURITY HUB — 4 devices managed)
  Peers:      cam_02, cam_03, sensor_01
  Heartbeat:  5000ms to sec_hub_01
  Last check: 2.3s ago
```

### RUN Responses

```
cam_01> RUN overflow -target firmware
[RUN] Executing buffer overflow against cam_01 firmware...
[████████████████████] SUCCESS
cam_01 — ROOT ACCESS OBTAINED
All subprocesses now controllable. Security rating bypassed.
Heat: +4
```

```
cam_01> RUN overflow -target firmware
[RUN] Executing buffer overflow against cam_01 firmware...
[████████████░░░░░░░░] FAILED — patched in this build
Heat: +2 (attempt cost)
cam_01> _
```

### PING Responses

```
root> PING sensor_03
[PING] sensor_03 — KM-40 Proximity Array
Trigger profile transmitted to runner team.
Runner evasion: ██% → ██%
Heat: +1
```

### TRACE Responses

```
cam_01> TRACE -upstream
[TRACE] Mapping network topology...
cam_01 → sec_hub_01 (SECURITY HUB)
  sec_hub_01 manages: cam_01, cam_02, cam_03, sensor_01
  sec_hub_01 → master_ctrl (RESTRICTED — Tier 3)
Heat: +2
```

---

## Hint Text for Puzzles

This is the fun part. The principle: **use real-ish technical terminology that encodes the puzzle type without naming it directly.** The player learns the mapping through experience.

### Encryption/Cipher Hints (Decryption Puzzle)

Instead of "Encryption type: Caesar," use the signal's security profile:

```
ENCRYPTION PROFILE:
  Cipher class:     Rotational substitution
  Key length:       Single-value
  Block mode:       Character-level
  Entropy analysis: Low (pattern-preserving)
```

That's a Caesar cipher described in technical terms. A Vigenère cipher might be:

```
ENCRYPTION PROFILE:
  Cipher class:     Polyalphabetic substitution
  Key length:       Multi-value (estimated: 4-6)
  Block mode:       Character-level
  Entropy analysis: Moderate (periodic pattern detected)
```

You can also embed the key or shift value in noise:

```
ENCRYPTION PROFILE:
  Cipher class:     CSR (Cyclic Shift Rotation)
  Spec:             CSR-5 [L]
  Cert:             OMC-CRYPTO-2084-REV3
  Block mode:       Sequential
  Compliance:       Sub-grade (deprecated 2086)
```

`CSR-5 [L]` — Cyclic Shift Rotation, shift of 5, Left. That's a Caesar cipher with a left shift of 5. The player who's learned to read this skips half the decryption puzzle because they already know the key. The `deprecated 2086` is a flavor hint that this is weak encryption — if the player sees `Current standard (2091)` on another signal, they know it'll be harder.

### More Cipher Hint Examples

```
// Caesar, shift 12
Cipher: ROT-STD | Offset: 0x0C | Mode: MONO-ALPHA

// Caesar, shift 3
Cipher: CSR-3 [R] | Grade: LEGACY | Deprecated

// Substitution cipher (not rotational)
Cipher: STATIC-MAP | Key: PARTIAL (3/26 recovered) | Grade: LOW

// Transposition cipher
Cipher: BLK-TRANSPOSE | Key length: 4 | Mode: COLUMNAR

// XOR-based
Cipher: XOR-STREAM | Key: SINGLE-BYTE | Entropy: LOW (repeating pattern)

// Something harder
Cipher: AES-LITE-128 | Mode: ECB | Key: UNKNOWN | Grade: STANDARD
```

### Puzzle Type Hint Mapping

Each puzzle type should have its own family of technical language:

**Decryption puzzle → Encryption profile**
```
SECURITY LAYER: ENCRYPTED
  Protocol:   {cipher description}
  Crack est.: {time hint if player waits vs. solves}
  Brute:      {whether brute force is viable + cost}
```

**Sniffer puzzle → Pattern matching profile**
```
SECURITY LAYER: OBFUSCATED
  Method:     Dynamic hex cycling
  Refresh:    {speed the grid changes}
  Signature:  {the pattern to find}
  Complexity: {grid size, number of matches needed}
```

**Terminal-only (no minigame) → Auth challenge**
```
SECURITY LAYER: AUTH CHALLENGE
  Type:       Command validation
  Clearance:  Tier {n}
  Bypass:     Credential match OR terminal override
```

**Process delay / multi-stage → Install/compile metaphor**
```
SECURITY LAYER: FIRMWARE LOCK
  Bypass:     Sequential flash required
  Stages:     {n} partitions
  Est. time:  {time per stage}
  Interrupt:  {what happens if you leave mid-process}
```

### Full Hint Block in Context

When the player first encounters a hackable signal's puzzle, it could appear as part of the boot sequence or as a PROBE result:

```
door_03> PROBE -vuln
[SCAN: VULNERABILITIES — door_03]
Checking security layers...

  PRIMARY LOCK: ENCRYPTED
    Protocol:     CSR-7 [R] — Cyclic Shift Rotation
    Grade:        SUB-STANDARD (deprecated 2085)
    Key recovery: Partial (4/8 positions mapped)
    Wait est.:    Full key in ~15s
    Brute force:  Available (-brute flag, +6 heat)

  SECONDARY LOCK: NONE

  KNOWN EXPLOITS: None for this firmware.

Recommendation: Decrypt or wait for key. Brute force available at high heat cost.
```

The player reads this and knows: it's a Caesar cipher with right-shift of 7, they already have 4 of 8 characters mapped, they can wait 15 seconds for the full key to reveal, or they can try to solve it now with partial info, or they can brute force it for 6 heat. Three options, all communicated through the hint text, all with different skill/time/heat tradeoffs.
