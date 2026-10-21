# UI color, contrast, and preference: primary-source appendix

Research checked: **2026-10-08T08:24:48-05:00**. Living appendix to the UI color study; descriptive screenshot measurements belong in the main document. Publication dates below describe sources, not a claim that a design rule was discovered on that date.

## Core conclusion

OKLCH provides useful perceptual coordinates for comparing UI palettes. It does not provide hue-independent accessibility guarantees or universal preference ranges. Treat screenshot popularity as descriptive evidence; validate text/background pairs separately using the applicable accessibility requirement and real text size/weight.

## Verified source register

| ID | Primary source | Publication or version date | Scope |
| --- | --- | --- | --- |
| S1 | [Björn Ottosson: A perceptual color space for image processing](https://bottosson.github.io/posts/oklab/) | 2020-12-23; introduction added 2025 | Oklab author explanation, transforms, model design and limits |
| S2 | [W3C CSS Color 4](https://www.w3.org/TR/css-color-4/) | Candidate Recommendation Draft, 2026-10-07 | OKLCH definition, conversion, gamut mapping |
| S3 | [W3C CSS Color 5](https://www.w3.org/TR/css-color-5/) | Working Draft, 2026-09-13 | Relative colors, mixing, theme-dependent colors |
| S4 | [W3C WCAG 2.2](https://www.w3.org/TR/2024/REC-WCAG22-20241212/) | Recommendation, 2024-12-12 | Contrast criteria and relative-luminance formula |
| S5 | [Myndex APCA reference implementation](https://github.com/Myndex/apca-w3) | README identifies library 0.1.9 beta, 2022-07-03; base algorithm 0.0.98G-4g, 2021-02-15; checked 2026-10-08 | Additional perceptual contrast model, not independent evidence of preference |
| S6 | [W3C WCAG 3.0](https://www.w3.org/TR/2026/WD-wcag-3.0-20260910/) | Working Draft, 2026-09-10 | Status of future accessibility guidance |
| S7 | [Palmer and Schloss: An ecological valence theory of human color preference](https://doi.org/10.1073/pnas.0906172107) | 2010; publisher issue 2010-05-11 | Experimental preference model |
| S8 | [Taylor, Clifford, and Franklin: Color preferences are not universal](https://pubmed.ncbi.nlm.nih.gov/23148465/) | Online 2012-11-12; issue 2013-11 | Cross-cultural preference evidence |
| S9 | [Piepenbrock, Mayr, and Buchner: Smaller pupil size and better proofreading performance with positive than with negative polarity displays](https://pubmed.ncbi.nlm.nih.gov/25135324/) | 2014 | Polarity, pupil size, proofreading experiment |
| S10 | [Ottosson: sRGB gamut clipping](https://bottosson.github.io/posts/gamutclipping/) | 2021-01-25 | Hue-dependent gamut slices and mapping tradeoffs |
| S11 | [Ottosson: Two new color spaces for color picking — Okhsv and Okhsl](https://bottosson.github.io/posts/colorpicker/) | 2021-09-08 | Independence of perceptual coordinates versus gamut geometry |
| S12 | [W3C: Understanding Contrast (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) | Living explanatory page; checked 2026-10-08 | Typography, threshold rounding, source colors versus antialiasing |
| S13 | [W3C: Understanding Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) | Living explanatory page; checked 2026-10-08 | Essential control/state/graphic cues |
| S14 | [W3C: Understanding Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) | Living explanatory page; checked 2026-10-08 | Redundant semantic cues |
| S15 | [W3C technique G18](https://www.w3.org/WAI/WCAG22/Techniques/general/G18) | Living technique; checked 2026-10-08 | Reproducible sRGB luminance calculation |
| S16 | [Schloss, Strauss, and Palmer: Object color preferences](https://doi.org/10.1002/col.21756) | Online 2012-07-18; correction 2012-08-13; journal issue 2013 | Context changes lightness/saturation preferences |
| S17 | [Schloss and Palmer: Aesthetic response to color combinations: preference, harmony, and similarity](https://pubmed.ncbi.nlm.nih.gov/21264737/) | Online 2010-11-10; journal issue 2011-02 | Pair preference, harmony, and foreground preference differ |
| S18 | [Piepenbrock, Mayr, and Buchner: Positive display polarity is particularly advantageous for small character sizes](https://pubmed.ncbi.nlm.nih.gov/25141597/) | Journal issue 2014-08 | Polarity × text-size experiment |

Versioned snapshots: [CSS Color 4, 2026-10-07](https://www.w3.org/TR/2026/CRD-css-color-4-20261007/) and [CSS Color 5, 2026-09-13](https://www.w3.org/TR/2026/WD-css-color-5-20260913/). Both are drafts. A specification's existence does not establish browser support for every feature.

All findings below are **paraphrases**, except equations and source titles. Computed examples are this study's derivations, not values reported by experimental participants.

## Four quantities that must stay separate

| Quantity | What it measures | What it cannot establish |
| --- | --- | --- |
| OKLCH `L` | Model estimate of perceptual lightness | WCAG contrast, physical display luminance, universal liking |
| OKLCH `C` | Distance from the neutral axis | Percentage saturation or hue-independent distance to a display gamut boundary |
| Relative luminance `Y` | Linear-light weighted RGB quantity for a specified color space | Preference or overall legibility by itself |
| `ΔEOK` | Euclidean color distance in Oklab | Text/background contrast requirement |

In CSS, `L=1` and `L=100%` express the same OKLCH coordinate; `C` is not restricted to a universal 0–1 gamut scale. Cartesian/polar conversion is `a=C cos(h)`, `b=C sin(h)`, `C=√(a²+b²)`, `h=atan2(b,a)`. Hue is undefined when `C=0`. [CSS Color 4 definitions and conversion](https://www.w3.org/TR/css-color-4/#ok-lab).

Oklab transforms D65 XYZ or linear sRGB through a cone-response approximation, cube roots, and another matrix. Therefore `L` is not a linear luminance coordinate. Ottosson also warns that part of his lightness/chroma comparison uses CAM16-generated data, which cannot decide which model best matches human perception. [Author's original derivation](https://bottosson.github.io/posts/oklab/).

For normalized sRGB channel `u`, linearize first:

```text
f(u) = u/12.92                      if u ≤ 0.04045
       ((u+0.055)/1.055)^2.4        otherwise
Y = 0.2126 f(R) + 0.7152 f(G) + 0.0722 f(B)
```

Do not apply the weighted sum directly to gamma-encoded hex channels. Other RGB primaries require their own conversion to XYZ/luminance; do not feed Display P3 channels into an sRGB formula. [W3C G18 luminance procedure](https://www.w3.org/WAI/WCAG22/Techniques/general/G18).

Color distance is:

```text
ΔEOK = √((L₂−L₁)² + (a₂−a₁)² + (b₂−b₁)²)
      = √((ΔL)² + C₁² + C₂² − 2C₁C₂ cos(Δh))
```

Second line is algebraic substitution. A hue difference may make `ΔEOK` large while luminance contrast remains low. CSS's `0.02` local-MINDE gamut-mapping tolerance is not a text, border, or accessibility threshold. [CSS Color 4 difference metric](https://www.w3.org/TR/css-color-4/#color-difference-OK), [gamut-mapping context](https://www.w3.org/TR/css-color-4/#GMA-Binary-local-MINDE).

## Equal lightness and chroma do not guarantee equal contrast

Computed counterexample, using Ottosson's inverse matrices updated **2021-01-25**, followed by the sRGB luminance calculation above. Every row is in sRGB gamut before quantization; `L=0.57`, `C=0.08`, solid opaque color against white. These values illustrate a failure of an assumption; they are not a proposed palette. [Inverse transform](https://bottosson.github.io/posts/oklab/), [contrast definition](https://www.w3.org/TR/WCAG22/#dfn-contrast-ratio).

| Hue, degrees | Computed `Y` | Contrast against white | Meets 4.5:1? |
| --- | ---: | ---: | --- |
| 30 | 0.176798 | 4.629671 | Yes |
| 90 | 0.184988 | 4.468305 | No |
| 140 | 0.192999 | 4.321007 | No |
| 200 | 0.194041 | 4.302558 | No |
| 270 | 0.182837 | 4.509592 | Yes |
| 330 | 0.175864 | 4.648815 | Yes |

The OKLCH coordinates match in two dimensions while the accessibility result changes with hue. A shared `L/C` role recipe is a starting parameterization; verify the rendered pair after hue selection, gamut mapping, alpha compositing, and output quantization. Screenshot samples cannot recover all those source operations.

## Quantitative contrast constraints that are defensible

WCAG 2.2 uses `(Ylighter+0.05)/(Ydarker+0.05)`. It is symmetric when text and background swap; real reading performance need not be. Normal text AA requires **4.5:1**; large text AA **3:1**; normal text AAA **7:1**. Large text means at least 18 pt regular or 14 pt bold, subject to the definition's typeface caveat. [WCAG 2.2 criteria and glossary](https://www.w3.org/TR/WCAG22/#contrast-minimum).

For target ratio `r`, algebra gives:

```text
dark foreground on light background: Yfg ≤ (Ybg + 0.05)/r − 0.05
light foreground on dark background: Yfg ≥ r(Ybg + 0.05) − 0.05
```

If a bound is below zero or above one, the requested pairing is infeasible in normalized SDR luminance; change a background or target role. For a neutral color only, Oklab's transform gives `Y ≈ L³` (small matrix-rounding differences). That special case yields these illustrative limits:

| Pair with neutral background | Target `r` | Background `Y` bound | Approximate neutral `L` bound |
| --- | ---: | ---: | ---: |
| White foreground | 3 | ≤ 0.300000 | ≤ 0.669433 |
| White foreground | 4.5 | ≤ 0.183333 | ≤ 0.568086 |
| White foreground | 7 | ≤ 0.100000 | ≤ 0.464159 |
| Black foreground | 3 | ≥ 0.100000 | ≥ 0.464159 |
| Black foreground | 4.5 | ≥ 0.175000 | ≥ 0.559344 |
| Black foreground | 7 | ≥ 0.300000 | ≥ 0.669433 |

These are **derived neutral contrast bounds**, not preferred light/dark theme ranges. They cease to be a shortcut when `C>0`.

Ratios are strict thresholds: 4.499 does not pass 4.5. Use authored/computed foreground and background colors for the normative test; antialiased edge pixels can understate source contrast. Thin strokes still warrant stronger colors or fonts because a nominal pass does not ensure good practical readability. [W3C typography and evaluation notes](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

Required control/state cues and meaningful graphics generally require **3:1 against adjacent colors**. This does not mean every card or decorative surface must have 3:1 contrast. Identify the visual information needed to recognize and operate the control. [W3C Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

## Chroma capacity depends on hue, lightness, and gamut

Define, for gamut `G`:

```text
Cmax(L,h,G) = largest C whose RGB_G(L,C,h) lies inside that gamut
ρ = C / Cmax(L,h,G)       when Cmax > 0
```

This is a derived analysis tool. `ρ` reports proximity to a gamut boundary; it is not perceived saturation or aesthetic preference. At a fixed hue, sRGB has a changing lightness/chroma boundary with a hue-dependent cusp. [Ottosson's primary gamut analysis](https://bottosson.github.io/posts/gamutclipping/).

Computed sRGB boundary examples at `L=0.65`, using the same inverse transform and 60 bisection iterations over `C∈[0,0.5]`:

| Hue, degrees | Approximate `Cmax` |
| --- | ---: |
| 30 | 0.236433 |
| 90 | 0.132832 |
| 140 | 0.209252 |
| 200 | 0.110504 |
| 270 | 0.186042 |
| 330 | 0.296280 |

This sample does not give the global minimum across all hues or prove every intermediate hue is valid. A genuinely hue-independent chroma ceiling at a chosen `L` must use `min_h Cmax(L,h,G)` over the supported hue domain, with a numerical safety margin. For a whole lightness interval, minimize over both `L` and `h`.

Independent perceptual hue/lightness/chroma controls and a simple cylindrical bounded RGB gamut cannot all be satisfied at once. Okhsl/Okhsv remap coordinates to address picking ergonomics; those remapped saturation values are not OKLCH chroma. [Ottosson's color-picker tradeoff discussion](https://bottosson.github.io/posts/colorpicker/).

## Light and dark themes: evidence, not an inversion rule

CSS Color 5 explicitly models separate light/dark colors. Its link example uses a dark blue for white and a much lighter blue for black. `contrast-color()` selects black or white for a solid background, with the precise contrast algorithm left to the user agent in this draft. Neither function defines a universal `L→1−L` palette transformation. [CSS Color 5 theme-dependent colors](https://www.w3.org/TR/css-color-5/#light-dark), [contrast-color definition](https://www.w3.org/TR/css-color-5/#contrast-color).

**Polarity experiment:** Piepenbrock et al. studied 35 participants aged 20–30 after exclusions, using German proofreading passages. Dark text on a light display produced smaller pupils and better proofreading. Authors identify low ambient illumination and young healthy participants as limits; their pupil correlation does not experimentally prove pupil size caused the performance change. This supports testing reading tasks and lighting conditions, not declaring all dark UIs harmful. [2014 paper, author-hosted accepted manuscript](https://www.psychologie.hhu.de/fileadmin/redaktion/Oeffentliche_Medien/Fakultaeten/Mathematisch-Naturwissenschaftliche_Fakultaet/Psychologie/AAP/Publikationen/in_press/Piepenbrock-in_press-Smaller_pupil_size_and_better.pdf), [publication record](https://pubmed.ncbi.nlm.nih.gov/25135324/).

**Text-size experiment:** A separate proofreading study tested black-on-white and white-on-black at 8, 10, 12, and 14 pt. The advantage of positive polarity grew as characters got smaller. UI inference: avoid combining small, thin, faint text with a dark theme; test the actual type and device. The experiment establishes no OKLCH background interval. [2014 primary study](https://pubmed.ncbi.nlm.nih.gov/25141597/).

APCA additionally accounts for polarity through different exponents and provides contrast-dependent font-size/weight lookup tables. Its signed `Lc` is neither OKLCH `L` nor a WCAG ratio. Pin the algorithm/library/table versions if reporting it. The inspected project labels itself public beta; WCAG 3 remains a Working Draft. Use APCA as an additional design diagnostic, while reporting WCAG 2 results separately when that is the requirement. Do not turn the model author's legal or superiority claims into independent validation. [APCA source and version notes](https://github.com/Myndex/apca-w3), [W3C draft status](https://www.w3.org/TR/2026/WD-wcag-3.0-20260910/#sotd).

## What preference experiments actually support

| Study | Supported finding | Limit for this UI study |
| --- | --- | --- |
| Palmer and Schloss, 2010 | 48 participants rated 32 chromatic colors. An object-association predictor accounted for 80% of variation in average color preferences in this dataset. Associations and experience are plausible explanatory variables. | Berkeley-region participants and contextless samples do not provide universal UI token values or conversion-rate evidence. [Original author PDF](https://palmerlab.berkeley.edu/pdf/Palmer%26Schloss%282010%29.pdf). |
| Taylor et al., 2013 | British and Himba preferences differed strongly; a single tested model did not explain both cultures. The Himba results lacked several patterns previously described as universal. | This challenges universal blue/green/chroma stories; it does not prove that every culture differs on every dimension. [Primary article abstract/record](https://pubmed.ncbi.nlm.nih.gov/23148465/). |
| Schloss et al., 2012/2013 | Preferences changed especially in lightness/saturation. Saturated colors were favored as contextless squares but disfavored for studied objects. Imagined, depicted, and physical T-shirt preferences agreed closely. | Experiment 1 reuses the 2010 study's 48 participants. Walls, clothing, and furniture are not UI screens; role/context dependence for UI is a hypothesis. [Author PDF](https://palmerlab.berkeley.edu/pdf/Schloss%20Strauss%20Palmer.pdf), [publisher and correction](https://doi.org/10.1002/col.21756). |
| Schloss and Palmer, 2011 | Pair liking, harmony, and liking of a figure against a background are different judgments. Hue similarity aided pair harmony, while figural preference could benefit from hue contrast. | A palette can look harmonious yet fail a figure/background task. These aesthetic ratings are not WCAG or task-success measurements. [Primary record](https://pubmed.ncbi.nlm.nih.gov/21264737/). |

Consequently, no universal `L` or `C` interval for “colors humans like” follows from this evidence. A popularity sample can reveal recurring palette structures; explaining their appeal requires competing hypotheses about role, area, context, content, brand familiarity, and audience.

The object study found no main preference effect between small squares and full-screen fields within its tested monitor conditions. Its object-context differences therefore cannot establish that pixel area itself caused a preference change. Distinguish an image's measured area composition from a tested preference for that composition. [Object study, experiment 1](https://doi.org/10.1002/col.21756).

## Practical do/don't rules

| Do | Don't | Evidence or status |
| --- | --- | --- |
| Compare `L/C` distributions within the same role and theme. | Pool background pixels and accent pixels, then call the pooled average a preferred color. | Analysis design: area-weighted pixels answer a different question from role-weighted palettes. |
| Use OKLCH to tune a color, then calculate the actual foreground/background ratio. | Assume common `L/C` guarantees accessibility after hue changes. | Computed equal-`L/C` counterexample above. |
| Check gamut after changing hue; lower chroma or adjust lightness deliberately. | Treat a fixed chroma as equally attainable for yellow, cyan, and magenta. | Hue-dependent gamut boundaries. |
| Author light/dark semantic roles and recheck each pairing. | Invert lightness blindly or reuse a dark link on a dark background. | CSS Color 5 example and contrast bounds. |
| Give status, selection, and errors additional labels/shapes/icons. | Encode meaning only through hue. | [W3C Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html). |
| Preserve readable source colors and sufficiently strong glyphs. | Copy tiny muted screenshot labels and assume their popularity proves legibility. | W3C typography notes and polarity experiments. |
| Label screenshot findings observational and population-specific. | Claim views/likes demonstrate color caused engagement, comfort, or usability. | Study design limitation: color is not randomized; popularity has many confounders. |
| Report `ΔEOK`, WCAG ratio, and APCA `Lc` in separate named columns. | Substitute one for another or call a `0.02` difference accessible. | Distinct quantities, tasks, and model versions. |

## How to keep this appendix current

1. Preserve dated specification links when updating a finding; check the latest URL for changes and record the new version date.
2. For each numerical recommendation, label it **normative**, **computed**, **observed**, or **proposed design starting point**.
3. If proposing hue-independent `L/C` bands, record role, theme, target gamut, hue domain, text size/weight, and the worst measured contrast. Sampled safe values are not a continuous-domain proof.
4. Re-evaluate proposed preference ranges with the target audience and actual task. Track preference, reading/task performance, and accessibility separately.

Coverage: primary color specifications, author-level color math, WCAG requirements, two polarity experiments, and four empirical preference studies. This appendix does not establish a causal effect of Dribbble palette choices, a universal preference distribution, or a complete accessibility audit of sampled screenshots.
