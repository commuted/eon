---
slug: using
title: Using a vocabulary
lead: >-
  Every term IRI published here resolves to both human documentation and machine
  RDF, by content negotiation, from one permanent address.
description: >-
  How to dereference, import and cite the ontologies published at
  epistemic-ontology.net — content negotiation, hash namespaces, and CORS.
---

## Dereferencing

Ask for what you want with an `Accept` header. The namespace IRI answers with a
`303 See Other` pointing at the representation you asked for.

```bash
# Human-readable documentation
curl -L -H "Accept: text/html" https://epistemic-ontology.net/record

# Turtle (also: application/rdf+xml, application/ld+json, application/n-triples)
curl -L -H "Accept: text/turtle" https://epistemic-ontology.net/record
```

Use `-L`, or you will only see the redirect. A `303` is the correct status here
rather than a `302`: the namespace IRI names an *ontology*, not the document that
describes it, and a `303` is exactly the way to say "the thing you asked about is
not a document, but here is a document about it".

## Hash namespaces

All vocabularies here use **hash** namespaces:

```turtle
https://www.epistemic-ontology.net/record#Inference
https://www.epistemic-ontology.net/record-harm#Destruction
https://www.epistemic-ontology.net/arith#Expression
```

The fragment never reaches the server. Dereferencing any single term therefore
fetches the *whole* vocabulary document, and your client resolves the fragment
locally. That is a deliberate trade: one round trip gets you every term, which is
the right shape for vocabularies of this size.

## Importing

The serializations are served with correct media types and
`Access-Control-Allow-Origin: *`, so browser-based RDF tooling and
`owl:imports`-by-URL both work without a proxy.

```turtle
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix rec:  <https://www.epistemic-ontology.net/record#> .

<https://example.com/my-ontology>
    a owl:Ontology ;
    owl:imports <https://www.epistemic-ontology.net/record> .
```

Note the import target has **no** trailing `#`: import the ontology IRI, not the
namespace prefix.

Loading directly with [rdflib](https://rdflib.readthedocs.io/):

```python
from rdflib import Graph

g = Graph().parse("https://epistemic-ontology.net/record", format="turtle")
print(len(g), "triples")
```

## Worked examples

Every worked example carries its own permanent namespace, formed
systematically from its name:

```turtle
@prefix ex: <https://www.epistemic-ontology.net/record/examples/neptune-discovery#> .
```

These dereference the same way as the vocabularies. They are illustrations, not
normative parts of any ontology — nothing imports them.

## Canonical host and redirects

The canonical host is the apex, `https://epistemic-ontology.net`. Three other
names (`www`, and both `.org` variants) permanently redirect to it, as does all
plain HTTP.

The namespace IRIs were minted at `www.epistemic-ontology.net`, so they resolve
through one permanent `301` to the apex and then the `303` negotiation. The
minted form stays valid forever; that is what "permanent" has to mean.

## Citing

Cite the **namespace IRI**, never a file path. The IRI is the identifier that is
promised to keep resolving; file layout is an implementation detail and may
change as serializations are added.

Version numbers shown on each ontology page are read directly out of the
published Turtle's `owl:versionInfo` at build time, so a version quoted on this
site is the version actually being served.

## Licensing

| What | Licence |
|---|---|
| Record Ontology and Arithmetic Companion (ontology and docs) | CC BY 4.0 |
| Record Ontology scripts and engine | MIT |
| Record Harm Ontology | MIT |

Attribution for CC BY 4.0 material:

> "The Record Ontology — epistemic-ontology.net" —
> https://www.epistemic-ontology.net/record
