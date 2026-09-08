# One site: homelab.excavador.xyz.
#
# MkDocs is the only Python in this estate -- everything else is Node 24 or
# Rust. That was a deliberate trade for Material's docs UX; devbox contains the
# cost rather than letting it spread.

default:
    @just --list

# Build into site/
build:
    mkdocs build --strict

# Serve with live reload
serve:
    mkdocs serve

# --strict fails on a broken internal link. This site points at repositories
# that move; the link check is the only thing that notices when one of them
# moves out from under a page.
check: build

clean:
    rm -rf site
