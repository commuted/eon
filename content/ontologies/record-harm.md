---
slug: record-harm
order: 3
title: Record Harm Ontology
prefix: rho
namespace: https://www.epistemic-ontology.net/record-harm#
primary_file: record-harm-ontology.ttl
summary: >-
  A taxonomy of the ways an informational record can be damaged — prime harms
  (destruction, fabrication, alteration, omission, denial) and the composites
  built upon them — with SKOS vocabularies, SHACL validation and an event layer
  for specific occurrences.
badges: [OWL 2 DL, SKOS, SHACL]
repo: https://github.com/commuted/record-harm-ontology
license: { name: MIT, url: "https://opensource.org/licenses/MIT" }
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
> repository* is that ontology's own v3.0 decision.

## Prime harms

| Term | Meaning |
|---|---|
| `rho:Destruction` | Annihilation of the record — removes its existence. |
| `rho:Fabrication` | Creation of a record that never legitimately existed. |
| `rho:Alteration` | Modification of a genuine record's content or metadata. |
| `rho:Omission` | Deliberate exclusion of elements that should be present. |
| `rho:Denial` | Refusing to acknowledge a record's existence or validity. |

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
