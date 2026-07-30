---
slug: arith
order: 2
title: Arithmetic Companion
prefix: arith
companion: true
namespace: https://www.epistemic-ontology.net/arith#
primary_file: arith.ttl
summary: >-
  The formal object face, at representative scope: arithmetic operations in a
  definitional hierarchy bottoming at Peano, and expressions as formal Records
  composed of Records. A companion to the Record Ontology — attached, never
  absorbed.
badges: [OWL 2 DL, companion, representative]
repo: https://github.com/commuted/record-ontology
license: { name: CC BY 4.0, url: "https://creativecommons.org/licenses/by/4.0/" }
cite_key: arithcompanion2026
cite_title: "The Arithmetic Companion to the Record Ontology"
cite_year: 2026
files:
  - { file: arith.ttl, label: Companion ontology }
---

## Namespace

```turtle
@prefix arith: <https://www.epistemic-ontology.net/arith#> .
```

The companion `owl:imports` the [Record Ontology](/record/), so a reasoner
fetching this document will resolve `https://www.epistemic-ontology.net/record`
and get the base vocabulary back.

## Why a companion rather than an extension

The Record Ontology owns the **operation** face of the formal: `rec:Inference`,
premises, conclusions, force. What it never had was the **object** face — the
things inferences are about. This companion supplies that at representative
scope, and it is deliberately *attached, never absorbed*: the same pattern the
base ontology applies to every domain vocabulary. A domain plugs in through
warrant; it does not get merged into the core.

Scope is representative on purpose: integers, variables, the four operations,
equality. Not analysis, not set theory, not proofs-as-objects. Names align with
the OpenMath `arith1` content dictionary by `dc:source` pointer — never by
import, which is the SKOS lesson applied again.

## Two disciplines

**The reasoner checks shape, never value.** `2 + 2 = 4` is not a DL entailment;
OWL 2 DL is decidable precisely because it excludes nearly all mathematics.
Evaluation and exercise live in the engine, which *compiles* a described record
into a computer-algebra system and runs it.

**Expressions are Records composed of Records.** `arith:Expression` is a
subclass of `rec:Record`, and operands are `rec:composedOf` parts. So the
patchwork structure the base ontology already models carries mathematical
content without any new mereology.

## The definitional hierarchy

The four operations sit in a hierarchy that bottoms out at the Peano ground —
mathematics' own derivation web, formal all the way down. That makes it the
limiting case of the knowledge-automaton argument: a web whose interior is
entirely derivable, and therefore entirely puncturable, regenerating from the
ground by deduction alone.

## Exercise, compiled from the description

The point of describing a formal record in full — sides, angles, relationships,
the whole thing coming together — is that the description can be *run*. A
compiler walks the expression subgraph into sympy, so the exercise is *derived
from* the description rather than hand-written beside it. Two consequences:

- Closed-world well-formedness is a compile error. A missing operand is caught
  by the compiler, because OWL cannot see absence.
- **Performative provenance**: every exercise act is logged at a moment, so
  earned warrant has a genealogy, and each record carries a lifecycle standing —
  unexercised → confirmed / failed → exorcised.

The worked pair lives with the [Record Ontology examples](/record/#downloads):
the 3-4-5 triangle, described and exercised from its description, and the 2 = 1
pseudo-proof, which fails at its hidden division by zero and is expelled.
