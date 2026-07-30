---
slug: record
order: 1
title: Record Ontology
prefix: rec
namespace: https://www.epistemic-ontology.net/record#
primary_file: record-ontology.ttl
summary: >-
  A domain-neutral ontology of warranted record-structure — how agents warrant,
  compose, ground and revise records. It models the connective grammar of
  knowledge, not the things known.
badges: [OWL 2 DL, reasoner-validated, one class]
repo: https://github.com/commuted/record-ontology
license: { name: CC BY 4.0, url: "https://creativecommons.org/licenses/by/4.0/" }
cite_key: recordontology2026
cite_title: "The Record Ontology: A Domain-Neutral Model of Warranted Record-Structure"
cite_year: 2026
files:
  - { file: record-ontology.ttl, label: Ontology }
  - { file: examples/cogito.ttl, label: "Example — the cogito" }
  - { file: examples/historical-narrative.ttl, label: "Example — narrative DAG" }
  - { file: examples/neptune-discovery.ttl, label: "Example — Neptune" }
  - { file: examples/bohr-atom.ttl, label: "Example — the atom, 1885–1927" }
  - { file: examples/triangle-described.ttl, label: "Example — triangle described" }
  - { file: examples/saccheri.ttl, label: "Example — the promontory" }
  - { file: examples/kepler-mars.ttl, label: "Example — the war on Mars" }
  - { file: examples/cuban-missile.ttl, label: "Example — escalation" }
  - { file: examples/tonkin-consent.ttl, label: "Example — consent by omission" }
  - { file: examples/arith-properties.ttl, label: "Example — arithmetic properties" }
  - { file: examples/trig-basics.ttl, label: "Example — trigonometry" }
  - { file: examples/orbital-mechanics.ttl, label: "Example — orbital mechanics" }
---

## Namespace

A **hash namespace**: dereferencing any term — say `…/record#SelfVerifying` —
returns the whole ontology document, and your client resolves the fragment. The
recommended prefix is `rec:`.

```turtle
@prefix rec: <https://www.epistemic-ontology.net/record#> .
```

Every worked example is dereferenceable too, under a systematic IRI:

```turtle
@prefix ex: <https://www.epistemic-ontology.net/record/examples/neptune-discovery#> .
```

## The founding constraint

> No class may be defined by a relation to an object that lies outside all
> records.

This is the rule the whole ontology is shaped by. Records are named by what the
agent holds — form, warrant, givenness, relations to other records, pragmatic
adequacy — never by a certified correspondence to a thing-in-itself. It is built
**for an agent** (a person or an AI) and never steps outside one.

## The one class, and the one non-record

| Term | Meaning |
|---|---|
| `rec:Record` | The single class — a form, in a carrier, for an agent, at a level of abstraction. Records are made of Records. |
| `rec:Continuum` | The one thing that is *not* a record: the undivided ground a record's support is individuated from (`rec:TheContinuum`; disjoint from `rec:Record`). |
| `rec:Agent` | A person or an AI — the one a record is *for*, and the one who individuates a record's support from the Continuum. |

There is deliberately **no `Form` class**. The form-in-itself is no more
available to an agent than the thing-in-itself; a `Form` class would be the
*formal apple*. Everything an agent holds is a Record.

## Warrant — a triad, one value per limit

Warrant is an **attribute, not a kind**, so patchworks decompose: a real
artifact is formal at some joints and conventional at others.

| Value | True in virtue of | Reaches toward |
|---|---|---|
| `rec:Formal` | form — deductive; the triangle verifies itself | the form-in-itself *(excluded)* |
| `rec:Empirical` | givenness — the senses, an instrument; defeasible | the world-in-itself *(excluded)* |
| `rec:SelfVerifying` | the act of recording — the cogito | the Agent-in-itself — **not** excluded |

Two limits are excluded and never instantiated as classes. The third is not:
the Agent is the one thing given to itself, and self-verifying warrant is
exactly the warrant that reaches it.

## Inference, support, metadata

| Term | Meaning |
|---|---|
| `rec:Inference` | **Defined**, never a primitive kind: a Record with `rec:hasPremise` and `rec:concludes`. Carries a `rec:hasForce` — truth-preserving or ampliative. Chains form a derivation DAG. |
| `rec:hasProvenance` · `rec:hasLocus` | The dissolved *carrier*: provenance (whence) plus locus (where/when, agent-relative). There is no `Carrier` class. |
| `rec:formulation` | **The form as held** — the first datatype property (new in v0.6.0): a formula, a constraint list, a text. Opaque to the reasoner by design. |
| `rec:metadataOf` | A record about a record (sub-property of `rec:directedToward`). There is no metadata layer — only records directed at records. |
| the cogito | Not a class but a **pattern**: self-verifying warrant + reflexive provenance + self-directedness. It halts the support-regress in the *warrant*, not in a thing. |

The regress "what carries the carrier?" is not answered with another entity. It
stops at a warrant. Credit Descartes for the existence, Hintikka for the
warrant — and not the *res cogitans*: the cogito certifies *that* the agent is,
never *what* it is.

## Exercise or exorcise

`hasWarrant rec:Formal` is a **claim**, not a credential. A formally warranted
record's `formulation` should be a *description* that can be run:

> claim → **exercise** (run the description) → confirmed *or* **exorcised**

Never exercised means testimonially held — which is how most mathematics is in
fact carried. A failed exercise expels the *pretender*, not the record: the
document survives, records about it survive, but it can no longer transmit
support, and everything resting on it cascades away. Kempe's 1879 "proof" of the
four-colour theorem stood eleven years until Heawood exercised it; as of 1885,
trusting it was justified.

## The engine — dynamics over the statics

OWL DL is **monotonic**: it cannot retract. So all dynamics live in a
computational layer *over* the static ontology — the `engine/` package in the
source repository, never axioms in the Turtle. The same rule strikes twice, and
symmetrically: *dynamics* live over the statics because DL is monotonic;
*computation* lives over the statics because DL is decidable.

- **Revision log as the carrier of moments** — an append-only stream of ground
  assertions, retractions and decisions. Log position is order-derived time, and
  any state is computable *as of any moment*. Derived records never enter the
  log; they regenerate by replay.
- **Forks and corroboration** — structural detection deliberately over-detects,
  so rivalry is *declared*, as a logged decision. Corroboration is **temporal**:
  only empirical evidence first asserted *after* a fork opened can collapse it.
  The losing branch is eclipsed, never deleted.
- **Fidelity** — not probability-of-truth (that would be the apple in numeric
  dress) but invariance under the web's own dynamics, computed from the ATMS
  label: a record's minimal environments. Scalars are purpose-relative
  projections.
- **Identification** — rivals proven equivalent make the fork *dissolve* rather
  than collapse, and their environments pool. Matrix versus wave mechanics
  (1926) is the type case.

## Stance: between the OWL/DL and SKOS camps

**DL-in-form, ecumenical-in-content.** Every concrete choice here is the DL
choice: defined classes, reasoner re-derivation, `owl:disjointWith` with a
consistency check, `rdfs:label` rather than `skos:prefLabel`, and a deliberate
refusal to import SKOS because it is OWL Full.

But the standing schism is demoted from a *choice of framework* to the
`rec:hasWarrant` attribute: a DL hierarchy is a record warranted **formally**
(subsumption); a thesaurus is one warranted **empirically** (community-fixed,
defeasible — `skos:broader` is a curatorial edge, not a deductive one). A real
scientific taxonomy is both. The ontology does not take a side; it represents
the axis the camps fight over.

## Validation

```bash
pip install -r requirements-dev.txt
python scripts/validate.py
```

A pure-Python OWL 2 RL reasoner (`owlrl`, no Java) checks four things:

1. **Defined-class entailment** — strip the asserted `Inference` type and confirm
   the *definition* re-derives it, with a negative control.
2. **Cogito pattern** — the pattern holds, and a self-verifying *promise* is
   correctly **not** conflated with it.
3. **Consistency** — no individual is both `Record` and `Continuum`.
4. **Sub-property entailment** — every `metadataOf` edge entails `directedToward`.

## Status and open items

The conceptual source of truth is [`ROOT.md`](https://github.com/commuted/record-ontology/blob/main/ROOT.md)
in the source repository; this page summarises what is settled. Three markers
run through it — **settled** (encoded in the Turtle), **prototyped** (working
code in `engine/`), **unbuilt** (recorded as horizon).

Known open items: composition transitivity is left off on purpose; the
escalation and formation layer is recorded as horizon, not vocabulary; the
knowledge-automaton — a groomed web whose formal interior regenerates by
deduction — is an engine/asset question with no vocabulary proposed.
