---
title: The carrier, dissolved
date: 2026-07-30
seq: 3
tags: [design, foundations]
summary: >-
  v0.5.0 removed a class rather than adding one. What carries the carrier turned
  out to be the wrong question — the regress halts in a warrant, not in a thing,
  and the cogito is a pattern rather than a class.
reading:
  - { title: "Record Ontology", url: "/record/" }
  - { title: "cogito.ttl", url: "/record/examples/cogito.ttl" }
---

Every external record is borne by something. A letter needs paper, a measurement
needs an instrument and a log, a memory needs a nervous system. The support is
always **excised from the Continuum** — the undivided ground that is the one
thing in this ontology that is not a Record — and the excision is never clean.
The paper is still made of the world; nothing is causally sealed off.

So: what carries the carrier?

An earlier draft answered it the obvious way. There was a `Carrier` class, a
`borneBy` property, and the chain was grounded at the Agent. It typechecked. It
was also wrong twice over, and v0.5.0 reversed it — the release removed a class
instead of adding one.

## The discipline objection

The ontology has exactly one class, `Record`, and everything else is an
**attribute**. That is not minimalism for its own sake; it is what makes
patchworks decompose. A real artifact is formal at some joints and conventional
at others, and an ontology of *kinds* forces you to pick one label for the whole
thing. An ontology of attributes lets each joint carry its own warrant.

A `Carrier` class buys the regress-halt at the cost of that rule. And the carrier
does not need to be a relatum, because it factors cleanly into two attributes
already in hand:

- `rec:hasProvenance` — the genealogy. *Whence* was this form individuated from
  the Continuum?
- `rec:hasLocus` — *where and when* it is borne, agent-relative, never a
  certified position in space-time-in-itself.

Between them there is nothing left for a `Carrier` object to do. It was not a
thing; it was two questions wearing a noun.

## The over-capture objection

The second failure was sharper, and it came from a stress test rather than from
theory. The draft had a **defined** `Cogito` class: a Record borne by an Agent,
with self-verifying warrant. A reasoner would derive membership.

It derives too much. A **promise** is agent-borne and self-verifying — saying "I
promise" is what makes it true — and a promise is emphatically not the cogito. So
is a christening, a resignation, a bet. Every performative walks into the class
and the reasoner cannot tell them apart, because on the stated conditions there
is nothing to tell apart.

The fix was to stop trying to define it. The cogito is not a class; it is a
**pattern**:

1. self-verifying warrant,
2. reflexive provenance — the act that is its own genealogy,
3. self-directedness — the `directedToward` points at the agent's own existence.

Performatives share the *warrant* without matching the pattern. A promise is
directed at a future act, not at the promiser's existence, so it never coincides.
Demoting the cogito to a pattern dissolved the over-capture at the same stroke as
the discipline problem — which is usually the sign that the reversal was the
right one rather than merely a smaller one.

## Where the regress actually stops

Not at an entity. At a **warrant**.

"I think" is true in virtue of the act of recording it, and its provenance *is*
that very act. Its support is not a substrate it has but the thinking it is —
which is, if anything, more faithful to Descartes than positing a
carrier-substance underneath.

At that one point the roles this ontology otherwise keeps carefully apart all
land on the same object: the *for-whom*, the *intentional object*, and the
*provenance* are the agent. It is indubitable **because** of the collapse.

Structurally, that gives the system its shape: a coherentist web with exactly one
foundationalist anchor, and the anchor placed in a warrant rather than in a
class. It also preserves the asymmetry the ontology cares most about. Two limits
are excluded — the world-in-itself and the form-in-itself — and approached only
asymptotically. The **Agent**-in-itself is not excluded. It is the one thing given
to itself, and self-verifying warrant is precisely the warrant that reaches it.

## How much Descartes to credit

The fixed point, not the substance.

The cogito certifies *that* the agent exists. It does not certify *what* the
agent is. Descartes' slide from "I am" to "I am a thinking substance" is a
different move entirely, and by this ontology's lights it is an **apple** — a claim
to the god's-eye standpoint that sees both the shadow and what casts it. Finitude
survives even here: a certain anchor of existence, not a fully known object.

Credit Hintikka for the warrant, incidentally, not Descartes. The cogito works as
a *performance*, not as an inference; there is no suppressed premise from which
"I am" is derived.

And the twin question never arises. If the mind is not a second substance, what
is the body? Nothing needs answering, because nothing was split. The body is
Continuum, approached the way any worldly object is — empirically, defeasibly,
never fully held. What is special about the agent was never a second kind of
stuff opposed to a first; it is the warrant-pattern above, sitting alongside all
the ordinary empirical records the agent also holds about its own body. Descartes
needed two substances to solve an interaction problem his own split created. Do
not create the split and neither the problem nor its machinery ever shows up.

## What is actually in the file

```turtle
rec:hasLocus a owl:ObjectProperty .
```

That is the whole positive change. No `Carrier`, no `Cogito`, no
`FoundationalCarrier`, no `borneBy`. The cogito is recognised by its pattern, and
the validator checks exactly that: the pattern holds in `cogito.ttl`, and a
self-verifying *promise* in the same file is correctly **not** conflated with it.

A negative control in a test suite is worth more than a class in a hierarchy.
