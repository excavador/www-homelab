# Homelab

A ten-node Kubernetes cluster: eight Turing RK1 modules across two Turing Pi 2
boards, a Raspberry Pi 5, and an x86 builder for amd64 images. The control
plane sits in three failure domains, so losing a whole board does not lose the
cluster.

Talos Linux — no SSH, no shell, no package manager, configured only through an
API. Cilium in native routing with eBPF. Argo CD reconciles everything;
nothing is clicked. VictoriaMetrics, VictoriaLogs and VictoriaTraces for
observability, OpenBao for secrets, dex for operator identity.

Storage comes in three tiers: NVMe on each node, a RAID1 mirror on each of the
two storage nodes for bulk, and Longhorn for the volumes that have to follow a
pod between nodes. A pull-through registry mirror sits in front of the public
registries, so an image the estate has seen once does not need the internet
again.

Three pages describe the estate itself:

<div class="grid cards" markdown>

-   [**The machines and the network**](topology.md)

    Two Turing Pi 2 boards, a Pi 5, an x86 builder, a switch and a router —
    what is wired to what, how it is addressed, and what happens when the
    fibre dies.

-   [**Getting in from outside**](access.md)

    A tunnel with no open ports for browsers, a private mesh for
    administration, and why those are deliberately not the same path.

-   [**What runs on it, and why that**](stack.md)

    The Kubernetes components, each with the reason it was chosen — including
    the ones that replaced an earlier choice.

</div>

The rest of this page is a directory of the tooling, not a manual. Each tool's
documentation lives with the tool — a second copy here would only be a second
copy to go stale. What follows is enough to tell whether something is worth
your time, and a link.

## Talking to infrastructure

Two [MCP](https://modelcontextprotocol.io) servers, both in Go, both
multi-arch. The distinction that matters: they **write**, not just read.

[**netbox-mcp**](https://github.com/excavador/netbox-mcp)
:   NetBox DCIM and IPAM. Ask what is in a rack, then record the switch you
    just cabled. Most NetBox MCP servers are read-only, which makes them a
    reporting tool rather than an inventory one — and an inventory you cannot
    update is an inventory that drifts.

[**homebox-mcp**](https://github.com/excavador/homebox-mcp)
:   A [HomeBox](https://homebox.software) household inventory. What is in the
    attic, what the boiler service cost, what that spare PSU actually fits.

Both publish an image and a chart to GHCR:

```
ghcr.io/excavador/netbox-mcp        oci://ghcr.io/excavador/charts/netbox-mcp
ghcr.io/excavador/homebox-mcp       oci://ghcr.io/excavador/charts/homebox-mcp
```

## Running things on Kubernetes

[**homebox-chart**](https://github.com/excavador/homebox-chart)
:   Upstream HomeBox ships a container image and no Kubernetes packaging, so
    everyone self-hosting it writes their own manifests. This is that work,
    done once — hardened defaults, native OIDC, Postgres or SQLite.

[**netbox-image**](https://github.com/excavador/netbox-image)
:   NetBox with the topology-views plugin baked in. The official chart can
    *enable* plugins but not *install* them — a distinction you discover at
    the wrong moment.

[**netbox-mcp-chart**](https://github.com/excavador/netbox-mcp-chart)
:   Packaging for NetBox Labs' own read-only server, kept as a fallback.

## Getting Talos onto small boards

[**talos-installer-rpi5**](https://github.com/excavador/talos-installer-rpi5)
:   The Image Factory cannot produce a bootable Pi 5 image for **D0 silicon**.
    The `rpi_5` overlay ships `rpi_generic`'s u-boot, which on a D0 board
    either fails to boot or comes up without advertising `SetVariableRT` — and
    without that, `talosctl upgrade` dies at the bootloader step. This builds
    an installer that works.

[**u-boot-rpi5**](https://github.com/excavador/u-boot-rpi5) and
[**sbc-rockchip**](https://github.com/excavador/sbc-rockchip) are the forks
underneath it.

## The board the cluster sits on

The Turing Pi 2's management controller runs a fork of its own firmware: a
health-gated A/B update that reverts a bad image by itself, a temperature
sensor the board never had, a kernel-driven fan, and Prometheus metrics behind
a credential that cannot touch the control API.

That one grew into [a project of its own](https://turingpi.xyz). What the
controller does for the modules around it is on the
[topology page](topology.md).

## What is not here

The **shape** of the estate is described on the three pages above: what the
hardware is, how it is addressed, how it is reached, what runs on it and why.
None of that is sensitive. It is an RFC 1918 network behind two layers of NAT
with no inbound ports, and the addresses in it mean nothing to anyone who is
not already on it.

The **configuration** is a different matter and stays private: the Talos machine
configs, the Argo applications, the network policy, the secrets wiring, and
anything that would tell you which door is currently unlocked rather than which
doors exist.

So: the design, yes — it is the part that might be useful to someone building
something similar. The running state, no.

The parts worth reusing outright are the repositories above, and they are
deliberately standalone: none of them assumes this estate.
