# Homelab

A four-node Kubernetes cluster running on Turing RK1 modules, with a Raspberry
Pi 5 as a control-plane node. Everything is GitOps; nothing is clicked.

This site covers the parts that are open source and reusable.

## netbox-mcp

An MCP server for [NetBox](https://netbox.dev), written in Go. Unlike most
NetBox MCP servers it **writes** as well as reads, which is the half that makes
it useful for an inventory that changes.

## homebox-mcp

An MCP server for [Homebox](https://homebox.software) — the household inventory
that tracks what is in the rack and what it cost.

## What runs it

Talos Linux, Cilium in native routing, Argo CD, VictoriaMetrics, OpenBao for
secrets, and a Turing Pi 2 whose firmware became
[a project of its own](https://turing.excavador.xyz).
