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