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

This site is a directory, not a manual. Each tool's documentation lives with
the tool — a second copy here would only be a second copy to go stale. What
follows is enough to tell whether something is worth your time, and a link.

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

That one grew into [a project of its own](https://turingpi.xyz).

## What is not here

The cluster's own configuration — Talos machine configs, Argo applications,
network policy, secrets wiring — is private. Not because any single piece is
sensitive, but because a public map of one specific network is a liability with
no matching benefit to anyone else.

The parts worth reusing are the ones above, and they are deliberately
standalone: none of them assumes this estate.
