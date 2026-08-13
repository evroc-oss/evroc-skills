# Blog SEO Validation Checklist

Reference checklist for validating on-page SEO of a completed evroc blog post.
Run after writing — catches issues before publishing.

## Usage

Perform each Step by reading the blog post file (or fetching from URL) and evaluating
against the Pass Criteria below. Generate a report in the SEO report format defined
at the end.

## Step 1: Read Content

Extract from the blog post:

- **Frontmatter** — title, description, date, lastUpdated, author, tags, canonical, og:image, slug/URL
- **Heading structure** — H1, H2, H3 hierarchy with full text
- **Links** — All internal and external links with anchor text
- **Meta tags** — OG tags, Twitter Card tags, canonical URL
- **Structured data** — JSON-LD or microdata types, required fields, syntax validity
- **Body content** — Full text for keyword and structural analysis

## Step 2: Title Tag Validation

| Check | Pass Criteria |
|---|---|
| Accuracy | Describes the visible page without exaggeration |
| Purpose fit | Makes the reader task or subject clear |
| Distinctiveness | Is not generic or interchangeable with unrelated pages |
| Truncation resilience | Critical meaning survives device-dependent previews |
| Uniqueness | Specific to the content |

## Step 3: Meta Description

| Check | Pass Criteria |
|---|---|
| Character count | Concise, page-specific summary. Flag truncation/duplication risk; not a hard length gate |
| Statistic included | Optional — use a number only when it reflects visible, sourced content |
| Reader value | States what the page helps the reader understand or do |
| Topic consistency | Uses natural terminology consistent with visible content |
| Accuracy | Makes no claim absent from the page |

## Step 4: Heading Hierarchy

| Check | Pass Criteria |
|---|---|
| Single H1 | Exactly one H1 tag (the title) |
| No skipped levels | H1 → H2 → H3, never H1 → H3 or H2 → H4 |
| Topic consistency | Headings accurately label their sections |
| Heading format | Use questions for question-led intent; descriptive headings otherwise |
| Section coverage | Include only sections needed for the reader task |
| Heading clarity | Concise wording; no character quota |

## Step 5: Internal Links

| Check | Pass Criteria |
|---|---|
| Link count | 3–10 internal links per post |
| Anchor text | Descriptive (not "click here" or "read more") |
| Bidirectional | Check if linked pages also link back (flag if not) |
| No orphan status | Post links to at least 3 other site pages |
| Link distribution | Spread across the post, not clustered |
| No self-links | Post does not link to itself |

## Step 5.5: Link Deduplication

| Check | Pass Criteria |
|---|---|
| No duplicate URLs | Each URL appears at most once in body content |
| Best instance kept | If duplicates exist, keep the one with most descriptive anchor text |
| Navigation exempt | Header/footer nav links don't count toward body dedup |
| Fragment normalization | URLs with different #fragments treated as same URL |

## Step 6: External Links

| Check | Pass Criteria |
|---|---|
| Source tier | Links to tier 1–3 sources only (authoritative, not SEO blogs) |
| Broken links | Verify top external links are reachable |
| Rel attributes | `rel="sponsored"` for paid, `rel="ugc"` for user-generated, `nofollow` otherwise |
| Link count | At least 3 external links to authoritative sources |
| No competitor links | Not linking to direct competitors unnecessarily |

## Claim Provenance

Verify that each material factual claim has enough support to identify, verify, and
interpret its source. Relevant details include:

- Publisher or document title
- Publication date or study period
- Methodology and limitations
- Stable URL
- Retrieval date for changeable or undated material

Unverifiable claims must be removed or replaced.

## Step 7: Canonical URL

| Check | Pass Criteria |
|---|---|
| Present | Defined in frontmatter or meta tags |
| Correct format | Full absolute URL (`https://domain.com/path`) |
| Trailing slash | Consistent with site convention |
| Self-referencing | Canonical points to the page itself |

## Step 8: OG Meta Tags

| Check | Pass Criteria |
|---|---|
| og:title | Present, matches or complements the title tag |
| og:description | Present, concise, page-specific, compelling for social sharing |
| og:image | Present, 1200×630 minimum, absolute URL |
| og:type | Set to `article` for blog posts |
| og:url | Present, matches canonical URL |
| og:site_name | Present, matches site/brand name |

## Step 9.5: Structured Data

| Check | Pass Criteria |
|---|---|
| Article schema | Article or BlogPosting present with headline, author, datePublished |
| Entity schema | Person and Organization present where the site provides author and brand data |
| Breadcrumb schema | BreadcrumbList present for indexable blog posts |
| JSON-LD validity | Valid JSON, no duplicate conflicting entities, URLs absolute where required |
| Date consistency | dateModified aligns with normalized lastUpdated/updated/lastmod |
| FAQPage — optional | If present, valid as entity markup only. FAQPage is not a Google rich result post-2026-05-07 and should not outrank Article priority |

Prioritize: Article/BlogPosting + Person + Organization + BreadcrumbList.

## Step 10: Report Format

```text
## SEO Validation Report: [Title]

**File**: [path or URL]
**Date**: [check date]
**Overall**: [X/Y passed] — [PASS/NEEDS WORK/FAIL]

### Results

| # | Check | Status | Details | Fix |
|---|-------|--------|---------|-----|
| 1 | Title accuracy | PASS | Matches visible page purpose | - |
| 2 | Heading hierarchy | PASS | Clean hierarchy | - |
| ... | ... | ... | ... | ... |

### Summary

**Passed**: [N] checks
**Failed**: [N] checks

### Priority Fixes
1. [Most impactful fix]
2. [Second most impactful]
3. [Third most impactful]

### Notes
- [Overall SEO health observations]
```

Status values: **PASS**, **FAIL**, **WARN**, **N/A**.
