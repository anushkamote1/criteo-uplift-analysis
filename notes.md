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