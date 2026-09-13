# What runs on it, and why that

A homelab is where you find out which components you actually understand.
Everything below was picked for a reason; where the reason was "it is what
everyone uses", it usually got replaced later.

## The operating system

**[Talos Linux](https://www.talos.dev)** — no shell, no SSH, no package
manager, no login at all. A node is configured entirely through an API, from a
machine configuration rendered out of this estate's repository.

The appeal is not minimalism for its own sake. It is that **configuration drift
becomes impossible**: there is no way to log into a node and fix something by
hand, so nothing is ever fixed by hand, so no node is quietly different from
its description. The cost is real — every habit you have for debugging a Linux
box has to be relearned — and it buys a cluster that can be destroyed and
rebuilt from git without anyone wondering what was done to node three in March.

## The network

**[Cilium](https://cilium.io)** in native routing, no overlay, with
kube-proxy replaced by eBPF.

Native routing because an overlay would mean encapsulating every packet on
eight ARM boards whose CPU is better spent on workloads; the nodes are all on
one flat subnet, so the router can simply route pod traffic and the overhead
disappears. Cilium also hands out LoadBalancer addresses from a pool on that
same LAN and announces them by ARP, which is what makes a bare-metal cluster
with no cloud load balancer behave like one that has them.

Hubble gives per-flow visibility, which turned out to matter more than
expected: network policy is only auditable if you can watch what it would have
dropped before it drops it.

## Keeping the cluster equal to the repository

**[Argo CD](https://argo-cd.readthedocs.io)** — every component is an
Application, arranged app-of-apps with sync waves so that ordering constraints
are declared rather than discovered.

Nothing is `kubectl apply`-ed by hand. The reason is less about purity than
about rebuilds: the cluster has been destroyed and recreated more than once,
and each time the recovery was a replay of a git history rather than an
archaeology exercise.

## Identity and secrets

**[dex](https://dexidp.io)** is the single OIDC issuer, with Google as the
directory behind it. `kubectl`, Argo CD, Grafana, the board management fleet —
all of them authenticate the same way. One place to grant access, one place to
revoke it.

**[OpenBao](https://openbao.org)** holds the secrets, on raft, unsealed with a
cloud KMS key so a restart does not need a human. **external-secrets** pulls
them into the cluster as needed, which keeps them out of git entirely — there
is no encrypted-blob-in-a-repository step to get wrong.

**cert-manager** issues everything internal from a private CA that every node
pins, so hops inside the cluster are TLS as well.

## The front door

**Envoy Gateway**, driven by the Gateway API rather than Ingress. Per-service
gateways, and authentication applied at the gateway instead of inside each
application — see [access](access.md). Gateway API because it separates who
runs the gateway from who publishes a route, which is exactly the split that
annotation-driven Ingress never managed.

## Storage, in three tiers

Storage is where homelab advice is worst, because the honest answer is that it
depends on what the data is.

- **NVMe on each node**, carved into logical volumes. Fast, local, and gone if
  the node is gone. For anything that can be rebuilt.
- **A RAID1 mirror on each of the two storage nodes** — 4 TB of spinning disk,
  for bulk: metrics, logs, traces, the registry cache. Big and cheap, and a
  mirror because a single disk failure should be a dull afternoon.
- **[Longhorn](https://longhorn.io)**, replicated across nodes, for the volumes
  that have to survive their pod moving.

Those mirrors taught the sharpest storage lesson here: a RAID1 array without a
write-intent bitmap re-copies **every** block after an unclean shutdown. Four
terabytes, many hours, on every reboot. A bitmap turns that into seconds, and
the rebuild is now proven by pulling a drive rather than by reading
documentation.

## Databases and caches

**CloudNativePG** for Postgres, because failover and backup belong to an
operator that understands Postgres rather than to a StatefulSet and hope.
**Valkey** where something needs a session store.

## Watching it

**VictoriaMetrics**, **VictoriaLogs** and **VictoriaTraces**, with
**OpenTelemetry** collection and **Grafana** on top.

The Victoria family rather than the more common choices for one measurable
reason: footprint. On ARM boards that also have real work to do, the
observability tier should not be the largest tenant, and here it is not.

**Gatus** probes the public endpoints from outside, because a monitoring system
that lives inside the thing it monitors cannot tell you that the thing is
unreachable. That distinction stopped being theoretical the day the metrics
store silently filled up and the alerts about it had nowhere to land.

## A registry of its own

**[zot](https://zotregistry.dev)** as a pull-through mirror in front of the
public registries, one instance on each storage node.

It started as a way to stop hitting Docker Hub's rate limits from a single home
IP address. What it actually bought was independence: an image the estate has
pulled once is on local disk, so nodes can restart and workloads can reschedule
during an ISP outage. Nothing is ever pushed to it, which is why the two
instances do not replicate — a cache miss on either is just a fetch.

## Knowing what is here

**[NetBox](https://netbox.dev)** for the estate — racks, devices, addresses —
and **[HomeBox](https://homebox.software)** for the household inventory. Both
have [MCP servers](index.md) so the question "what is plugged into port 4" can
be asked in words, and answered against the record rather than from memory.

## The small necessary things

`descheduler` to correct placement that drifted, `reloader` to restart
workloads when a config or secret changes underneath them, `metrics-server`,
and priority classes so the platform wins when something has to lose.

None of them are interesting. All of them are the difference between a cluster
that runs and one that needs attention every week.
