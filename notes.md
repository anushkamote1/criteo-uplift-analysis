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

## Step 6: Uplift model

**Method:** T-learner with two XGBoost classifiers (300 trees, depth 5), one trained on treated users and one on control. Uplift = P(visit | ads) − P(visit | no ads). Trained on a 3M-row random sample (Bernoulli 21.5%, seed 42; 2.1M train / 900K test, stratified by treatment and outcome). Evaluated on the held-out test set with Qini curves, since uplift can't be checked with accuracy or AUC. Compared against a standard response model that predicts who visits, ignoring treatment.

**Results (900K held-out users)**

| Share targeted | Uplift model keeps | Response model keeps |
|---|---|---|
| Top 10% | 55% of incremental visits | 47% |
| Top 20% | 76% | 73% |
| Top 30% | 83% | 85% |
| Top 50% | 92% | 95% |

- Qini coefficient: uplift model 2,636 vs. response model 2,641 (effectively tied overall)
- Both models far outperform random targeting, which would keep only 10% of incremental visits at 10% targeted

**Takeaway:** Ad effects are highly concentrated: targeting just the top 20% of users captures about three quarters of the incremental visits. The uplift model has a clear edge at tight budgets (55% vs. 47% of incremental visits in the top 10%), which is where targeting decisions matter most. Past 30%, the two models perform about the same, meaning in this data the users most likely to visit are largely the same users ads persuade. Recommendation: use the uplift model when the budget only covers a small share of users; for broad campaigns, either model works.

**Limitations**
- The T-learner's control model trains on only ~315K users, so individual uplift scores are noisy (range −0.55 to +0.59). Rankings are more reliable than individual scores.
- Mean predicted uplift (0.76 pts) is a little below the measured lift (1.03 pts), so the model is conservative on absolute effect size.
- Modeled visits only; conversions are too rare for a stable individual-level model.

## Step 7: Targeting and budget analysis

Users in the 900K test set ranked by predicted uplift and split into 10 equal deciles (~90,200 users each). Actual lift measured within each decile (treated vs. control), so results reflect what really happened, not model predictions.

**Lift by decile**
- Decile 1 (most persuadable): +5.52 pts (95% CI: 4.71 to 6.32), about 5x the average lift
- Decile 2: +1.05 pts (95% CI: 0.60 to 1.49), about the average lift
- Deciles 3 to 9: between −0.02 and +0.26 pts, effectively zero
- Decile 10: +0.42 pts (95% CI: −0.08 to 0.92), not significant
- The model is well calibrated where it matters: predicted uplift in deciles 1 and 2 (6.9 and 1.1 pts) closely matches measured lift (5.5 and 1.05 pts). Its negative predictions for the bottom deciles did not hold up; those users show no measurable effect either way.

**Targeting scenarios (uplift model)**

| Target | Ad spend cut | Visit effect kept | Cost per extra visit vs. blanket |
|---|---|---|---|
| Top 10% | 90% | 72% | 0.14 (86% cheaper) |
| Top 20% | 80% | 86% | 0.23 (77% cheaper) |
| Top 30% | 70% | 88% | 0.34 (66% cheaper) |
| Top 50% | 50% | 92% | 0.54 (46% cheaper) |

**Uplift vs. response model:** The uplift model is clearly better at the tightest budget (top 10%: 72% vs. 65% of the effect kept). From 20% onward, the response model keeps slightly more, consistent with the Qini results in Step 6.

**Recommendation:** Target the top 20% of users by predicted uplift. Per 1M users, this shows ads to 200,000 instead of 1,000,000 while keeping about 8,900 of the ~10,340 incremental visits, making each extra visit about 77% cheaper than blanket targeting. Expanding to 30% adds only 2 more points of effect for 50% more spend.

**Assumptions:** No cost data in the dataset, so savings are expressed as share of impressions cut, assuming cost scales with users reached. Results come from a 900K-user held-out set.