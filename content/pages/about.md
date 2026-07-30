---
slug: about
title: About
lead: >-
  A small namespace for formal vocabularies about knowledge and record,
  maintained so that the IRIs published under it keep resolving.
description: >-
  About epistemic-ontology.net — what it publishes, the editorial policy, and
  how the site itself is built and kept honest.
---

## What this is

Epistemic Ontology is a publishing address, not a project umbrella. The goal is
narrow and durable: a handful of carefully engineered, inter-operable
vocabularies, each at a permanent IRI so it can be cited, imported and
dereferenced for decades.

The vocabularies are related but independent. The [Record Ontology](/record/) is
the core: a domain-neutral model of *warranted record-structure*. The
[Arithmetic Companion](/arith/) attaches to it, supplying the formal object face
at representative scope. The [Record Harm Ontology](/record-harm/) reads the same
territory from the other side — what damage to a record looks like as an *act*,
with a perpetrator and a date.

## Editorial policy

**Permanent from birth.** A vocabulary is not published here until its IRIs are
the ones it will keep. Placeholder namespaces are a debt paid by everyone
downstream, and this site carries a live example of the interest: record-harm is
served through a namespace rewrite because it was drafted under `example.org`,
and the staging script fails loudly if a single placeholder IRI survives.

**Small, and reasoned.** OWL 2 DL where reasoning genuinely matters, SKOS where a
controlled vocabulary is enough, SHACL for closed-world validation. Terms are
added when they are settled, not when they are imagined; open questions are
recorded as open rather than encoded as vocabulary.

**Documentation is not a summary of the RDF; the RDF is the source.** Version
numbers, term counts, licences and import lists on this site are extracted from
the published Turtle at build time. They cannot drift from what is served,
because nothing retypes them.

## How the site is built

A short Python generator (`build.py`) renders Markdown content through Jinja
templates into a static tree, which nginx serves. There is no database, no
client-side framework, and no JavaScript beyond a theme toggle.

The build does three things worth naming:

1. **Reads ontology metadata with rdflib** from the staged Turtle, so the site
   cannot advertise a version it is not serving.
2. **Checks every internal link** and fails the build on a dead one.
3. **Refuses placeholder IRIs**, so a rewritten namespace can never silently
   revert.

Staging is separate from building. `stage-record.sh` and `migrate.sh` copy
serializations out of the source repositories into `ontology-dist/`; the site
builds from that, so it can be rebuilt and deployed without the source repos
present.

## Maintainer

Maintained by Ron Hinchley. Source and issue trackers are linked from each
ontology page. Corrections to the vocabularies belong in their own repositories;
corrections to this site belong with the site.

## Colophon

Set in the reader's system UI typeface, with no webfonts and no external
requests. Light and dark themes follow the operating system unless overridden.
The RDF is served with `Access-Control-Allow-Origin: *` so that browser tooling
can fetch it directly.
