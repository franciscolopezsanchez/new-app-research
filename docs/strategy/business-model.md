# Business Model and Unit Economics

**Product:** School-parent communication SaaS for Spanish preschools (ages 0–6)
**Date:** March 2026
**Version:** 1.1 — Updated: no free tier, seasonal sales model, phone-first outreach
**Stage:** Pre-revenue, solo founder, building V1

---

## 1. Business Model Summary

### How We Make Money

Flat-rate monthly SaaS subscription paid by the school. Parents always use the product for free. Revenue is 100% B2B — the school is the customer; parents are the beneficiaries whose satisfaction drives retention.

### Who Pays, Who Uses, Who Decides

| Role             | Who They Are                 | Their Job to Be Done                                                  |
| ---------------- | ---------------------------- | --------------------------------------------------------------------- |
| Buyer            | School director (directora)  | Reduce admin burden, improve parent satisfaction, look professional   |
| User (primary)   | Teachers / pedagogical staff | Log daily activities, send messages, document attendance              |
| User (secondary) | Parents                      | See what their child did today, receive news, communicate with school |
| Influencer       | AMPA (parent association)    | Occasionally advocates for or against tools adopted by school         |

The decision is made by one person: the directora. She controls the budget. She signs. She does not need IT approval, a procurement committee, or a CFO sign-off. This is both the opportunity (short sales cycle if she wants it) and the risk (she's spending personal/operational money, not a corporate budget).

### Pricing Philosophy: Why Flat-Rate

Flat-rate wins over per-child pricing for three reasons that matter in this specific market:

1. **Predictability for the buyer.** A Spanish guardería director manages a tight monthly operating budget. A fixed invoice for €59/month behaves like her accountant invoice or her cleaning service contract — she knows exactly what she's committing to. Per-child pricing creates anxiety: "What happens if I enroll 5 more kids? Does the software bill go up?" Flat-rate removes that objection entirely.

2. **Simplicity for the seller (you).** You're one founder doing direct sales. Flat-rate means no usage tracking disputes, no invoice surprises, no per-seat arguments. The demo and the close are cleaner.

3. **Upsell mechanics are preserved.** Flat-rate at the school level doesn't preclude per-school-size pricing tiers later. You can introduce a "Plan Centro Plus" for larger schools when you have the data to justify it. Per-child pricing is harder to walk back once schools have internalized it.

The tradeoff: a 200-child school pays the same as a 60-child school at the same tier. You will eventually want a volume tier for larger schools. That's fine — solve it in Year 2.

---

## 2. Pricing Model

### 2.1 Standard Pricing — "Plan Centro"

**Price: €59/month (monthly billing) | €49/month (annual billing, paid upfront = €588/year)**

| Dimension                       | Included                  |
| ------------------------------- | ------------------------- |
| Children enrolled               | Up to 80                  |
| Teachers / staff accounts       | Unlimited                 |
| Parent accounts                 | Unlimited                 |
| Daily reports + messaging       | Yes                       |
| Attendance + safeguarding       | Yes                       |
| Media (photos + video)          | Yes                       |
| Billing / invoicing module      | Yes                       |
| Attendance reports (PDF export) | Yes                       |
| Basic analytics dashboard       | Yes                       |
| Custom school branding          | Yes                       |
| Storage                         | 20 GB/school              |
| Support                         | Priority email (24h)      |

**There is no free tier.** Every school pays from day one. The risk-reduction mechanism is the Early Adopter Offer (see 2.2) and a 30-day money-back guarantee on the first month, not a freemium product.

**Why €59 and not €49 or €69?**

Anchoring against what a Spanish guardería director already pays monthly:

- Gestoría / accountant: €80–150/month
- Cleaning service: €200–400/month
- Telefónica broadband + phone: €50–80/month
- Seguridad Social for one part-time employee: €200+/month

At €59/month, you are cheaper than her accountant, comparable to her internet bill, and delivering something that touches every parent in her school every day. The psychological reference is: "this costs less than my accountant and my accountant doesn't make parents happy."

At €49 you leave money on the table and signal uncertainty about your value. At €69 you introduce hesitation in a market where trust is still being built. €59 is clean, credible, and slightly below the psychological €60 round-number threshold.

**Annual discount:** 17% discount (monthly equivalent of €49 vs €59). Offering annual upfront improves cash flow and de-risks churn. Target 40% of conversions on annual plans from Month 6 onward — push for it actively in demos but don't require it to close.

**30-day money-back guarantee:** Stated clearly at signup and in sales conversations. A director who pays and can cancel is more committed to implementing the product than one who signed up free. This replaces the risk-reduction function of a free tier without the conversion dead weight.

### 2.2 Early Adopter Offer — "Escuelas Fundadoras"

**Price: €39/month, locked for 12 months, then standard €59/month**
**Hard cap: first 15 schools only. Once full, this offer is gone.**

This is the replacement for the free pilot program. Every early adopter pays — but they pay at a founding-school rate that will never be available again.

Positioning in sales conversations: *"Estamos lanzando con un programa para centros fundadores — los primeros 15 centros que entren tienen precio bloqueado de €39/mes durante el primer año. A partir de ahí, el precio estándar es €59. Nos quedan [X] plazas."*

Why this works better than free:
- Schools that pay, even at a discount, implement the product seriously. They train staff. They onboard parents. They actually use it.
- Directors who paid €39 are psychologically invested in making it work.
- The renewal conversation at Month 12 moves from "now you have to pay" to "your price goes from €39 to €59" — a much easier ask.
- The cap creates genuine scarcity and urgency.

Target: fill all 15 Escuelas Fundadoras slots before or during the first sales window (May–August).

### 2.3 Volume Tier — "Plan Grupo"

**Price: Custom, starting at €129/month per school (negotiated for 3+ school chains)**

Available for schools with 80+ children or multi-school operators. Not productized in Year 1 — handle manually when the conversation comes up. The floor is €129/month per location because below that, the support complexity of enterprise relationships doesn't justify the margin.

### 2.4 Billing and Invoicing as Primary Demo Value Driver

The invoicing module is the single most compelling feature to demonstrate to directors on the fence. Spanish guarderías must issue monthly invoices to parents — most directors do it in Excel or a generic tool. A live demo of automated invoicing generation with SEPA direct debit eliminates the "is this worth €59?" question.

Frame in demo: *"¿Cuánto tiempo dedica cada mes a hacer las facturas? Con esto, lo tiene listo en 10 minutos."*

Since there is no free tier, the invoicing module is not a paywall upgrade lever — it is a primary close lever. Show it early in the demo, not at the end.

### 2.5 Pricing Psychology for the Directora

She is spending operational money, often her own school's money, and she is accountable for it. What makes pricing feel fair and trustworthy:

1. **No surprise bills.** Fixed price, always. If storage or users ever become an issue, warn her with 30 days notice and offer a graceful upgrade path. Never auto-charge overages.
2. **Monthly cancellation possible.** Even if you push annual, she needs to know she can leave. Annual billing with a refund policy for unused months is more credible than a lock-in.
3. **Invoice / factura always available.** She needs a proper factura for her accountant. Stripe must generate a valid Spanish factura automatically with your NIF, her NIF, and the correct IVA line (21% IVA for software SaaS). Failing here breaks trust immediately.
4. **Price stability.** Don't change pricing on existing customers in Year 1. If you raise prices in Year 2, grandfather existing schools for 12 months.

---

## 3. Sales Motion

### 3.1 Why Phone Calls, Not Email

Cold email is wrong for this persona. Guardería directors are not knowledge workers who live in their inbox. On a typical Tuesday, Carmen is handling a sick child, talking to a worried parent at the gate, chasing a supplier, and reviewing weekly menus with her cook. She checks email once a day, maybe. Cold email from an unknown software vendor is deleted or ignored.

The 3% email-to-demo conversion assumed in the original model is optimistic for this segment. In practice it is 1–1.5% for pure cold email. Phone calls to the school number, in contrast, get through at 30–40% — directors often answer their own phones.

**Phone-first is not an add-on to the email strategy. It is the primary motion.**

### 3.2 Outreach Cadence (Per School)

| Step | Timing | Action |
|------|--------|--------|
| 1 | Day 1 | Call school number. Ask for directora by name. If unavailable: brief hook + callback request |
| 2 | Day 1 (same day) | Follow-up email — purpose is to make scheduling frictionless, not to generate the demo |
| 3 | Day 7 | Second call if no response. WhatsApp if you have a mobile number |
| 4 | Day 14 | Final email — brief, no pressure. Move to next quarter's pipeline if no response |

**Hook for voicemail / receptionist:** *"Llamo por un tema de comunicación con familias y cumplimiento LOPDGDD, para hablar con la directora cuando pueda."*

**Best call times:** 9:00–10:30am and 4:00–5:30pm Spanish time (before morning chaos peaks or after the school day winds down).

**WhatsApp is legitimate** for follow-up in Spain once you have a mobile number. A WhatsApp message after an initial call has significantly higher open rates than email in this market.

### 3.3 Weekly Outreach Volume

| Metric | Value |
|--------|-------|
| Schools researched per week | 10–12 |
| Schools contacted per week | 10–12 |
| Monthly contacts | ~45 |
| Call-to-conversation rate | 35% |
| Conversation-to-demo rate | 22% |
| Demo-to-paid rate | 42% |
| **New paid schools per month** | **~1.5** |

This is similar throughput to a volume email model but with substantially higher lead quality. Directors who book a demo after a real phone conversation are more committed than those who clicked a cold email.

### 3.4 Sales Calendar — Seasonal Rhythm

This market has a hard seasonal constraint. Schools change software at year boundaries — either in June (end of year) or in August–September (before the new year starts). Changing communication software mid-year means migrating 40–80 families to a new app while they are actively using the current one. Almost no director does this voluntarily.

**The year has two windows and two phases:**

#### Window A: May–August (Primary Closing Window)

This is when you close schools. Directors are thinking about the new year, reviewing vendors, making administrative changes. Your goal: be in active conversations with 40–60 schools by May 1 so you can close 8–15 before September.

Activities:
- Maximum outreach intensity (10–12 schools/week called)
- Demos prioritized over all other work
- Push for September start date ("¿Empezamos en septiembre?")
- Push for annual billing ("Ahorra €120 con el plan anual")
- Close Escuelas Fundadoras slots

#### Phase B: September–April (Pipeline Building Phase)

You will not close many schools in this period. That is normal and expected. Use it productively.

Activities:
- Continue outreach at reduced pace (5–6 schools/week) to build pipeline for next May
- Nurture warm leads who said "call me after summer" or "maybe next year"
- Onboard and support September cohort — these are your reference customers
- Build case studies from September schools ("Guardería X ahorra 4h/mes en facturación")
- Product development and improvement
- Identify directors who are having a bad experience with their current software (mid-year switchers)

#### Window B: November–January (Minor Closing Window)

A small number of desperate mid-year switchers exist — schools that had a bad September with their current tool and are willing to absorb the disruption of switching. This represents maybe 1–2 schools per year at your scale. Worth pursuing if a warm lead surfaces, but don't build the model around it.

### 3.5 The Pipeline-to-Close Timeline

A school you call in February will not close until September. This is not a failure — it is the market.

Build your pipeline in January–April by having real conversations, sending relevant content (a LOPDGDD compliance checklist, an invoicing template they can use today), and staying warm. When May arrives, these directors already know you. Your demo is half-done before you start it.

---

## 4. Unit Economics

### 4.1 Base Case Assumptions

- Average paid school: 40 children
- Plan Centro monthly price: €59/month (Escuelas Fundadoras at €39/month for first 15 schools)
- Annual billing mix: 30% annual (Month 1–6), 40% annual (Month 7+)
- Infrastructure: €150/month total, shared across all active schools
- Founder support time: 1 hour/month per paying school at an opportunity cost of €40/hour

### 4.2 Per-School Economics

| Metric                                                 | Calculation     | Value   |
| ------------------------------------------------------ | --------------- | ------- |
| MRR per school (standard)                              | €59/month       | €59.00  |
| MRR per school (early adopter)                         | €39/month       | €39.00  |
| ARR per school (standard)                              | €59 x 12        | €708.00 |
| Infrastructure cost per school (at 20 paying schools)  | €150 / 20       | €7.50   |
| Infrastructure cost per school (at 50 paying schools)  | €150 / 50       | €3.00   |
| Infrastructure cost per school (at 100 paying schools) | €150 / 100      | €1.50   |
| Support time cost per school/month                     | 1h x €40        | €40.00  |
| Total COGS per school/month (at 50 schools)            | €3.00 + €40.00  | €43.00  |
| Gross profit per school/month (at 50 schools)          | €59.00 - €43.00 | €16.00  |
| Gross margin per school (at 50 schools)                | €16 / €59       | 27%     |

**Note:** Early adopter schools (€39/month) have a gross margin of approximately -10% in the first year at 50-school scale. This is acceptable — they are reference customers, not margin contributors. Ensure the 15-school cap is honored so this doesn't distort early economics beyond the pilot cohort.

| Schools | Infra/School | Support/School | COGS/School | Gross Margin |
| ------- | ------------ | -------------- | ----------- | ------------ |
| 10      | €15.00       | €40.00         | €55.00      | 7%           |
| 25      | €6.00        | €40.00         | €46.00      | 22%          |
| 50      | €3.00        | €40.00         | €43.00      | 27%          |
| 100     | €1.50        | €30.00         | €31.50      | 47%          |
| 200     | €0.75        | €20.00         | €20.75      | 65%          |

**Key insight:** This is a support-cost business in the early stage, not an infrastructure-cost business. Invest in documentation, onboarding videos, and a self-serve help center early — every hour of support you eliminate goes directly to margin.

### 4.3 Customer Acquisition Cost (CAC)

Phone-first outreach model. Quality over volume.

**Outreach funnel assumptions:**

| Metric | Value |
|--------|-------|
| Schools researched + contacted per week | 10–12 |
| Monthly contacts | ~45 |
| Call-to-conversation rate | 35% → ~16 conversations/month |
| Conversation-to-demo rate | 22% → ~3.5 demos/month |
| Demo-to-paid rate | 42% → ~1.5 new paid schools/month |

**CAC breakdown:**

| CAC Component | Hours | Cost |
| --- | --- | --- |
| Research + outreach (45 schools x 25 min) | 18.75h | €750 |
| Calls + follow-up (16 conversations x 20 min) | 5.3h | €212 |
| Demo calls (3.5 demos x 45 min) | 2.6h | €105 |
| Follow-up and close | 1.0h | €40 |
| Onboarding | 1.5h | €60 |
| **Total CAC** | **~29h** | **~€1,167** |

Divided across 1.5 closed schools per month: **working CAC ≈ €778 per acquired school.**

Use **€800 CAC** as the working assumption — consistent with the previous model, though the time distribution shifts toward research and calls rather than email volume.

**How CAC improves over time:**
- Word-of-mouth referrals from satisfied directors have near-zero CAC
- Reference customers enable warm introductions — a director recommending you to a colleague converts at 70%+ without a full sales cycle
- By Year 2, expect 20–30% of new schools to come via referral, pulling blended CAC toward €400–500

**Out-of-pocket CAC:** Near zero. A basic CRM (€30/month), a phone with a Spanish SIM or VoIP number, outreach tracking in a spreadsheet. Not material.

### 4.4 Churn Model — Annual, Not Monthly

This market does not churn monthly. Schools switch at year boundaries. The correct churn model is:

- **Mid-year churn (October–May):** ~0%. A school that started in September is not switching mid-year unless something catastrophic happens. Operational switching cost is too high.
- **Annual churn (June–August):** Concentrated here. If a school is going to leave, they leave at year end.

**Annual churn rate assumptions:**

| Scenario     | Annual Churn Rate | Monthly Equivalent |
| ------------ | ----------------- | ------------------ |
| Conservative | 20%               | 1.8%               |
| Base         | 12%               | 1.0%               |
| Optimistic   | 7%                | 0.6%               |

The base case 12% annual churn is equivalent to schools staying for an average of ~8 years — which is optimistic. Use 15% (average retention ~6 years) as a more conservative base, and 20% (average 5 years) as the bear case. These are reasonable for a product that becomes embedded in daily teacher and parent workflows.

**Key churn driver:** The relationship you build with the directora before and after the sale. A director who knows you personally and trusts you is not switching for a competing product. Invest in the relationship, not just the product.

### 4.5 Lifetime Value (LTV)

**LTV = ARR x Gross Margin % x (1 / Annual Churn Rate)**

Using steady-state 65% gross margin (Year 2+ support efficiency):

| Scenario     | Annual Churn | Avg Retention | LTV (65% margin) | LTV (27% margin) |
| ------------ | ------------ | ------------- | ---------------- | ---------------- |
| Conservative | 20%          | 5 years       | €2,301           | €955             |
| Base         | 12%          | ~8 years      | €3,835           | €1,592           |
| Optimistic   | 7%           | ~14 years     | €6,577           | €2,730           |

**Note:** Switching from a monthly to annual churn model significantly improves LTV estimates compared to the previous version of this document. The business is healthier than the monthly-churn model suggested.

### 4.6 LTV:CAC Ratio

| Scenario     | LTV (65% margin) | CAC  | LTV:CAC | Assessment                         |
| ------------ | ---------------- | ---- | ------- | ---------------------------------- |
| Conservative | €2,301           | €800 | 2.88x   | Solid for early stage              |
| Base         | €3,835           | €800 | 4.79x   | Strong — this business works       |
| Optimistic   | €6,577           | €800 | 8.22x   | Excellent — invest in sales motion |

**Revised assessment:** The annual churn model changes the picture materially. Even the conservative scenario produces a healthy LTV:CAC. The business fundamentals are sound. The constraint is not unit economics — it is cash flow during the long buildup to self-sufficiency.

### 4.7 Payback Period

**Payback = CAC / (MRR x Gross Margin %)**

Using steady-state 65% margin:

| CAC  | MRR | Gross Margin | Monthly Contribution | Payback Period |
| ---- | --- | ------------ | -------------------- | -------------- |
| €800 | €59 | 65%          | €38.35               | 20.9 months    |
| €800 | €59 | 45%          | €26.55               | 30.1 months    |
| €800 | €59 | 27%          | €15.93               | 50.2 months    |

**Key implication:** At early-stage margins, payback is long. This is normal for bootstrapped SaaS — but it means churn management is existential, not optional. Every school you lose before Month 21 represents a net loss on that customer relationship.

---

## 5. MRR / ARR Projections — Seasonal Model

### 5.1 Key Assumptions

| Assumption | Value | Notes |
| --- | --- | --- |
| Schools called per week | 10–12 | Phone-first, quality over volume |
| Call-to-conversation rate | 35% | Much higher than cold email |
| Demo-to-paid rate | 42% | Warmer leads from phone conversations |
| New paid schools per month (active selling) | ~1.5 | During May–August window |
| New paid schools per month (pipeline phase) | ~0.25 | Sep–Apr, mostly mid-year switchers |
| Escuelas Fundadoras (early adopter cohort) | 15 schools at €39/month | Hard cap |
| Annual churn rate | 12% (base) | Applied at June–August each year |
| Infrastructure cost | €150/month flat | Stable through ~200 schools |
| Product ready-to-sell | April 2026 (assumption) | Adjust all dates if this shifts |

### 5.2 Year 1 — Seasonal Shape (Base Case)

**Context:** Assuming product ready-to-sell by April 2026. First real sales window is May–August 2026.

**Phase A — Setup (Jan–Apr 2026):**
Product is being built. No paid closes yet. Use this time to:
- Research and score 150 target schools
- Build pipeline by calling and starting conversations
- Aim to have 30–40 warm leads ready to demo in May

**Phase B — First Sales Window (May–Aug 2026):**
Active closing. Target 8–12 new paying schools before September. These are the Escuelas Fundadoras cohort (€39/month) and first standard-price converts.

**Phase C — Pipeline Phase (Sep–Dec 2026):**
Onboard September cohort. 1–2 mid-year switchers possible. Product improvement. Reference customer development.

| Month | New Paid (Closed) | Pricing | Total Paying | MRR |
| --- | --- | --- | --- | --- |
| Jan–Apr | 0 | — | 0 | €0 |
| May | 3 | €39 EA | 3 | €117 |
| Jun | 3 | €39 EA | 6 | €234 |
| Jul | 3 | €39 EA | 9 | €351 |
| Aug | 3 | €39 EA + €59 std | 12 | €429 |
| Sep | 1 (mid-year) | €59 | 13 | €488 |
| Oct | 0 | — | 13 | €488 |
| Nov | 1 (mid-year) | €59 | 14 | €547 |
| Dec | 0 | — | 14 | €547 |

**Year 1 close (base case): ~13–14 paying schools, ~€547 MRR.**

This is significantly lower than previous projections because (a) no free-tier conversion pipeline, and (b) seasonality compresses the actual closing window to 4 months. **This is the correct forecast, not a pessimistic one.** Plan your runway accordingly.

### 5.3 Year 2 Projections (Base Case)

Year 2 has two closing windows. By the first window (May–Aug 2027), you have reference customers and case studies. Referral rate begins to matter. Assume 20% of new schools via referral (near-zero CAC).

**Summer 2027 window (May–Aug):** Close 15–20 new schools at standard pricing. Target: 18.

**Annual churn applied at June 2027:** 12% of 14 schools = ~2 schools churn. Net: 12 retained.

| Period | New Paid | Churned | Total Paying | MRR | ARR |
| --- | --- | --- | --- | --- | --- |
| Jan–Apr Y2 | 2 (mid-year) | 0 | 16 | €871 | €10,452 |
| May–Aug Y2 | 18 | 2 (annual) | 32 | €1,829 | €21,948 |
| Sep–Dec Y2 | 2 (mid-year) | 0 | 34 | €1,947 | €23,364 |

**Year 2 close (base case): ~32–34 paying schools, ~€1,947 MRR.**

Note: Early adopter schools (15 at €39) begin converting to €59 at Month 12 of their contract. Assume 80% conversion (12 schools). This adds ~€240 MRR in Year 2.

**With EA conversion included, Year 2 MRR: ~€2,187.**

### 5.4 Year 3 Projections (Base Case)

Founder adds 1 part-time sales/CS contractor in Year 2 (funded by revenue). Doubles outreach capacity. Annual churn (12%) applied at June 2028.

| Period | New Paid | Churned | Total Paying | MRR | ARR |
| --- | --- | --- | --- | --- | --- |
| Jan–Apr Y3 | 4 (mid-year) | 0 | 38 | €2,242 | €26,904 |
| May–Aug Y3 | 30 | 4 (annual) | 64 | €3,776 | €45,312 |
| Sep–Dec Y3 | 4 (mid-year) | 0 | 68 | €4,012 | €48,144 |

**Year 3 close (base case): ~65–68 paying schools, ~€4,012 MRR.**

### 5.5 Milestone Timeline

| Milestone | Conservative | Base | Optimistic |
| --- | --- | --- | --- |
| Infrastructure self-funding (€150 MRR) | Aug 2026 | Jul 2026 | Jun 2026 |
| Cover all fixed costs ex-salary (€200 MRR) | Sep 2026 | Aug 2026 | Jul 2026 |
| Founder living expenses (€2,500 MRR net) | Sep 2028 | May 2028 | Dec 2027 |
| First €10K MRR | Not Y3 | Mid Y4 | End Y3 |
| First €100K ARR | Not Y3 | Y4 | Y3 |

**Critical runway observation:** The path to founder self-sufficiency is Month 26–30 in the base case. If you have less than 24 months of personal runway, this is the governing constraint on the business — not product quality, not market size. Know your number.

---

## 6. Break-Even Analysis

### Fixed Costs

| Cost | Monthly | Notes |
| --- | --- | --- |
| Infrastructure (Fly.io + Supabase + Tigris) | €150 | Stable to ~200 schools |
| Founder salary (Phase 1, pre-revenue) | €0 | Bootstrapped |
| Founder salary (Phase 2, target) | €2,500 | Self-sufficiency threshold |
| Tools (CRM, phone/VoIP, Stripe, misc) | €60 | Estimated |
| **Total fixed costs (Phase 1)** | **€210** | |
| **Total fixed costs (Phase 2)** | **€2,710** | |

### Variable Costs per School per Month

| Cost Item | Per School/Month | Notes |
| --- | --- | --- |
| Infrastructure allocation | €1.50 (at 100 schools) | Decreases with scale |
| Support time (Year 1) | €40.00 | 1h @ €40 opportunity cost |
| Support time (Year 2+) | €20.00 | 30min @ €40, with better onboarding |
| Payment processing (Stripe 1.4% + €0.25) | €1.08 | On €59 |
| **Total variable COGS (Year 1)** | **~€43** | |
| **Total variable COGS (Year 2+)** | **~€23** | |

### Break-Even Paying Schools Required

**Phase 1 (no salary):**
- Fixed costs: €210/month
- Contribution margin per school (Year 1): €59 - €43 = €16
- Break-even: €210 / €16 = **14 paying schools**

**Phase 2 (founder at €2,500/month):**
- Fixed costs: €2,710/month
- At Year 1 margins: €2,710 / €16 = **170 paying schools**
- At Year 2 margins: €2,710 / €36 = **76 paying schools**

| Stage | Break-Even Schools | When Achievable (Base Case) |
| --- | --- | --- |
| Cover infrastructure only | 4 schools | August 2026 |
| Cover all fixed costs ex-salary | 14 schools | End of Y1 (barely) |
| Cover salary at €2,500/month (Year 2 margins) | 76 schools | Mid Year 3 |
| Cover salary at €2,500/month (Year 1 margins) | 170 schools | Beyond Year 3 |

**Key insight:** The path to founder self-sufficiency is reducing support time per school, not just adding schools. The difference between 170 and 76 schools required is entirely in support efficiency. Invest in onboarding automation and help docs from Month 3.

---

## 7. Revenue Expansion Opportunities

### Tier 1: High Feasibility, Meaningful Revenue, Low Additional Effort

#### 1. Billing and Invoicing Module (Premium Add-On)

- **What:** Automated monthly invoice generation for tuition fees, direct debit integration (SEPA), parent payment portal
- **Revenue model:** €15–20/month add-on for schools that want premium billing features (custom payment plans, late fee management, multi-child discounts)
- **Revenue potential:** If 60% of paying schools add the premium billing tier at €15/month: at 75 schools = €675/month incremental MRR
- **Effort:** Medium. Basic version included in Plan Centro; premium features as a separate add-on.
- **When:** Year 2, Q1.
- **Feasibility:** High. This is the single most-requested feature category in school admin software.

#### 2. Multi-School Chain Licensing

- **What:** Custom contracts for preschool chains (3–10 locations). Flat per-location fee with chain-level dashboard.
- **Revenue model:** €129–199/month per location (vs €59 for standalone). 3-location chain = €387–597/month vs €177.
- **Revenue potential:** One 5-location chain at €149/month = €745 MRR. Equivalent to 12.6 standalone schools.
- **Effort:** Low on product (add a "chain admin" role and consolidated dashboard). High on sales (longer cycle).
- **When:** Year 2 when you have 50+ standalone schools and at least one organic chain inquiry.
- **Feasibility:** Medium. Spain has a growing number of small preschool chains (3–8 locations). Target franchised guarderías (Nemomarlin, etc.).

### Tier 2: Good Potential, Requires More Build

#### 3. AMPA (Parent Association) Tools Module

- **What:** Meeting management, voting, fee collection, document sharing for the parent association.
- **Revenue model:** €19/month add-on per school.
- **Revenue potential:** At 40% adoption among paying schools at 100 schools: €760/month
- **Effort:** Medium-high. Reuses messaging and document infrastructure already built.
- **When:** Year 2, Q2-Q3.
- **Feasibility:** Medium. AMPA digitization is a real problem but AMPAs are volunteer-run and budget-averse.

#### 4. Analytics and Reporting Dashboard (Premium)

- **What:** Enrollment trends, parent engagement scores, teacher activity summaries, regulatory compliance reports
- **Revenue model:** €20/month add-on
- **Revenue potential:** 25% adoption at 100 schools = €500/month incremental
- **Effort:** Medium. Most data already exists; it's a frontend and aggregation problem.
- **When:** Year 2, Q2.

### Tier 3: Year 3+ Only — Flag, Don't Build

#### 5. LATAM Expansion (Mexico, Colombia, Argentina)

- **When it makes sense:** When you have €15K+ MRR from Spain and product is stable. LATAM represents a 10–30x larger addressable market but requires localization, different regulatory compliance, and a different go-to-market.
- **Revenue potential:** Enormous if executed well. The same product with LATAM pricing (€25–35/month equivalent) could replicate the Spain model at scale.
- **Effort:** High. Don't touch this before €200K ARR in Spain.

#### 6. White-Label for Education Management Companies

- **Revenue potential:** €500–2,000/month per enterprise license.
- **Effort:** High product work (theming, API isolation), high sales complexity.
- **When:** Year 3+, and only if you receive inbound interest.

#### 7. Marketplace / Integrations (Phase 3+)

- Educational supply vendors, insurance partnerships, SaaS integrations (accounting software)
- Not material before 500+ schools.

### Revenue Expansion Priority Matrix

| Opportunity | Year | Revenue Potential (Year 2) | Founder Effort | Priority |
| --- | --- | --- | --- | --- |
| Billing module add-on | Y2 Q1 | €500–800 MRR | Medium | 1 |
| Multi-school chains | Y2 Q2 | €500–1,500 MRR | Low-Medium | 2 |
| AMPA tools | Y2 Q3 | €300–700 MRR | Medium-High | 3 |
| Analytics premium | Y2 Q2 | €200–500 MRR | Medium | 4 |
| LATAM | Y3+ | Significant | Very High | 5 |
| White-label | Y3+ | Moderate | High | 6 |

---

## 8. Fundraising Considerations

### The Honest Assessment

You don't need to raise money to build this business. The unit economics support a bootstrapped path to profitability by Year 2–3. A seed round solves cash flow stress but introduces board dynamics, reporting obligations, and pressure to grow faster than the market supports.

**Raise only if one of these is true:**

- You've validated product-market fit (20+ paying schools), churn is below 15% annually, and you want to accelerate beyond what direct sales can deliver — specifically to hire a full-time sales/CS person
- A LATAM opportunity emerges with a partner who can execute locally but needs product investment
- A larger competitor enters Spain aggressively and you need to defend market position fast

### When the Metrics Would Support a Conversation

| Metric | Minimum Threshold | Strong Case |
| --- | --- | --- |
| Paying schools | 20+ | 40+ |
| MRR | €1,500+ | €3,000+ |
| Annual churn | Below 20% | Below 10% |
| LTV:CAC | Above 2x | Above 4x |
| NPS or qualitative retention signal | Schools renewing and referring | Directors doing warm intros |

### What a Spanish Edtech Seed Round Looks Like

- **Typical size:** €200K–€600K (pre-PMF), €500K–€1.5M (post-PMF)
- **Instruments:** Convertible note or SAFE equivalent; ENISA loans + private co-investment
- **Key investors:** Lanzadera (Valencia), Ship2B, Kfund, Samaipata, Encomenda, Mundi Ventures
- **ENISA loan** is worth exploring at Month 12 if you have 15+ paying schools — non-dilutive, founder-friendly, designed for this stage
- **Dilution at seed:** 10–20% for €300K–€600K

---

## 9. Financial Risks

### Risk 1: Personal Runway Is the Governing Constraint

**Description:** With a seasonal sales model and no free-tier conversion pipeline, Year 1 realistically ends at 13–14 paying schools and ~€550 MRR. Founder self-sufficiency (€2,500 MRR) is reached in approximately Month 26–30. If personal runway is less than 24 months, this creates existential pressure.

**Probability:** High (90% — this is the base case, not a risk scenario).

**Mitigation:**
- Know your exact runway before building. Not approximately — exactly.
- If runway is under 18 months, consider part-time consulting to extend it. €1,000/month of consulting income extends a tight runway by 6–12 months.
- Push annual billing hard from day one: a school paying €588 upfront in August extends your cash runway meaningfully versus monthly billing.
- Begin outreach conversations in January–April even before the product ships. Being in the pipeline early maximizes the May–August window.

### Risk 2: First Sales Window Is Missed or Compressed

**Description:** If the product is not ready-to-sell by April, the primary 2026 closing window shrinks or disappears. A launch in October means waiting until May 2027 for meaningful sales.

**Probability:** Medium (40%). Software is almost always delayed.

**Financial Impact:** High. Missing the 2026 window means Year 1 ends at effectively €0 MRR and you restart the clock in 2027.

**Mitigation:**
- Define "ready-to-sell" as the minimum viable product needed to run a real demo: attendance marking, daily reports, messaging, and parent app. Invoicing can be manual for the first 3 schools.
- Start sales conversations (pipeline building, not closing) before the product is complete. A director who has seen a demo in March and was impressed will close in July.
- Have a plan for running the first 2–3 schools manually if the product is 80% ready in May. The founder operating some features manually for a paying school is better than missing the window.

### Risk 3: Annual Churn Concentrated in a Bad Summer

**Description:** If 3–4 schools decide not to renew in the same summer (June–August), MRR could drop materially in a single month. Unlike smooth monthly churn, annual churn can feel like a sudden crisis.

**Probability:** Medium (30% chance of a bad renewal season in Year 2–3).

**Financial Impact:** Medium. Losing 4 schools of 30 total is a 13% MRR drop in one month.

**Mitigation:**
- Identify renewal risk early. By April each year, know which schools are at risk of not renewing. Signs: low parent engagement, director hasn't logged in, school hasn't contacted you in 3 months.
- Begin renewal conversations in March ("¿Todo bien con el sistema? ¿Renovamos para el próximo año?"). Don't wait until June.
- Offer early-renewal discount for schools that commit before May: 2 months free on annual plan. Locks in revenue before the uncertainty of summer.

### Risk 4: Competitor Enters with Aggressive Pricing (ClassDojo / Brightwheel Spain Expansion)

**Description:** ClassDojo is already used informally by some Spanish preschools. If a well-funded EU or US competitor launches Spanish-language product with LOPD compliance, price pressure intensifies.

**Probability:** Low-Medium (25% in Year 1, 45% by Year 3).

**Financial Impact:** High. A free or very low-cost competitor changes the willingness-to-pay landscape.

**Mitigation:**
- Your moat in Year 1 is local: Spanish language, LOPD compliance, Spanish invoicing with proper IVA, and a founder who answers the phone in Spanish. A US competitor cannot replicate this overnight.
- Build switching costs: billing history, document archive, parent communication history. Schools don't want to migrate this.
- Build relationships, not just accounts. A directora who knows you personally is not switching for a €10/month saving.
- Monitor Brightwheel's EU expansion announcements and ClassDojo Pro adoption in Spain.

### Risk 5: LOPD / Privacy Compliance Incident

**Description:** You process personal data of children under 14, which falls under heightened GDPR protections in Spain (LOPD-GDD). A data breach, parent complaint, or compliance audit finding could result in AEPD fines and reputational damage.

**Probability:** Low for a breach (5%), Medium for a compliance query from a school or parent (30%).

**Financial Impact:** Very High. Schools will churn immediately if they perceive legal risk.

**Mitigation:**
- Invest in LOPD compliance before the first school signs: a proper DPA template, clear privacy notices for parents in plain Spanish, data stored exclusively in EU (Frankfurt infrastructure already planned), documented data deletion process.
- Get a 2-hour legal review from a Spanish data protection specialist (cost: €300–500) in Month 1.
- Your technical architecture (RLS, encrypted sensitive fields, audit logs, consent management) is already designed for this. Make sure the legal documentation matches the technical reality.
