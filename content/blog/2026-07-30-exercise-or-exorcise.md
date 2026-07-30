---
title: Exercise or exorcise
date: 2026-07-30
seq: 2
tags: [design, warrant]
summary: >-
  v0.6.0 added one datatype property and a discipline that goes with it. Formal
  warrant is a claim, not a credential: run the description or hold the record
  testimonially — and be honest about which.
reading:
  - { title: "Record Ontology", url: "/record/" }
  - { title: "Arithmetic Companion", url: "/arith/" }
  - { title: "triangle-described.ttl", url: "/record/examples/triangle-described.ttl" }
---

A Record is defined as *a form, in a carrier, for an agent, at a level of
abstraction*. For four versions, every record in every fixture had no form.

They had labels — prose glosses for humans. They had structure — premises,
conclusions, warrants, provenance. But the actual content, the thing the record
was a record *of*, lived nowhere in the graph. The energy levels in the atom
fixture were a string in an `rdfs:label`. The triangle's three sides were a
comment. An ontology of forms-in-carriers contained no forms.

v0.6.0 closes that with a single datatype property, the first in the vocabulary:

```turtle
rec:formulation a owl:DatatypeProperty ;
    rdfs:domain rec:Record .
```

**The form as held, serialized.** A formula, a constraint list, a data table, a
text. It is not mathematics-specific — a letter's formulation is its text.

Note what it is not. It is not the form-in-itself. It is the token serialization
of what *this agent holds*, which is why it passes the founding rule while a
`Form` class would not. The triangle gets content here. It still gets no birthday.

## The reasoner must not look inside

The first discipline riding along with `formulation` is that it is **opaque to
the classifier**, permanently and by design.

OWL 2 DL is decidable precisely because it excludes nearly all mathematics. A
formulation is a literal; nothing in the reasoner evaluates it. Execution belongs
to the engine.

This is the same architectural rule the ontology already lives under, striking a
second time and symmetrically:

> *Dynamics* live over the statics because DL is monotonic.
> *Computation* lives over the statics because DL is decidable.

One rule, two corollaries. The ontology holds structure; engines perform
operations.

## Warrant is earned

The second discipline is the interesting one, and it generalises something the
validator has always done. The validator refuses stipulated inference-hood: it
strips `a rec:Inference` from a record and demands the reasoner re-derive it from
the definition, with a negative control that must *not* be derived.

Say the same thing about formal warrant. `hasWarrant rec:Formal` is a **claim**.
Exercising the formulation — running its description, checking that it closes —
is what confirms the claim.

> claim → **exercise** → confirmed, *or* **exorcised**

with a third state sitting before the fork, and it is the most common one:
**never exercised**, which means testimonially held. That is not a failure state.
Most mathematics-as-held is testimonial. You did not re-derive the theorems you
use; you received them through a chain of agents and trusted the chain. The
capacity to complete a formal record internally is a *capacity*, rarely
exercised. Running the derivation converts testimonial holding into formal
holding — which is exactly what executable content does when it is added to a
fixture.

The point of the vocabulary is not to shame testimonial holding. It is to make it
**visible**, so that "formally warranted" stops silently meaning two different
things.

## What exorcism expels

Not the record. The **pretender** — formal warrant worn without the form.

Kempe published a proof of the four-colour theorem in 1879. It stood for eleven
years, until Heawood exercised it in 1890 and found the flaw. The paper is a
real, historically important record; records *about* it preserve the history; the
mathematics it developed went on being useful. What is withdrawn is its formal
warrant, **at a moment** — 1890, not retroactively.

That timestamp is the entire point. As of 1885, trusting Kempe was justified.
Judging the 1885 agent by the 1890 verdict is what this project calls the
temporal apple: hindsight dressed up as a god's-eye view along the time axis. The
log records when the verdict landed, and states are computed as-of a moment, so
the question "was this reasonable then?" has an answer that is not contaminated by
what came later.

After an exorcism the record survives but can no longer transmit support, and
everything resting on it cascades away. A repaired proof is a **new** record, not
a restoration.

The demo pair brackets the two outcomes at eyeball scale: the 3-4-5 triangle,
described in full and exercised from its own description, passes; the 2 = 1
pseudo-proof fails at its hidden division by zero and is expelled, taking its
dependents with it and leaving the publication record standing.

## Provenance couples differently to each warrant

One more thing fell out of taking formulation seriously, and it resolves an old
quarrel in passing. Formal warrant is agent-independent; provenance is
agent-relative and constitutive. There is no contradiction, because they answer
different questions — *how is it justified?* versus *whence did it come?* Ask how
tightly the two couple, and the warrant triad completes itself once more, one
value per limit:

| Warrant | Coupling to provenance | Consequence |
|---|---|---|
| formal | **decoupled** — survives total provenance loss | anonymous theorems are fine |
| empirical | **constituted** — lose the chain of custody, lose the warrant | anonymous data is worthless |
| self-verifying | **coincident** — the act is both genealogy and justification | an anonymous cogito is impossible |

Kant's version: knowledge that *begins with* experience need not *arise out of*
it. The rationalist and empiricist camps were each collapsing one of these
columns into the other.

The practical payoff is a storage rule, and it is exact:

> Drop whatever is provenance-decoupled. Keep whatever is
> provenance-constituted.

The formal interior of a web regenerates by deduction. The empirical leaves and
the trail of decisions do not. That is why a knowledge web can be compressed at
all — and, read the other way, it is precisely what destruction can and cannot
reach.
