---
name: evroc-blog-writing
description: "Use when the user asks to write, draft, edit, review, or optimize a blog post for evroc. Covers technical writing standards, brand voice enforcement, editorial review, and SEO validation per evroc requirements. Requires the blog post content as a file or URL. Do NOT trigger for newsletter drafts, changelog entries, API documentation, marketing emails, social media posts, or non-evroc content."
license: Apache-2.0
compatibility: "For Hermes Agent, Claude Code, Cursor, or any agent with web_search, read_file, and write_file. Internet access useful for competitive research."
metadata:
  author: evroc
  version: "1.0"
  category: content
allowed-tools: terminal, read_file, write_file, search_files, web_search
---

# evroc-blog-writing

Write, edit, and review blog posts that meet evroc's technical writing standards.
Enforces brand voice, banned language, structural patterns, and SEO via a
referenceable checklist.

## When to Use

- User says "write a blog post about..." and mentions evroc
- User asks to review, edit, or improve an evroc blog draft
- User asks for SEO optimization of an evroc blog post
- User wants to translate technical content into evroc brand voice
- User mentions "evroc blog", "developer blog", or "content marketing" in context of writing

**Do NOT use for:** newsletter drafts, changelog entries, API documentation,
marketing emails, social media posts, product one-pagers, or non-evroc content.
Those have different formats and audiences.

## Workflow

1. **Concept Interview** — Determine the problem the post solves and the target audience
2. **Competitive Research** — Find comparable published posts as reference
3. **Draft** — Follow structure and tone rules below
4. **Edit** — Apply banned-language cleaning and structural fixes
5. **SEO Validation** — Run the checklist in [`references/seo-validation.md`](references/seo-validation.md)

## Concept Interview

Before drafting, clarify:

1. **Problem & Benefit** — What does this feature/insight solve for a developer?
2. **How it works** — How can the reader get hands-on and start using it?
3. **Technical depth** — Any architecture, trade-offs, or interesting implementation details?
4. **Target persona** — SRE, platform engineer, startup founder, enterprise architect?

If the user does not provide this context, ask explicitly. Do not infer.

## Competitive Research

Find 2–3 comparable published posts as reference:

1. Ask the user for links to similar articles they like.
2. If they cannot provide any, run:
   ```bash
   web_search "blog post about <topic>"
   ```
   ...and present the top 3 results. Ask the user to confirm which match the vibe they want.

Use these as style/depth benchmarks, not as content to copy.

## About evroc

evroc is The European Cloud, a sovereign cloud and AI services company committed to
strengthening Europe's digital capability, independence and security. Launched in 2025
evroc is building Europe's truly sovereign cloud platform for the AI era, combining
modern cloud performance with operational resilience, data residency in Europe, and
complete platform and software control.

The platform supports scalable deployment of AI workloads and is designed for
mission-critical environments and organisations that require the highest standards
of security and compliance, including public authorities, defence organisations and
operators of essential services.

Headquartered in Stockholm, evroc operates entirely within Europe and is built from
the ground up to meet European regulatory and data sovereignty requirements. It is
fully European-owned and controlled, with zero dependencies on externally controlled
software. evroc operates active cloud regions with redundant data centers and AI
infrastructure in Stockholm, Paris and Frankfurt, supported by development teams across
Sweden, France and the United Kingdom.

Backed by leading European investors including EQT Ventures, Norrsken VC, Giant
Ventures and blisce, evroc's mission is to build a competitive, independent cloud
platform that strengthens Europe's digital resilience, innovation capacity and
long-term technological capability.

## Tone of Voice

**We sound like:** A senior developer at a conference afterparty explaining something
they're genuinely excited about — smart, specific, a little irreverent, deeply
knowledgeable.

**We don't sound like:** A corporate blog, a press release, a sales deck, or an
AI-generated summary.

- Be technically precise, opinionated, and direct.
- Use "we" (evroc) and "you" (the reader). This is a conversation, not a paper.
- No passive voice where active voice works.
- No hedging: "it is believed that" → "we chose this because".

## Banned Language

Never use these. Flag and rewrite on sight:

| Banned | Why | Rewrite |
|---|---|---|
| "We're excited/thrilled to announce" | Just announce it. | "X is now available." |
| "thrilled" | Tells people they should be excited. | Explain *why* they should be excited. |
| "revolutionary" | Filler, no information content. | Describe the actual change. |
| "disrupting" | Banned word. | "replacing" or " obsolete" if true. |
| "journey" | Corporate speak. | "process", "path", or remove entirely. |
| Any urgency/desperation signals | "Don't miss out", "Limited time" — not our voice. | None. Delete. |
| "Best-in-class" / "industry-leading" / "cutting-edge" | Show, don't tell. | Include a benchmark or specific claim. |
| "Seamless" / "seamlessly" | Nothing is seamless. | Describe what actually happens. |
| "Empower" / "leverage" / "unlock" | Say what you mean. | "lets you", "enables", "gives access to" |
| "Robust" | Describe what makes it robust. | "resilient to X", "handles Y without Z" |
| "At [Company], we believe..." | Just state the belief. | "X is true because..." |
| "Streamline" | Everyone is streamlining. | "simplifies", "reduces steps", or be specific. |
| "That being said," / "It's worth noting that," / "At the end of the day" / "Without further ado" / "As you might know" | Filler transitions. | Delete or replace with an actual transition. |
| "In this blog post, we will explore..." | Be direct. Just start. | Delete the sentence entirely. |

## Positive Language Examples

- "The platform is live and serving clients in regulated sectors today."
- "Sovereignty is not a feature. It is an architectural property."
- "evroc was built to address a structural problem, not a temporary market gap."
- "The platform supports AI and mission-critical workloads across the full stack."
- "Europe now has a path to build its own hyperscale capability."
- "Founded in 2022, evroc has been building this from the ground up."
- "Every layer of the stack is under European ownership and control."

## Structure: Follow the Reader's Questions

Structure every post around what the reader is actually wondering, not your internal
narrative:

1. **What problem does this solve?** (1–2 paragraphs max)
2. **How does it actually work?** Not buttons-you-click, but underlying technology. (Bulk of the post — be specific)
3. **What were the trade-offs or alternatives?** (Separates good from great)
4. **How do I use/try/implement this?** (Concrete next steps)

For engineering deep-dives, also address:
5. **What did we try that didn't work?** (Builds trust)
6. **What are the known limitations?** (Shows intellectual honesty)

### The Opening

The opening must **state the problem** or **state the conclusion**. Never start with
background, company history, or hype.

**Good:** "Two weeks before launch, we killed our entire metrics product. Here's why
pre-aggregating time-series metrics breaks down for debugging."

**Bad:** "At Sentry, we're always looking for ways to improve the developer experience.
Today, we're thrilled to share some exciting updates..."

## Formatting for Skimmability

**Break paragraphs at contrast points.** When a sentence introduces "but," "however,"
or shifts perspective, start a new paragraph. Don't bury the turn inside a block
of text.

**One idea per paragraph.** Three-sentence paragraphs are fine. One-sentence paragraphs
are fine for emphasis.

**No em dashes.** Use commas, periods, or line breaks instead.

## Section Headings Must Convey Information

**Weak:** Background, Architecture, Results, Conclusion

**Strong:** "Why time-series pre-aggregation destroys debugging context," "The
scatter-gather approach to distributed GROUP BY," "Where this breaks down: the
cardinality wall"

## Technical Quality Standards

- **Numbers over adjectives.** "Reduced p99 from 340ms to 45ms" — not "significantly
  reduced."
- **Code must work.** If a post includes code, test it. Include imports, config, context.
  Comments explain *why*, not *what*.
- **Diagrams for systems.** If you describe a system with more than two interacting
  components, include a diagram. Label with real service names.
- **Honesty over hype.** Acknowledge limitations. If something is in beta, say so.
  If a competitor does something well, it's okay to note that.

## Title Guidelines

The title is the highest-leverage sentence in the post. It must stop a developer
scrolling through their feed.

**Strong:** "The metrics product we built worked. But we killed it anyway."
**Weak:** "Introducing our new metrics product"

## The Closing

End with something useful: a link to docs, source code, a way to try it, or a call
to give feedback. Never end with generic hype ("We can't wait to see what you build!")
or product-page CTAs.

## The "Would I Share This?" Test

Before publishing, ask: Would a developer share this post? Does it have a shot at
getting on Hacker News? If not, the post either needs more depth, more original
insight, or belongs in the changelog instead.

Posts worth sharing contain at least one of:
- A technical decision explained with trade-offs
- Original data or research not found elsewhere
- A real-world debugging story with specific details
- An honest accounting of something that went wrong
- A how-to that saves the reader real time

## AI Writing Patterns to Avoid

Flag and rewrite these:

| Pattern | Bad | Good |
|---|---|---|
| Staccato dramatic fragments | "No errors. No warnings. Everything green." | "There were no errors, no warnings; everything looked fine." |
| Bumper-sticker aphorisms | "You can't fix what you can't see." | "Without visibility into the full request lifecycle, you're guessing." |
| Three-beat reveals | "Not a config issue. Not a code bug. The deploy was stale." | "It wasn't a config issue or a code bug. The deploy was stale." |
| Smug simplicity | "That's it. That's all you need." | Explain what the code does, then move on. |
| Parallel structure ad copy | "Metrics tell you what's broken. Traces tell you why." | "Metrics show what's broken. Traces are where you'll figure out why." |
| Personality only at bookends | Personal intro → impersonal body → generic CTA | First-person asides woven through: "this is the part that tripped me up" |

## Word Count

Articles should be around 1,000–2,000 words. Do not stretch with filler to hit a quota.
If the point lands in 800 words, stop.

## Non-Negotiables

1. Never publish without a real person's name on it.
2. Never publish code that doesn't work.
3. Never say "we're excited to announce."
4. If you describe a system, include a diagram.
5. If you make a performance claim, include the number.
6. If you discuss a decision, explain what you didn't choose and why.
7. Every post must have a clear "who is this for" before writing begins.
8. Changelogs belong in the changelog. Blog posts offer something more.
9. When in doubt, go deeper.
10. Write the post you wish existed when you were trying to solve this problem.

## When Reviewing a Draft

Run both checklists:

**Technical Review:**
- All claims are accurate and verifiable
- Code samples work
- Numbers and benchmarks are correct
- No oversimplifications that would make an expert cringe

**Editorial Review:**
- Opening hooks within 2 sentences
- Passes the "would I share this?" test
- No corporate language, filler, or fluff
- Headings convey information
- Right length (not padded, not thin)
- Title is specific and compelling
- Author byline present (real person's name)
- Links to docs/getting-started included

## SEO Validation

After the draft is complete, run the SEO checklist:

```bash
# Read the full SEO validation reference
read_file("references/seo-validation.md")
```

Covers title tags, meta descriptions, heading hierarchy, internal/external links,
canonical URLs, OG meta tags, structured data, and claim provenance.

**Completion criterion:** Every item in the SEO checklist shows PASS or N/A.
