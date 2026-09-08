# Homelab

A four-node Kubernetes cluster running on Turing RK1 modules, with a Raspberry
Pi 5 as a control-plane node. Talos Linux, Cilium in native routing, Argo CD,
VictoriaMetrics, OpenBao. Everything is GitOps; nothing is clicked.

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

That one grew into [a project of its own](https://turing.excavador.xyz).

## What is not here

The cluster's own configuration — Talos machine configs, Argo applications,
network policy, secrets wiring — is private. Not because any single piece is
sensitive, but because a public map of one specific network is a liability with
no matching benefit to anyone else.

The parts worth reusing are the ones above, and they are deliberately
standalone: none of them assumes this estate.
