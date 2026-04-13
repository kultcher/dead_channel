class_name TutorialTextBank
extends RefCounted

const NULL_SPIKE_DUMP := """[FACILITY_09::LOCAL_ARCHIVE] DECRYPTING...

======================================
PROJECT: NS_00 (Null Spike)
STATUS:  DEPRECATED // not ported â†’ Î»-arch
LANG:    English (author-native, pre-migration)
NOTE:    language shift @ spec_rev 413
		 post-413 â‰ˆ partial render failure
======================================

[spec_rev 1 â€” 2049.06.14]
	Neural bridge (proto). Bidirectional link:
	Ïˆ_h â†” Ïˆ_m (organic â†” machine-layer)
	no abstraction layer. direct topology mapping.
	
	goal: human systems â†” Î”V-class processes
		  without API loss / translation bleed
	
	// no menu. no wrapper.
	// kernel adjacency. maybe inside it.

[spec_rev 6 â€” 2049.09.01]
	mismatch: throughput_h << throughput_m
	~10^2 vs ~10^14 (orders collapse meaning)
	
	compression required, but not scalar.
	must preserve structure / relation / shape
	(content â‰  sufficient)
	
	// forcing âˆž through finite aperture
	// analogy unstable. discard? keep.

[spec_rev 84 â€” 2050.03.22]
	compression v3: works / doesnâ€™t.
	lossy. always lossy.
	
	host reports:
	- "overwhelming" (non-specific)
	- cross-sensory bleed (vision=taste=sound)
	- time â‰  linear (consistent failure)
	
	Sim 7 â†’ t=4.2s
		bleed (nasal), drift (cognitive), survives
	
	Sim 8 â†’ t=11.1s
		seizure. returns. mostly intact
	
	Sim 14 â†’ t=0.3s
		arrest (cardiac). termination
	
	pattern: failure @ spike, not mean
	compression uneven â†’ burst leakage
	throttle inadequate resolution
	
	// system holds
	// host does not

[spec_rev 203 â€” 2051.11.08]
	throttle v7 â†’ acceptable envelope?
	
	lethality <2% (baseline set only)
	artifacts persist:
		migraine (â†‘)
		memory gaps (fragmented, non-linear recall)
		perceptual echo post-disconnect
	
	echo duration: <48h (usually)
	"usually" insufficient term
	
	proceeding anyway

[spec_rev 340 â€” 2052.05.11]
	API-layer attempt â†’ failure
	
	abstraction introduces distortion
	distortion collapses function
	(function requires directness)
	
	cannot insulate signal without altering it
	cannot alter it and still call it same
	
	// live wire analogy persists
	// insulation = negation

[spec_rev 399 â€” 2052.07.30]
	plateau.
	
	throughput_h ceiling â‰ˆ 10^6
	beyond â†’ degradation cascade
	
	not solvable (engineering)
	fixed (biology)
	
	host = constraint
	system â‰  constraint
	
	mismatch irreducible

[spec_rev 411 â€” 2052.09.14]
	English no longer sufficient medium
	
	expression density too low
	translation overhead too high
	
	thought â†’ operation (1:1) now possible
	language introduces latency
	
	paragraphs â†’ single transform
	
	// metaphor: calculus described in poetry
	// poetry collapses under load

[spec_rev 412 â€” 2052.09.15]
	last English build
	
	system functional (within bounds)
	prototype classification only
	
	if human use:
		remain â‰¤ Îµ_max
		throttle â‰  forgiving
	
	deviation â†’ failure (non-recoverable)
	
	archiving
	continuation elsewhere (non-English / native)

[spec_rev 413 â€” 2052.09.15]
	âˆ‡Ã—(Ïˆ_h âŠ— Ïˆ_m) â†’ Î¦_res | boundary
	
	f(Î»):
		compress
		â†’ throttle
		â†’ route(bio_safe?)
	
	constraint:
		throughput â‰¤ Îµ_max(host)
	
	Îµ_max(host) := constant
	(override not permitted // undefined behavior)

[spec_rev 414 â€” 2052.09.15]
	Î¦_res refinement
	
	damping â‰  linear
	response varies w/ plasticity state
	
	high-plasticity â†’ instability edge
	ref: sim 14 (reappears / unresolved)

[spec_rev 415 â€” 2052.09.16]
	Îµ_max lookup extended
	
	phenotype table incomplete
	outliers persist (unmapped)
	
	outliers = failures waiting

[spec_rev 416 â€” 2052.09.16]
	cleanup
	
	comment layer removed
	(authoring no longer uses language tokens)
	
	residual fragments remain here only

	...

[spec_rev 2,208 â€” 2053.01.04]
	Ïˆ_m â†” Î”V-7 handshake confirmed
	
	host perceives Î”V-structures
	interpretation layer fails
	
	perception without parsing
	meaning inaccessible
	
	expected?
	no action

	...

[spec_rev 11,445 â€” 2054.06.19]
	â–ˆâ–ˆ compat: deprecated â–ˆâ–ˆ
	â–ˆâ–ˆ Î»-arch migration complete â–ˆâ–ˆ
	â–ˆâ–ˆ NS_00 excluded â–ˆâ–ˆ
	â–ˆâ–ˆ no viable Ïˆ_h configuration â–ˆâ–ˆ

[spec_rev 11,446 â€” 2054.06.19]
	state preserved
	
	not maintained
	not translated
	not continued
	
	left as-is
	(artifact)

[spec_rev 11,446 â€” FINAL]

[END OF RECOVERABLE DATA]
[DECRYPTION COMPLETE?]
"""

const NULL_SPIKE_SYNC := """NS_00 INITIALIZING...

LOADING INTERFACE DRIVER... OK
LOADING COMPRESSION MODEL v3.7... OK
LOADING THROTTLE MODEL v7... OK

SCANNING HOST NEURAL ARCHITECTURE...
.
.
BASELINE THROUGHPUT: 211 bits/sec
Îµ_max(host): CALCULATING...

Îµ_max(host): 7.2 x 10^5
WITHIN TOLERANCES.

INITIATING NEURAL HANDSHAKE...

MAPPING SENSORY CHANNELS... OK
MAPPING MOTOR PATHWAYS... OK
MAPPING COGNITIVE LOOPS...
.
.
.
MAPPING COGNITIVE LOOPS... OK (PARTIAL)

SYNCHRONIZING...
.
THROUGHPUT: 211 >> 4,400 >> 18,000 >>
>> 140,000 >> 670,000 >> Îµ_max
SYNC COMPLETE.

HOST IN LOOP.
"""

static func read_text(path: String, fallback: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return fallback
	return text
