# Business Model and Unit Economics
**Product:** School-parent communication SaaS for Spanish preschools (ages 0–6)
**Date:** March 2026
**Stage:** Pre-revenue, solo founder, building V1

---

## 1. Business Model Summary

### How We Make Money

Flat-rate monthly SaaS subscription paid by the school. Parents always use the product for free. Revenue is 100% B2B — the school is the customer; parents are the beneficiaries whose satisfaction drives retention.

### Who Pays, Who Uses, Who Decides

| Role | Who They Are | Their Job to Be Done |
|---|---|---|
| Buyer | School director (directora) | Reduce admin burden, improve parent satisfaction, look professional |
| User (primary) | Teachers / pedagogical staff | Log daily activities, send messages, document attendance |
| User (secondary) | Parents | See what their child did today, receive news, communicate with school |
| Influencer | AMPA (parent association) | Occasionally advocates for or against tools adopted by school |

The decision is made by one person: the directora. She controls the budget. She signs. She does not need IT approval, a procurement committee, or a CFO sign-off. This is both the opportunity (short sales cycle if she wants it) and the risk (she's spending personal/operational money, not a corporate budget).

### Pricing Philosophy: Why Flat-Rate

Flat-rate wins over per-child pricing for three reasons that matter in this specific market:

1. **Predictability for the buyer.** A Spanish guardería director manages a tight monthly operating budget. A fixed invoice for €59/month behaves like her accountant invoice or her cleaning service contract — she knows exactly what she's committing to. Per-child pricing creates anxiety: "What happens if I enroll 5 more kids? Does the software bill go up?" Flat-rate removes that objection entirely.

2. **Simplicity for the seller (you).** You're one founder doing direct sales. Flat-rate means no usage tracking disputes, no invoice surprises, no per-seat arguments. The demo and the close are cleaner.

3. **Upsell mechanics are preserved.** Flat-rate at the school level doesn't preclude per-school-size pricing tiers later. You can introduce a "Plan Centro Plus" for larger schools when you have the data to justify it. Per-child pricing is harder to walk back once schools have internalized it.

The tradeoff: a 200-child school pays the same as a 60-child school at the same tier. You will eventually want a volume tier for larger schools. That's fine — solve it in Year 2.

---

## 2. Pricing Model Deep Dive

### Recommended Pricing Tiers

#### Free Tier — "Plan Gratuito"

| Dimension | Limit |
|---|---|
| Children enrolled | Up to 15 |
| Teachers / staff accounts | Up to 3 |
| Parent accounts | Unlimited |
| Daily diary entries | Yes |
| Messaging (school-to-parent) | Yes |
| Media uploads (photos/videos) | Yes, with storage cap (2 GB/school) |
| Attendance tracking | Yes |
| Billing / invoicing module | No |
| Analytics dashboard | No |
| Priority support | No |
| Custom branding | No |

**Purpose:** Validate product-market fit with real schools. Drive word-of-mouth among directors who talk to each other. Build the conversion pipeline.

**Hard limit logic:** 15 children is the right free limit because it covers the smallest guarderías (some infant rooms run 8–12 children) but ensures that any school with a meaningful operation — say, 2 classrooms, 25+ kids — hits the wall naturally. It is not artificial friction; it maps to real school sizes.

#### Paid Tier — "Plan Centro"

**Price: €59/month (monthly billing) | €49/month (annual billing, paid upfront = €588/year)**

| Dimension | Included |
|---|---|
| Children enrolled | Up to 80 |
| Teachers / staff accounts | Unlimited |
| Parent accounts | Unlimited |
| All Free features | Yes |
| Billing / invoicing module | Yes |
| Analytics dashboard (basic) | Yes |
| Attendance reports (PDF export) | Yes |
| Priority email support | Yes (response within 24h) |
| Custom school branding | Yes |
| Storage | 20 GB/school |

**Why €59 and not €49 or €69?**

Anchoring against what a Spanish guardería director already pays monthly:
- Gestoría / accountant: €80–150/month
- Cleaning service: €200–400/month
- Telefónica broadband + phone: €50–80/month
- Seguridad Social for one part-time employee: €200+/month

At €59/month, you are cheaper than her accountant, comparable to her internet bill, and delivering something that touches every parent in her school every day. The psychological reference is: "this costs less than my accountant and my accountant doesn't make parents happy."

At €49 you leave money on the table and signal uncertainty about your value. At €69 you introduce hesitation in a market where trust is still being built. €59 is clean, credible, and slightly below the psychological €60 round-number threshold.

**Annual discount:** 17% discount (monthly equivalent of €49 vs €59). Offering annual upfront solves your cash flow problem and de-risks churn. Target 40% of conversions on annual plans once product confidence is established — push for this from Month 6 onward.

#### Volume Tier — "Plan Cadena"

**Price: Custom, starting at €129/month per school (negotiated for 3+ school chains)**

Available for schools with 80+ children or multi-school operators. Not productized in Year 1 — handle manually when the conversation comes up. The floor is €129/month per location because below that, the support complexity of enterprise relationships doesn't justify the margin.

### The Upgrade Trigger

The single most important free-to-paid conversion lever is the **billing/invoicing module**.

In Spain, guarderías must issue monthly invoices to parents for tuition fees. This is mandatory, repetitive, and painful — most directors do it in Excel or a generic invoicing tool. Putting a clean, automated invoicing module behind the paid tier means:

- Directors on the free tier see the feature locked, grayed out, with a clear message: "Automatiza tus recibos mensuales con Plan Centro"
- They understand the value immediately — it's not a vague "analytics dashboard," it's hours of admin work eliminated every month
- The ROI conversation becomes: "If this saves your secretary 3 hours/month, it pays for itself at any wage above €20/hour"

Secondary upgrade triggers: custom branding (directors who care about school image), PDF attendance reports for inspection compliance, and priority support once they've had a bad experience with async resolution.

### Annual vs. Monthly Billing

Offer both from Day 1. Defaulting the checkout flow to annual (with monthly as the "more expensive" option displayed second) increases annual uptake significantly. Frame it as: "Ahorra €120 al año con el plan anual."

For the first 8 Escuelas Fundadoras pilot schools, the conversion offer at Month 12 should be annual billing at a 20% loyalty discount (€47/month equivalent, €564/year) — lower than standard annual to reward early adopters and smooth the free-to-paid psychological jump.

### Pricing Psychology for the Directora

She is spending operational money, often her own school's money, and she is accountable for it. What makes pricing feel fair and trustworthy to her:

1. **No surprise bills.** Fixed price, always. If storage or users ever become an issue, warn her with 30 days notice and offer a graceful upgrade path. Never auto-charge overages.
2. **Monthly cancellation possible.** Even if you push annual, she needs to know she can leave. A school director will not sign anything that feels like a trap. Annual billing with a refund policy for the unused months is more credible than an annual lock-in.
3. **Invoice / factura always available.** She needs a proper factura for her accountant. Your billing system (Stripe) must generate a valid Spanish factura automatically with your NIF, her NIF, and the correct IVA line (21% IVA for software SaaS). This is not optional — failing here breaks trust immediately.
4. **Price stability.** Don't change pricing on existing customers in Year 1. If you need to raise prices in Year 2, grandfather existing schools for 12 months. Spanish SME owners have long memories for suppliers who surprised them with a price increase.

---

## 3. Unit Economics

### Base Case Assumptions

- Average paid school: 40 children
- Plan Centro monthly price: €59/month
- Annual billing mix: 30% annual (Month 1-6), 40% annual (Month 7+)
- Infrastructure: €150/month total, shared across all active schools
- Founder support time: 1 hour/month per paying school at an opportunity cost of €40/hour

### Per-School Economics

| Metric | Calculation | Value |
|---|---|---|
| MRR per school | €59/month | €59.00 |
| ARR per school | €59 x 12 | €708.00 |
| Infrastructure cost per school (at 20 paying schools) | €150 / 20 | €7.50 |
| Infrastructure cost per school (at 50 paying schools) | €150 / 50 | €3.00 |
| Infrastructure cost per school (at 100 paying schools) | €150 / 100 | €1.50 |
| Support time cost per school/month | 1h x €40 | €40.00 |
| Total COGS per school/month (at 50 schools) | €3.00 + €40.00 | €43.00 |
| Gross profit per school/month (at 50 schools) | €59.00 - €43.00 | €16.00 |
| Gross margin per school (at 50 schools) | €16 / €59 | 27% |

**Note on support time:** This is the biggest variable. The €40/hour assumption reflects founder opportunity cost, not a cash cost. As the product matures and onboarding is automated, support time should drop to 20–30 minutes/school/month in Year 2, improving gross margin significantly.

| Schools | Infra/School | Support/School | COGS/School | Gross Margin |
|---|---|---|---|---|
| 10 | €15.00 | €40.00 | €55.00 | 7% |
| 25 | €6.00 | €40.00 | €46.00 | 22% |
| 50 | €3.00 | €40.00 | €43.00 | 27% |
| 100 | €1.50 | €30.00 | €31.50 | 47% |
| 200 | €0.75 | €20.00 | €20.75 | 65% |

**Key insight:** This is a support-cost business in the early stage, not an infrastructure-cost business. Invest in documentation, onboarding videos, and a self-serve help center early — every hour of support you eliminate goes directly to margin.

### Customer Acquisition Cost (CAC)

Direct outreach model, solo founder. No paid acquisition.

**Outreach funnel assumptions:**
- 40 cold emails/week = 160/month
- Email to demo conversion: 3% = ~5 demos/month
- Demo to paid conversion: 35% = ~1.7 new paid schools/month
- Total outreach effort per acquired school: roughly 94 emails sent
- Time per email (research + personalization): 10 minutes = 15.7 founder hours per acquired school
- Demo time: 45 minutes x 2 demos per close (accounting for no-shows) = 1.5 hours
- Follow-up and close: 1 hour
- Onboarding: 1.5 hours
- **Total founder hours per acquired customer: ~20 hours**
- Opportunity cost at €40/hour = **€800 per customer**

| CAC Component | Hours | Cost |
|---|---|---|
| Research + outreach (94 emails x 10 min) | 15.7h | €628 |
| Demo calls (2 demos x 45 min) | 1.5h | €60 |
| Follow-up and close | 1.0h | €40 |
| Onboarding | 1.5h | €60 |
| **Total CAC** | **19.7h** | **€788** |

Use **€800 CAC** as the working assumption. This will drop as you build reputation and inbound leads emerge from word-of-mouth.

**Out-of-pocket CAC:** Near zero. Cold email tools (€30–50/month), potential postal mail for physical outreach campaigns (~€1–2/letter). Not material.

### Lifetime Value (LTV)

**LTV = MRR x Gross Margin % x (1 / Monthly Churn Rate)**

Gross margin at 50 schools: 27%. Using a steady-state 65% margin assumption for LTV modeling (Year 2+ support efficiency).

| Scenario | Avg Retention | Monthly Churn | LTV (65% margin) | LTV (27% margin) |
|---|---|---|---|---|
| Conservative | 18 months | 5.6% | €689 | €286 |
| Base | 30 months | 3.3% | €1,157 | €480 |
| Optimistic | 48 months | 2.1% | €1,829 | €758 |

### LTV:CAC Ratio

| Scenario | LTV (65% margin) | CAC | LTV:CAC | Assessment |
|---|---|---|---|---|
| Conservative | €689 | €800 | 0.86x | Below break-even — fix churn or CAC |
| Base | €1,157 | €800 | 1.45x | Marginal but improving with scale |
| Optimistic | €1,829 | €800 | 2.29x | Healthy for early stage |

**Honest assessment:** The conservative scenario is not viable at current assumptions. This means two things: (1) churn management is existential, not optional, and (2) CAC must come down as word-of-mouth compounds. The business works in the base case and works well in the optimistic case. Focus on retention above all else in Year 1.

### Payback Period

**Payback = CAC / (MRR x Gross Margin %)**

Using steady-state 65% margin:

| CAC | MRR | Gross Margin | Monthly Contribution | Payback Period |
|---|---|---|---|---|
| €800 | €59 | 65% | €38.35 | 20.9 months |
| €800 | €59 | 45% | €26.55 | 30.1 months |
| €800 | €59 | 27% | €15.93 | 50.2 months |

**Key implication:** At current margins, payback is long. This is normal for bootstrapped SaaS in Year 1 — but it means you cannot afford significant churn. Every school you lose before Month 21 represents a net loss on that customer relationship.

---

## 4. MRR / ARR Projections

### Key Assumptions

| Assumption | Value | Notes |
|---|---|---|
| Weekly cold emails sent | 40 | Realistic for solo founder alongside building |
| Email to demo rate | 3% | Conservative for cold outreach to SME directors |
| Demo to paid rate | 35% | Assumes solid demo script and genuine pain |
| Free tier signups per month (organic) | 2 | Word-of-mouth, directory listings |
| Free-to-paid conversion rate | 15%/quarter | Of free schools that have been on free for 90+ days |
| Monthly churn rate (paid) | 3% | Base case |
| Average MRR per school | €59 | Blended (some annual, some monthly) |
| Escuelas Fundadoras pilots | 8 schools, start Month 1 | Free for 12 months |
| Pilot-to-paid conversion at Month 12 | 70% | Expect 5–6 of 8 to convert |
| Infrastructure cost | €150/month flat | Stable through ~200 schools |

### Scenario Definitions

- **Conservative:** Email-to-demo 2%, demo-to-paid 25%, churn 4.5%, pilot conversion 50%
- **Base:** Email-to-demo 3%, demo-to-paid 35%, churn 3%, pilot conversion 70%
- **Optimistic:** Email-to-demo 4%, demo-to-paid 45%, churn 2%, pilot conversion 85%

### Base Case — Month-by-Month, Year 1

New paid schools per month from outreach: 160 emails x 3% x 35% = 1.68, rounded to ~2/month for base case.
Free-to-paid conversions begin Month 4 (schools that signed up free in Month 1 hit 90-day mark).

| Month | New Paid (Outreach) | New Paid (Free Conversion) | Churned | Total Paying | MRR | ARR |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 | 0 | 0 | €0 | €0 |
| 2 | 1 | 0 | 0 | 1 | €59 | €708 |
| 3 | 2 | 0 | 0 | 3 | €177 | €2,124 |
| 4 | 2 | 1 | 0 | 6 | €354 | €4,248 |
| 5 | 2 | 1 | 0 | 9 | €531 | €6,372 |
| 6 | 2 | 1 | 0 | 12 | €708 | €8,496 |
| 7 | 2 | 1 | 0 | 15 | €885 | €10,620 |
| 8 | 2 | 1 | 0 | 18 | €1,062 | €12,744 |
| 9 | 2 | 1 | 1 | 20 | €1,180 | €14,160 |
| 10 | 2 | 1 | 1 | 22 | €1,298 | €15,576 |
| 11 | 2 | 1 | 1 | 24 | €1,416 | €16,992 |
| 12 | 2 | 5 (pilots convert) | 1 | 30 | €1,770 | €21,240 |

Notes: Month 1 is setup and pilot onboarding — no paid outreach closes yet. Churn starts Month 9 (first cohort hitting 6-month mark with some attrition). Pilot conversions at Month 12 assume 5 of 8 Escuelas Fundadoras convert to paid.

**Year 1 close (base case): 30 paying schools, €1,770 MRR, €21,240 ARR.**

### Year 2–3 Quarterly Projections (Base Case)

From Year 2 onward: assume founder adds 1 part-time sales/CS hire (or contractor), doubling outreach capacity. New paid schools per month increases to ~4–5.

| Period | New Paid | Churned | Total Paying | MRR | ARR | Cumulative Revenue |
|---|---|---|---|---|---|---|
| Q1 Y2 | 14 | 3 | 41 | €2,419 | €29,028 | €27,645 |
| Q2 Y2 | 15 | 3 | 53 | €3,127 | €37,524 | €38,421 |
| Q3 Y2 | 15 | 4 | 64 | €3,776 | €45,312 | €50,169 |
| Q4 Y2 | 16 | 5 | 75 | €4,425 | €53,100 | €63,474 |
| Q1 Y3 | 18 | 5 | 88 | €5,192 | €62,304 | €79,050 |
| Q2 Y3 | 20 | 6 | 102 | €6,018 | €72,216 | €97,122 |
| Q3 Y3 | 22 | 7 | 117 | €6,903 | €82,836 | €117,891 |
| Q4 Y3 | 24 | 8 | 133 | €7,847 | €94,164 | €141,654 |

### Three-Scenario Summary at Key Milestones

| Milestone | Conservative | Base | Optimistic |
|---|---|---|---|
| Infrastructure self-funding (€150 MRR) | Month 11 | Month 6 | Month 4 |
| Founder living expenses covered (€2,500 MRR net) | Month 32 | Month 24 | Month 18 |
| First €10K MRR | Month 42 | Month 30 | Month 22 |
| First €100K ARR | Not reached Y3 | Month 34 | Month 26 |

**Conservative scenario assumptions:** Email-to-demo 2%, demo-to-paid 25%, churn 4.5%, pilot conversion 50%. Results in ~15 paying schools at end of Year 1, and slow compounding.

**Optimistic scenario assumptions:** Email-to-demo 4%, demo-to-paid 45%, churn 2%, pilot conversion 85%, plus meaningful word-of-mouth inbound from Month 6. Results in ~45 paying schools at end of Year 1.

### Critical Path Observation

The base case reaches €2,500 MRR (founder self-sufficiency) at approximately Month 24. This means roughly 24 months of runway without salary. If the founder has 12–18 months of personal runway, the window is tight. The optimistic case at Month 18 is achievable but requires outreach execution starting Day 1, not after launch.

**Action item:** Begin building the cold outreach list and email sequences before the product ships. Don't wait for a perfect product to start conversations.

---

## 5. Break-Even Analysis

### Fixed Costs

| Cost | Monthly | Notes |
|---|---|---|
| Infrastructure (Fly.io + Supabase + Tigris) | €150 | Stable to ~200 schools |
| Founder salary (Phase 1, pre-revenue) | €0 | Bootstrapped |
| Founder salary (Phase 2, target) | €2,500 | Self-sufficiency threshold |
| Tools (email outreach, Stripe, misc) | €50 | Estimated |
| **Total fixed costs (Phase 1)** | **€200** | |
| **Total fixed costs (Phase 2)** | **€2,700** | |

### Variable Costs per School per Month

| Cost Item | Per School/Month | Notes |
|---|---|---|
| Infrastructure allocation | €1.50 (at 100 schools) | Decreases with scale |
| Support time (Year 1) | €40.00 | 1h @ €40 opportunity cost |
| Support time (Year 2+) | €20.00 | 30min @ €40, with better onboarding |
| Payment processing (Stripe 1.4% + €0.25) | €1.08 | On €59 |
| **Total variable COGS (Year 1)** | **~€43** | |
| **Total variable COGS (Year 2+)** | **~€23** | |

### Break-Even Paying Schools Required

**Phase 1 (no salary):**
- Fixed costs: €200/month
- Contribution margin per school (Year 1): €59 - €43 = €16
- Break-even: €200 / €16 = **13 paying schools**

**Phase 2 (founder at €2,500/month):**
- Fixed costs: €2,700/month
- Contribution margin per school (Year 1): €16
- Break-even: €2,700 / €16 = **169 paying schools**

- Contribution margin per school (Year 2+ support efficiency): €59 - €23 = €36
- Break-even at Year 2 margins: €2,700 / €36 = **75 paying schools**

**Summary:**

| Stage | Break-Even Schools | When Achievable (Base Case) |
|---|---|---|
| Cover infrastructure only | 4 schools | Month 4 |
| Cover all fixed costs ex-salary | 13 schools | Month 7 |
| Cover salary at €2,500/month (Year 1 margins) | 169 schools | Beyond Year 3 |
| Cover salary at €2,500/month (Year 2 margins) | 75 schools | Month 27–30 |

**Key insight:** The path to founder self-sufficiency is not just about adding schools — it's about reducing support time per school. Invest in onboarding automation, help docs, and in-app guidance from Month 3. The difference between 169 and 75 schools required is entirely in support efficiency.

---

## 6. Revenue Expansion Opportunities

### Tier 1: High Feasibility, Meaningful Revenue, Low Additional Effort

#### 1. Billing and Invoicing Module (Premium Add-On or Plan Upgrade Driver)
- **What:** Automated monthly invoice generation for tuition fees, direct debit integration (SEPA), parent payment portal
- **Revenue model:** Either gated behind Plan Centro (conversion driver) or as a €15–20/month add-on for schools that want premium billing features (custom payment plans, late fee management)
- **Revenue potential:** If 60% of paying schools add the premium billing tier at €15/month: at 75 schools = €675/month incremental MRR
- **Effort:** Medium. Requires Stripe billing integration and SEPA direct debit setup. Regulatory consideration: Spanish payment processing rules.
- **When:** Year 2, Q1. Build the basic version for Plan Centro inclusion in Year 1; launch the premium tier in Year 2.
- **Feasibility:** High. This is the single most-requested feature category in school admin software.

#### 2. Multi-School Chain Licensing
- **What:** Custom contracts for preschool chains (3–10 locations). Flat per-location fee with chain-level dashboard.
- **Revenue model:** €129–199/month per location (vs €59 for standalone). 3-location chain = €387–597/month vs €177.
- **Revenue potential:** One 5-location chain at €149/month = €745 MRR. Equivalent to 12.6 standalone schools.
- **Effort:** Low on product (add a "chain admin" role and consolidated dashboard). High on sales (enterprise sales motion, longer cycle).
- **When:** Year 2 when you have 50+ standalone schools and at least one organic chain inquiry.
- **Feasibility:** Medium. Spain has a growing number of small preschool chains (3–8 locations). Target the franchised guarderías (Nemomarlin, etc.).

### Tier 2: Good Potential, Requires More Build

#### 3. AMPA (Parent Association) Tools Module
- **What:** Meeting management, voting, fee collection, document sharing for the parent association. Currently a pain point managed via WhatsApp groups and email.
- **Revenue model:** €19/month add-on per school, paid by AMPA or school depending on negotiation.
- **Revenue potential:** At 40% adoption among paying schools at 100 schools: €760/month
- **Effort:** Medium-high. Requires new UX flows, but reuses messaging and document infrastructure already built.
- **When:** Year 2, Q2-Q3. Test demand with a waiting list in Year 1.
- **Feasibility:** Medium. AMPA digitization is a real problem but AMPAs are volunteer-run and budget-averse. Pricing must stay very low.

#### 4. Analytics and Reporting Dashboard (Premium)
- **What:** Enrollment trends, parent engagement scores, teacher activity summaries, regulatory compliance reports
- **Revenue model:** €20/month add-on, targeting directors who care about data and inspections
- **Revenue potential:** 25% adoption at 100 schools = €500/month incremental
- **Effort:** Medium. Most data already exists; it's a frontend and aggregation problem.
- **When:** Year 2, Q2. Add basic analytics to Plan Centro in Year 1 to demonstrate value, charge for advanced in Year 2.
- **Feasibility:** Medium. Value is real for larger schools; smaller guarderías may not care.

### Tier 3: Year 3+ Only — Flag, Don't Build

#### 5. LATAM Expansion (Mexico, Colombia, Argentina)
- **When it makes sense:** When you have €15K+ MRR from Spain and product is stable enough to run without daily firefighting. LATAM represents a 10–30x larger addressable market but requires localization, different regulatory compliance (child data laws vary), and a different go-to-market.
- **Revenue potential:** Enormous if executed well. The same product with Spanish-language content and LATAM pricing (possibly €25–35/month equivalent) could replicate the Spain model at scale.
- **Effort:** High. Don't underestimate the operational burden of two markets simultaneously.
- **Honest assessment:** Don't touch this before €200K ARR in Spain. Distraction risk is very high for a solo founder.

#### 6. White-Label for Education Management Companies
- **What:** License the platform to a larger edtech company or franchise operator who rebrands it.
- **Revenue potential:** €500–2,000/month per enterprise license.
- **Effort:** High product work (theming, API isolation), high sales complexity.
- **When:** Year 3+, and only if you receive inbound interest. Don't build for it proactively.

#### 7. Marketplace / Integrations (Phase 3+)
- Educational supply vendors, insurance partnerships, SaaS integrations (accounting software)
- Revenue model: referral fees, data partnerships
- Not material before 500+ schools. Flag for Year 4+.

### Revenue Expansion Priority Matrix

| Opportunity | Year | Revenue Potential (Year 2) | Founder Effort | Priority |
|---|---|---|---|---|
| Billing module add-on | Y2 Q1 | €500–800 MRR | Medium | 1 |
| Multi-school chains | Y2 Q2 | €500–1,500 MRR | Low-Medium | 2 |
| AMPA tools | Y2 Q3 | €300–700 MRR | Medium-High | 3 |
| Analytics premium | Y2 Q2 | €200–500 MRR | Medium | 4 |
| LATAM | Y3+ | Significant | Very High | 5 |
| White-label | Y3+ | Moderate | High | 6 |

---

## 7. Fundraising Considerations

### The Honest Assessment

You don't need to raise money to build this business. The unit economics, while tight, support a bootstrapped path to profitability by Year 2–3. A seed round solves cash flow stress but introduces board dynamics, reporting obligations, and pressure to grow faster than the market supports.

**Raise only if one of these is true:**
- You've validated product-market fit (20+ paying schools), churn is below 3%, and you want to accelerate beyond what direct sales can deliver — specifically to hire a full-time sales/CS person
- A LATAM opportunity emerges with a partner who can execute locally but needs product investment
- A larger competitor enters Spain aggressively and you need to defend market position fast

### When the Metrics Would Support a Conversation

A Spanish seed investor (or EU edtech-focused fund) would want to see:

| Metric | Minimum Threshold | Strong Case |
|---|---|---|
| Paying schools | 30+ | 50+ |
| MRR | €2,000+ | €4,000+ |
| Monthly churn | Below 4% | Below 2% |
| LTV:CAC | Above 1.5x | Above 2.5x |
| NPS or qualitative retention signal | Schools renewing and referring | Directors doing warm intros |
| ARR trajectory | Clear growth trend, 3+ months | Accelerating, not linear |

This threshold maps roughly to €2,000–4,000 MRR, achievable in the base case around Month 18–24.

### What a Spanish Edtech Seed Round Looks Like

- **Typical size:** €200K–€600K (pre-product fit), €500K–€1.5M (post-PMF)
- **Instruments:** Convertible note (nota convertible) or simple SAFE equivalent; increasingly common in Spain via ENISA loans + private co-investment
- **Key investors to know:** Lanzadera (Valencia), Ship2B, Kfund, Samaipata, Encomenda, Mundi Ventures. ENISA public loans are non-dilutive and worth exploring early (loans of €25K–€300K for early-stage startups).
- **Dilution at seed:** 10–20% for €300K–€600K
- **Valuation basis:** Revenue multiple (3–8x ARR at seed for SaaS) or traction/market size argument pre-revenue

**ENISA loan is worth exploring at Month 12** if you have 15+ paying schools and product traction. Non-dilutive, relatively founder-friendly terms, and designed for exactly this stage.

### Decision Point

If by Month 18 you are at €2,000+ MRR with sub-3% churn, initiate conversations with 3–4 seed funds while continuing to grow. Don't raise from a position of desperation. Raise when the money would accelerate something already working, not rescue something that isn't.

---

## 8. Financial Risks

### Risk 1: Sales Cycle Locked to Academic Calendar

**Description:** Spanish preschools make software purchasing decisions in May–June for September implementation. A school you pitch in October may say "yes, but let's start in September." This compresses your sales pipeline into a 6–8 week window per year and means cold outreach in October–March has lower conversion rates.

**Probability:** High (70%). This is structural to the Spanish education market.

**Financial Impact:** Medium. Revenue that should arrive in Month 6 arrives in Month 14. Cash flow stress during the dead months (October–February) could be significant.

**Mitigation:**
- Offer a "start anytime" free tier so schools can begin in October at no commitment — you get them in the funnel even if paid conversion waits until June
- Build a 12-month outreach calendar with January–April as the "demo and nurture" season and May–June as the "close" season
- Use October–December for product development and relationship-building with pilot schools
- Track and model the academic year cycle into your projections — don't assume linear monthly conversion

### Risk 2: Free Tier Cannibalization

**Description:** A school stays on the free tier indefinitely by keeping enrollment below 15 children, or by splitting into multiple "school" accounts to avoid the limit. You have 50+ free users but minimal paid conversions.

**Probability:** Medium (40%). Small guarderías genuinely have fewer than 15 children. Some will never upgrade. Gaming the limit is less likely but possible.

**Financial Impact:** Medium-High. If free-to-paid conversion is 5% instead of 15%, your Year 2 MRR projection drops by ~30%.

**Mitigation:**
- The billing/invoicing module behind the paywall is the critical gate — make it genuinely valuable and genuinely absent from the free tier
- Monitor free tier engagement. Schools actively using the product for 90+ days with high teacher and parent engagement are your best conversion targets — create an automated "upgrade nudge" workflow triggered by usage thresholds
- Don't make the free tier too comfortable: 2 GB storage will fill up for an active school within 6–9 months of photo uploads. This is a natural conversion pressure.
- Consider adding a time-based free trial element: free tier is unlimited for 60 days, then 15-child limit kicks in. Increases urgency for medium-sized schools.

### Risk 3: Pilot School Churn at Month 12 (Escuelas Fundadoras)

**Description:** The 8 pilot schools used the product free for 12 months. They are now asked to pay. The product has become part of their workflow, but switching costs are lower than you'd hope (data export is possible, parent apps are commodity). Conversion rate could be lower than 70%.

**Probability:** Medium (35% chance conversion rate is below 50%).

**Financial Impact:** High. If only 3 of 8 pilots convert instead of 5–6, you lose ~€180 MRR at a critical psychological moment (your first "graduation" from pilots to paid).

**Mitigation:**
- Begin the conversion conversation at Month 9, not Month 12. Give pilots 90 days warning with a loyalty pricing offer.
- Frame it correctly: "You're graduating to Plan Centro. As a founding school, your price is €47/month for the first year." The loyalty discount costs you €12/month per school (€144/year) but dramatically increases conversion probability.
- Identify your champion at each pilot school. If the directora loves it and has told other directors about it, she will convert. If she's a passive user, you have a problem. Know this by Month 6.
- Invest disproportionate support and relationship time in pilot schools from Month 8–12.

### Risk 4: Competitor Enters with Aggressive Free Tier (ClassDojo / Brightwheel Spain Expansion)

**Description:** ClassDojo is already used informally by some Spanish preschools. If ClassDojo launches a Spain-specific product with Spanish-language support and LOPD compliance, or if a well-funded EU competitor targets Spain directly, price pressure intensifies immediately.

**Probability:** Low-Medium (25% in Year 1, 40% by Year 3).

**Financial Impact:** High. A free or very low-cost competitor changes the willingness-to-pay landscape and may accelerate churn among price-sensitive schools.

**Mitigation:**
- Your moat in Year 1 is local: Spanish language, LOPD compliance, Spanish invoicing with proper IVA, and a founder who answers the phone in Spanish. These are not advantages a US competitor can replicate overnight.
- Build switching costs: the billing history, the document archive, the parent communication history. Schools don't want to migrate this data.
- Build relationships, not just accounts. A directora who knows you personally and trusts you is not switching for a €10/month saving.
- Monitor Brightwheel's EU expansion announcements and ClassDojo Pro adoption in Spain. Set up Google Alerts.

### Risk 5: LOPD / Privacy Compliance Incident

**Description:** You process personal data of children under 14, which falls under heightened GDPR protections in Spain (LOPD-GDD). A data breach, a parent complaint, or a compliance audit finding could result in AEPD (Agencia Española de Protección de Datos) fines, school-level liability concerns, and reputational damage that directly affects churn.

**Probability:** Low for a breach (5%), Medium for a compliance query from a school or parent (30%).

**Financial Impact:** Very High if a fine or incident occurs. Schools will churn immediately if they perceive legal risk. Even a public complaint could stall sales pipeline.

**Mitigation:**
- Invest in LOPD compliance before the first pilot school signs. This means: a proper DPA (Data Processing Agreement) template, clear privacy notices for parents in plain Spanish, data stored exclusively in EU (already planned with Frankfurt infrastructure), and a documented data deletion process.
- Get a 2-hour legal review from a Spanish data protection specialist (cost: €300–500). Do this in Month 1.
- Make compliance a selling point: "Almacenamiento en Frankfurt, cumplimiento LOPD certificado, DPD disponible." This is a differentiator vs. US tools.

### Financial Risk Summary

| Risk | Probability | Financial Impact | Mitigation Complexity |
|---|---|---|---|
| Academic calendar sales cycle | High | Medium | Low — plan around it |
| Free tier cannibalization | Medium | Medium-High | Medium — requires product gating discipline |
| Pilot school churn at Month 12 | Medium | High | Low — relationship management |
| Competitor enters aggressively | Low-Medium | High | Medium — build moat early |
| LOPD compliance incident | Low | Very High | Low — one-time legal investment |

---

## Appendix: Key Assumptions Reference

This document is a living financial model. The following assumptions are the most sensitive — update them as real data comes in.

| Assumption | Current Value | When to Update |
|---|---|---|
| Email-to-demo conversion | 3% | After first 500 emails sent |
| Demo-to-paid conversion | 35% | After first 10 demos |
| Monthly churn | 3% | After first 6 months of paying schools |
| Free-to-paid conversion | 15%/quarter | After first 20 free schools and 90 days |
| Support hours per school/month | 1h (Year 1) | Track from Month 2 onward |
| Pilot school conversion | 70% | Update at Month 9 with real signals |
| Average MRR per school | €59 | Update if annual billing mix shifts significantly |
| Founder CAC (hours) | 20h | Track from first close |
| Infrastructure cost scaling | €150 flat | Validate at 50 and 100 schools |
| Academic year sales concentration | 60% of closes in May–July | Measure in Year 1, model in Year 2 |

---

*Document version: 1.0 — March 2026*
*Next scheduled review: June 2026 (after first full outreach quarter)*
*Owner: Founder / Finance Lead*
