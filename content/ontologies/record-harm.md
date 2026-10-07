---
slug: record-harm
order: 3
title: Record Harm Ontology
prefix: rho
namespace: https://www.epistemic-ontology.net/record-harm#
primary_file: record-harm-ontology.ttl
summary: >-
  A taxonomy of the ways an informational record can be damaged — prime harms
  (destruction, fabrication, alteration, omission, denial, suppression) and the
  composites built upon them — with SKOS vocabularies, SHACL validation, an
  event layer for specific occurrences, and a record layer saying where a
  record lives.
badges: [OWL 2 DL, SKOS, SHACL]
repo: https://github.com/commuted/record-harm-ontology
license: { name: CC BY 4.0, url: "https://creativecommons.org/licenses/by/4.0/" }
cite_key: recordharmontology2026
cite_title: "Record Harm Ontology: A Formal Model of Ontological Attacks on Information"
cite_year: 2026
files:
  - { file: record-harm-ontology.ttl, label: Ontology }
  - { file: record-harm-shapes.ttl, label: SHACL shapes }
  - { file: example-harm-events.ttl, label: Example events }
---

## Namespace

```turtle
@prefix rho: <https://www.epistemic-ontology.net/record-harm#> .
```

A hash namespace: dereferencing any term — for example `…/record-harm#Destruction`
— returns the whole ontology document.

> **Migration note.** This vocabulary was drafted under the placeholder
> `http://example.org/record-harm-ontology#`. The copies served here are
> rewritten to the permanent base at staging time, and the build fails if any
> `example.org` IRI survives. Adopting the permanent base *in the source
> repository* is that ontology's own v4.0 decision — v3.0 went to the prime-set
> correction described below.

## Prime harms

Six, since v3.0. `rho:Suppression` was a composite until then, said to build
upon `rho:Omission` — a category error on the ontology's own definitions, since
nothing is excluded *from* a suppressed record: it is complete, unmodified and
merely out of reach. It was promoted because it is also the only prime
attacking `rho:Accessibility`, which no prime had targeted at all; the
composite had been hung off omission for want of anywhere else to attach.

| Term | Meaning |
|---|---|
| `rho:Destruction` | Annihilation of the record — removes its existence. |
| `rho:Fabrication` | Creation of a record that never legitimately existed. |
| `rho:Alteration` | Modification of a genuine record's content or metadata. |
| `rho:Omission` | Deliberate exclusion of elements that should be present — where *elements* includes a record's internal relations, ordering and adjacent metadata, not only its content. |
| `rho:Denial` | Refusing to acknowledge a record's existence or validity. |
| `rho:Suppression` | Severing the channel between an intact record and an observer — classifying, burying, withholding. |

## Composite harms

Built from primes via `rho:buildsUpon` — `rho:Repudiation`, for instance, builds
upon `rho:Denial` and `rho:Fabrication`. Composite membership is
reasoner-derivable: any harm with a `buildsUpon` edge. Note that `buildsUpon` is
**presupposition, not subsumption**; transitivity was dropped deliberately to
stay inside OWL 2 DL.

## Layers

| Term | Meaning |
|---|---|
| `rho:RecordHarm` | The harm-type taxonomy (Prime / Composite). |
| `rho:HarmEvent` | A specific occurrence against a real record — date, perpetrator, severity. |
| `rho:HarmPattern` | A recurring bundle of co-occurring harms, such as a cover-up. |
| `rho:RecordAspect` | SKOS scheme of attacked aspects: existence, authenticity, integrity, accessibility, context, trustworthiness. |
| `rho:Record` | The thing harmed. Since v3.1 it has structure of its own: `rho:hasElement` for records made of records, `rho:bearer` for where a record lives. |

## Where a record lives

Added in v3.1. A record is borne by an agent — `rho:bearer` — and that one
property carries the whole distinction between a record held **inside an
agent** (a memory, a belief, a private ledger: one individual bearer) and one
held **inside a community** (a register, an archive: many bearers, or a single
collective bearer). Records can also contain records, via `rho:hasElement`, so
a community's register is a record in its own right rather than a bag of them.

The distinction needed no new harm. Every case lands on a prime already there:

| | |
|---|---|
| forgetting | `rho:Destruction` |
| confabulated memory | `rho:Fabrication` |
| self-deception | `rho:Denial` |
| repression | `rho:Suppression` |
| testimony kept out of a register | `rho:Omission` *from that register* |

So location is a property of the record, not a dimension of harm. What it does
make expressible for the first time is **self-directed harm** — a `HarmEvent`
whose perpetrator is also the bearer of the record it harms. Repression is
suppression with the perpetrator inside.

Two boundaries are deliberate. A private memory is **not** a suppressed record:
suppression means access was severed from someone who would otherwise have had
it, which is a change in the configuration, not the configuration itself. And
an agent who witnesses something and records nothing harms no record, because
there is no record — pure non-creation sits outside the vocabulary.

## Relation to the Record Ontology

The two vocabularies are **two readings of the same web**, and the translation
between them is written out in full as the harm dictionary in `ROOT.md` §18.

Record-harm's primes are **act-shaped** — what a perpetrator does to an artifact.
The Record Ontology's cuts are **warrant-shaped** — where in the web the
incoherence lands. The spine of the dictionary is a single claim:

> Every prime harm is a legitimate web operation with its escalation record
> removed.

Puncturing is a storage decision; destruction is the non-regenerable residue
lost. Supposition is worn openly; fabrication is the pretender transmitting
unearned warrant. Retraction appends a new moment; alteration rewrites an old
one. A stub is a skip that became a record; omission is the skip left
unrecorded. Exorcism withdraws standing by a verdict; denial refuses standing
without one. The act was never the harm — concealment is.

That is also why both survive. This web **computes the incoherence**;
record-harm **names the act and the actor**. A `HarmEvent` has a perpetrator, a
date and a severity — attribution content a court or an archive genuinely needs,
and which the Record Ontology deliberately refuses to compute: there, harm is
detected, never charged.

[Read the post on the harm dictionary →](/blog/harm-is-an-operation-minus-its-record/)

## Further reading

- [Querying record harm](/record-harm/queries/) — worked SPARQL for harm
  dependencies, aspect coverage, events, patterns, and where a record lives.
  The IRIs are the permanent ones, so the queries run against what is served
  here.
- [Record harm compared](/record-harm/comparison/) — the mapping to STRIDE, the
  CIA triad, InterPARES diplomatics and spoliation doctrine, including the two
  things this vocabulary deliberately does not cover.
- [Architecture and design decisions](https://github.com/commuted/record-harm-ontology/blob/main/docs/ARCHITECTURE.md)
  — kept in the repository rather than published here. It is contributor
  documentation: the primality tests a new harm must pass, what counts as a
  breaking change, and the defects past versions shipped. Useful if you are
  extending the vocabulary, not if you are using it.

