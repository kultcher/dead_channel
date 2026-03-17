class_name Jargonizer extends Resource

static func get_handshake():
	return handshakes.pick_random()

static var handshakes = [
	"Establishing tunnel... OK",
	"Negotiating session... OK",
	"Handshake: SYN → SYN-ACK → ACK (██ms)",
	"Routing through proxy chain... 3 hops... connected.",
	"Port scan: ██/tcp open. Establishing link.",
	"Spoofing MAC address... accepted.",
	"TLS downgrade... success. Channel open.",
	"Connecting via relay ████... latency ██ms... OK",
	"Session key exchanged. Encrypted channel active.",
	"Piggyback on maintenance port... accepted.",
	"Auth bypass: null credential injection... OK",
	"Certificate pinning disabled. Proceeding.",
	"Tunneling through ████:██... connected."
]

var camera_types = [
	"SentinelCorp PTZ-4400",
	"OmniDyne Watchdog Mk3",
	"Krieger Optics KR-90",
	"Fujin FieldEye V2",
	"Panoptik Sentry-7",
	"Daedalus Overwatch D12"
]
