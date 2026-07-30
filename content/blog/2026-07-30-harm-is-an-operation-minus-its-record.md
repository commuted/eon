---
title: A harm is a legitimate operation minus its escalation record
date: 2026-07-30
seq: 1
tags: [record-harm, design]
summary: >-
  Two ontologies published here cut the same territory differently — one
  act-shaped, one warrant-shaped. Writing the dictionary between them produced a
  single sentence that covers all five prime harms, and explains why neither
  vocabulary should absorb the other.
reading:
  - { title: "Record Harm Ontology", url: "/record-harm/" }
  - { title: "Record Ontology", url: "/record/" }
---

Two vocabularies are published at this namespace, and they were built from
opposite ends.

The [Record Harm Ontology](/record-harm/) is **act-shaped**. Its five prime harms
name what a perpetrator does to an artifact: destroy it, fabricate it, alter it,
omit from it, deny it. Its event layer carries a date, a perpetrator, a severity.
It is the shape an archivist or a court needs.

The [Record Ontology](/record/) is **warrant-shaped**. Its native cuts are about
where in a web an incoherence lands: a leaf lost, a moment rewritten, a skip left
unrecorded, a pretender's exercise failing. It has no harm vocabulary at all.

The obvious guess is that one should absorb the other — re-derive the harm
taxonomy from the record web and drop the duplicate. Writing out the translation
in full showed that this is wrong, and produced something better on the way.

## The sentence

Every prime harm is a **normal web operation with its explicitness removed**.

| The operation, recorded (legitimate) | The same operation, concealed (prime harm) |
|---|---|
| **puncture** — a storage decision; leaves and trail kept, interior regenerates | **Destruction** — the non-regenerable residue lost: empirical leaves, the escalation trail |
| **supposition** — stood on, worn openly; quarantined, transmits nothing | **Fabrication** — the pretender: unearned warrant transmitted into the held web |
| **retraction** — a new moment appended; old moments never rewritten | **Alteration** — a rewrite of old moments; change without a moment |
| **stub** — the skip that became a record: "X deferred, for Y, at moment m" | **Omission** — the unrecorded skip |
| **exorcism** — standing withdrawn *by a verdict*, logged at a moment | **Denial** — standing refused without a verdict |

Read down the right column and record-harm's five primes appear. Read across and
each is its left-hand twin with the escalation record deleted.

This matters because the left column is not a list of things to avoid. Excision
is **constitutive** — no record has total support, so something is always cut
away. Retraction is routine. Skips are mandatory for any finite agent; an agent
that never deferred anything would never finish anything. Puncturing is how a web
stays affordable.

The act was never the harm. **Concealment is.**

## Why the engine needs no harm vocabulary

Once the dictionary is written, the detectors turn out to already exist, because
each one is a discipline the web needed for its own sake:

- The **pretender alarm** — the generated test suites — is Fabrication's formal
  detector.
- The **consumption check** catches the subtler case: a fabrication whose content
  happens to be *true* and only whose genealogy is forged. A joint that restates
  its own conclusion is the undeclared twin of an honestly stated stub.
- **As-of-moment computation** catches Alteration. If states are computed at a
  moment and old moments are never rewritten, an anachronism is a contradiction
  rather than a suspicion.
- The **observation planner** renders Omission as the stub that isn't there: it
  can name what should have been recorded.
- The **puncture report's** must-keep partition says exactly what Destruction can
  and cannot reach.
- **Environment liveness** after an exorcism computes what a poisoned ground
  infects. "Doubt infects the whole" stops being a mood and becomes a map.

None of these were built as harm detection. They are the disciplines that make a
revisable web work at all, and harm detection is what they do incidentally. That
is the strongest argument that the factorization is real.

## Where the two shapes genuinely disagree

The isomorphism is in coverage, not in structure — and it does not preserve the
prime/composite distinction. Two disagreements are worth naming.

**Three acts collapse into one shape.** Fabrication, harmful Omission and harmful
Alteration are three distinct things to do to an artifact. Web-internally they
are one genus: **concealed escalation**. A trade-off made against the web and not
logged; a skip not recorded; a change not given a moment. To a perpetrator these
are different crimes. To the web they are the same lesion.

**Denial goes the other way, and instructively.** Record-harm promoted Denial to
a *prime* precisely because it involves no act of hiding, creating or modifying —
it looked irreducible as an act. Web-internally it reduces after all, one level
up. "That document is fake" is a record *directed at* a record: a
fabrication-charge the web does not corroborate. It is **Fabrication at the
meta-level**, a false posit whose content is another record's standing.

Prime in one factorization, composite in the other, and both correct in their own
shape. That is the cleanest evidence that these are two genuine factorizations
rather than one taxonomy and one paraphrase of it.

One composite does not survive translation at all. **Decontextualization** loses
its object: there is no metadata layer to strip, and the excision is already part
of the support. "Stripping context" is not a distinct operation on an intact
record — it is Alteration or Omission of the record itself.

## Why both vocabularies stay

The temptation was to re-derive record-harm and retire it. The dictionary argues
against that, because the act-shape carries exactly what the warrant-shape
deliberately refuses.

A `HarmEvent` has a **perpetrator**. It has a date and a severity. That is
attribution — and the Record Ontology forbids itself to compute it. Punitive
calculus is refused there on purpose; harm is *detected*, never *charged*. An
engine that computed blame would be claiming the standpoint that sees both the
shadow and what casts it, which is the one move the whole ontology is built to
avoid.

So the division of labour is clean, and it is a division rather than a merger:

> This web computes the incoherence. Record-harm names the act and the actor.

Two readings of the same web, kept apart on purpose — attached, never absorbed,
which is the same relation the [Arithmetic Companion](/arith/) has to the core.
The next release of record-harm keeps its taxonomy and re-grounds its definitions
through this table: correspondence language out, web-internal readings in.

And the dictionary settles one more thing by demonstration. It adds no
vocabulary to either ontology — a harm class would stamp per node what the web
already entails — and it needs no new code, because every detector in it was
already running. It is the compression argument applied to itself: one fewer
ontology to assert.
