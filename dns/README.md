# DNS records

Both domains are served by **Route 53**. As of 2026-07-31 neither carried any
mail records at all — no MX, no SPF, no DKIM, no DMARC — which means anyone
could send mail as `@epistemic-ontology.net` and every receiver would accept it
as unauthenticated-but-unchallenged. These records close that.

Apply them in the Route 53 console, or with `aws route53 change-resource-record-sets`
if you have credentials. Then verify with `./dns/check-dns.sh`.

---

## epistemic-ontology.org — lock down (ready to apply)

This domain only 301-redirects to the .net. It will never send or receive mail,
so it gets the complete "no mail here, ever" set. Nothing depends on a provider,
so these values are final.

| Name | Type | TTL | Value |
|---|---|---|---|
| `epistemic-ontology.org` | MX | 3600 | `0 .` |
| `epistemic-ontology.org` | TXT | 3600 | `"v=spf1 -all"` |
| `_dmarc.epistemic-ontology.org` | TXT | 3600 | `"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; rua=mailto:REPORTS@example.com"` |
| `*._domainkey.epistemic-ontology.org` | TXT | 3600 | `"v=DKIM1; p="` |

What each one does:

- **Null MX** (`0 .`, [RFC 7505](https://www.rfc-editor.org/rfc/rfc7505)) — a
  single dot as the exchange explicitly declares the domain accepts no mail.
  Senders fail immediately instead of retrying for days.
- **`v=spf1 -all`** — no host anywhere is authorised to send as this domain.
- **DMARC `p=reject`** — tell receivers to reject anything that fails. `sp=reject`
  extends it to subdomains; `adkim=s`/`aspf=s` require strict alignment.
- **Wildcard DKIM with an empty `p=`** — a published revocation: any selector a
  spoofer invents resolves to a key that is explicitly void.

Replace `REPORTS@example.com` with a real address to receive aggregate reports,
or drop `rua=` entirely if you do not want them.

---

## epistemic-ontology.net — depends on the mail decision

The intent is **server-generated alerts**, no mailbox. Two constraints, both
verified against Proton's documentation on 2026-07-31:

1. **SMTP submission is Proton Business only.** Sending from a script or server
   needs an SMTP token, and tokens are not available on free or standard paid
   plans (Mail Plus, Unlimited).
2. **Proton requires MX records** to activate a custom domain. A null MX
   contradicts that, so "Proton, sending only, receives nothing" is not a
   configuration Proton supports.

So the honest fork:

### Option A — Proton Business (mailbox + server sending)

Add the domain in Proton, then copy the account-specific values it gives you.
Only the DMARC record below is not account-specific.

| Name | Type | Value |
|---|---|---|
| `@` | TXT | `protonmail-verification=…` *(from Proton)* |
| `@` | MX | *(two records, from Proton)* |
| `@` | TXT | `v=spf1 include:_spf.protonmail.ch ~all` |
| `protonmail._domainkey` | CNAME | *(from Proton)* |
| `protonmail2._domainkey` | CNAME | *(from Proton)* |
| `protonmail3._domainkey` | CNAME | *(from Proton)* |
| `_dmarc` | TXT | `v=DMARC1; p=quarantine; rua=mailto:you@epistemic-ontology.net` |

All three DKIM records are required, and there must be exactly **one** SPF
record on the name — a second one invalidates both. Start DMARC at
`p=quarantine` (Proton's own recommendation) or `p=none` while you watch
reports, and tighten to `p=reject` once alerts are landing cleanly.

### Option B — Amazon SES for alerts, no mailbox

The domain sends alerts and receives nothing. SES is in the same AWS account as
this zone, so it can write its own DKIM records during verification.

| Name | Type | Value |
|---|---|---|
| `@` | MX | `0 .` — receives nothing |
| `@` | TXT | `v=spf1 include:amazonses.com -all` |
| `<token>._domainkey` | CNAME | ×3, created by SES during domain verification |
| `_dmarc` | TXT | `v=DMARC1; p=reject; sp=reject; rua=mailto:you@…` |

Note SES starts in sandbox mode: until you request production access it will
only deliver to addresses you have verified — which is fine for alerts to one
inbox, and is arguably the safer default.

### Option C — lock .net down too, alert from elsewhere

Identical to the .org table above. Alerts then come from an account that has
nothing to do with this domain. Least work, least to maintain, and the domain
becomes unspoofable immediately.

---

## Verifying

```bash
./dns/check-dns.sh                    # both domains
./dns/check-dns.sh epistemic-ontology.org
```

It reports what is published and flags what is missing or wrong: multiple SPF
records, a missing null MX, a DMARC policy weaker than intended. DNS changes
take up to the previous record's TTL to propagate, so allow an hour before
trusting a negative result.
