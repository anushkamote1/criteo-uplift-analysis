# Analysis notes

## Step 3: Data quality and SRM

**Data quality**
- 13,979,592 rows
- No invalid values in treatment, visit, conversion, or exposure
- No missing feature values
- No conversions without a visit
- No exposed users in the control group (holdout did not leak)

**Sample ratio mismatch (SRM)**
- Treatment: 11,882,655 | Control: 2,096,937
- Treatment share: 85.00% (designed: 85%)
- Chi-square = 1.8e-6, p ≈ 0.999
- No SRM. The near-exact match suggests the public dataset was sampled to the design ratio, so this confirms consistency with the documented design rather than live assignment integrity.

**Balance check**
- **Balance check**
- All 12 features balanced: max |SMD| = 0.049 (f3), well under the 0.1 threshold; 9 of 12 under 0.03
- Used SMD rather than per-feature t-tests, since at 14M rows trivial differences become statistically significant

## Step 4: Lift analysis

Compared by treatment assignment (intent-to-treat), not exposure.

**Visits**
- Control: 3.82% | Treatment: 4.85%
- Absolute lift: +1.03 pts (95% CI: 1.01 to 1.06), z = 65.2, p < 0.001
- Relative lift: +27.1% (95% CI: 26.2% to 28.0%)
- ~10,340 extra visits per 1M users targeted

**Conversions**
- Control: 0.194% | Treatment: 0.309%
- Absolute lift: +0.115 pts (95% CI: 0.108 to 0.122), z = 28.5, p < 0.001
- Relative lift: +59.4% (95% CI: 54.4% to 64.7%)
- ~1,150 extra conversions per 1M users targeted

**Takeaway:** Ads caused a clear, statistically significant increase in both visits and conversions. The conversion lift is larger in relative terms (+59% vs. +27%), so ads didn't just bring more people to the site; the visitors they brought were also more likely to convert (6.4% of treated visitors converted vs. 5.1% of control visitors). The conversion CI is wider because conversions are rare.

**Note on p-values:** Python shows 0.0 because the true value is smaller than the computer can represent (z = 65 and 28). Reported as p < 0.001.

## Step 5: Power analysis

Settings: alpha = 0.05 (two-sided), power = 80%, 85/15 split.

**Visits**
- Effect size (Cohen's h): 0.051, small by convention but typical for ad effects
- MDE: 0.040 pts; observed lift (1.03 pts) is about 26x the MDE
- Users needed to detect the observed lift: about 23,800

**Conversions**
- Effect size (Cohen's h): 0.023
- MDE: 0.009 pts; observed lift (0.115 pts) is about 12x the MDE
- Users needed to detect the observed lift: about 114,800

**Sample size vs. lift size (visits)**
- 1% relative lift: about 15.6M users, more than this whole experiment
- 5% relative lift: about 635,000 users
- 10% relative lift: about 162,000 users
- 27% relative lift (observed): about 23,800 users

**Takeaway:** The experiment was heavily overpowered for the average effect. The overall lift could have been detected with about 24,000 users for visits and 115,000 for conversions. The 14M scale matters for the next step: estimating uplift for smaller user segments, where effects vary and each slice has far fewer users. Required sample size grows with the inverse square of the lift, so halving the lift roughly quadruples the users needed.

Did not report observed (post-hoc) power, since it is a direct function of the p-value and adds no information.