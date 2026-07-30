---
title: Born at a permanent address
date: 2026-07-30
seq: 4
tags: [publishing, namespaces]
summary: >-
  Why the Record Ontology never had an example.org placeholder, what the
  redirect chain under this site actually does, and why a 303 is the right
  answer to a namespace IRI.
reading:
  - { title: "Using a vocabulary", url: "/using/" }
  - { title: "Record Ontology", url: "/record/" }
  - { title: "Record Harm Ontology", url: "/record-harm/" }
---

There is a debt you can take on in the first ten minutes of drafting an ontology
and pay off for years. It looks like this:

```turtle
@prefix rho: <http://example.org/record-harm-ontology#> .
```

Nobody means it permanently. It is a placeholder, to be replaced once the real
address exists. But an ontology's IRIs are not a naming convenience; they are the
identity of every term in it. The moment anyone imports your vocabulary, cites a
term, or stores an annotation, the placeholder is load-bearing. Changing it later
is not a rename — it is a breaking release that every downstream adopter has to
be dragged through.

The Record Harm Ontology was drafted that way, and it is still paying. What is
served from this site is a *rewritten copy*: the staging script substitutes the
permanent base and then refuses to finish if a single `example.org` IRI survives
the rewrite.

```bash
if grep -rInE "https?://[^ <>]*example\.org" "$DEST"; then
  echo "error: an example.org IRI is present in staged output" >&2
  exit 1
fi
```

That check is not paranoia. A hosted copy that quietly drifted back to the
placeholder would publish two different names for the same term, which is exactly
the failure the ontology itself calls **Forgery of Provenance**.

The Record Ontology was started later, and started at its final address:

```turtle
@prefix rec: <https://www.epistemic-ontology.net/record#> .
```

The consequence is small and pleasant. Its hosted copy is byte-identical to the
source file in its repository. There is no rewrite step, nothing to verify, and
no v3.0 migration waiting in its future. Its staging script only copies, and then
asserts that the permanent namespace is present.

## Why 303 and not 302

Ask this site for a namespace IRI and you get a `303 See Other`.

```bash
curl -sI -H "Accept: text/turtle" https://epistemic-ontology.net/record | head -2
```

The distinction matters more than it looks. `https://…/record` names *an
ontology*. It does not name a document. There is no file that "is" the Record
Ontology; there are serializations of it — Turtle today, possibly RDF/XML and
JSON-LD tomorrow — and a documentation page, and none of them is the thing
itself.

A `302` would say "the resource you asked for is temporarily over here", which
asserts that the ontology *is* a document that has moved. A `303` says something
weaker and true: the thing you asked about is not a document, but here is a
document *about* it. That is the whole content of the httpRange-14 resolution,
and it is one of the few places where a status code carries a genuine ontological
commitment.

The same document then serves every term, because the namespaces here are **hash**
namespaces. `…/record#Inference` never sends the fragment to the server at all;
you fetch the one document and your client resolves the fragment locally. One
round trip gets you the complete vocabulary. For vocabularies of this size that
is plainly the right trade; slash namespaces earn their keep at thousands of
terms, not dozens.

## The redirect chain, and why the old name still works

The IRIs were minted at `www.epistemic-ontology.net`. The canonical host is now
the apex, `epistemic-ontology.net`. Four names exist — the apex, `www`, and both
`.org` variants — and three of them permanently redirect to the fourth, as does
all plain HTTP.

So a minted term IRI resolves through one `301` to the apex, and then the `303`
negotiation. Two hops, both permanent, both cacheable.

It would have been tidier to mint at the apex. It is not worth "fixing". A
permanent identifier that you rewrite whenever a tidier form occurs to you is not
a permanent identifier — it is a mutable one with good intentions. The minted
form stays valid forever, because that is the only thing "permanent" can mean.

## What follows for anyone citing this

Cite the IRI, never the file path:

```bibtex
url = {https://www.epistemic-ontology.net/record}
```

not `…/record/record-ontology.ttl`. The IRI is what is promised. File layout is
an implementation detail, and this site has already moved files once: the worked
examples now live under `/record/examples/`, each at its own dereferenceable
namespace, because every one of them declares an IRI of the form

```turtle
@prefix ex: <https://www.epistemic-ontology.net/record/examples/saccheri#> .
```

and an address that a file declares as its own name ought to be an address that
answers. The old paths still redirect. They will keep redirecting.

## The general rule

Pick the permanent name before the first term is written. If you cannot — if the
domain is not registered, if the project might be renamed — then you do not yet
know what you are publishing, and it is cheaper to wait than to migrate.

The alternative is what this site demonstrates in miniature: one vocabulary that
is copied straight through, and one that is rewritten in flight, checked, and
still carrying a breaking release on its horizon. Both work. Only one of them was
free.
