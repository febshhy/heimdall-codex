# Conditional SEO for interface design and copy

SEO is **not** an interface-wide requirement. Activate only if a surface is a public, indexable web page intended to be found through search. User value, accuracy, navigation and accessibility take priority. A private dashboard, payment confirmation, protected account screen, ephemeral state or blocked/noindex route usually has no SEO task.

## Gate: decide applicability

Record `Public? | Indexable? | Search intent? | Real content value? | SEO owner?`. If unknown, confirm before designing for indexing. Do not turn a private screen public to satisfy a search checklist.

## If applicable, design and check

1. **Purpose and intent:** page answers a defined question or job for a real audience. No copied/rewritten filler or manufactured topical authority.
2. **Content:** unique, accurate, useful page text based on verified knowledge. Clear headings that reflect actual content and terms users use naturally. Avoid keyword repetition.
3. **Information architecture:** meaningful links with real, crawlable destinations; user-friendly hierarchy, accessible navigation, correct page purpose.
4. **Metadata:** unique descriptive page title, helpful description, correct language, canonical/indexation strategy, sharing metadata where relevant. Validate the rendered output; never fabricate metadata claims.
5. **Rendering:** ensure key content and links are discoverable to crawlers, especially in JS-heavy sites. Server-render/prerender where justified; account for HTTP status semantics, lazy-loading, robots rules.
6. **Structured data:** only add types that correctly describe visible content and are eligible for supported search features; validate without expecting a ranking guarantee.
7. **Measurement:** separate indexing from rankings and conversions; measure meaningful outcomes with consent-aware analytics if available.

## Anti-slop and SEO

Google states that scaled AI-generated content without user value can violate spam policy, and that AI-assisted content requires accuracy checks. Do not produce large sets of near-duplicate SEO pages or invent expertise, reviews, FAQs, authors, prices or product specifications.

SEO cannot justify deceptive UI, accessibility regressions, fabricated copy, or adding unrelated marketing sections to a transactional flow.

## Sources

- Google Search Essentials: https://developers.google.com/search/docs/essentials
- Helpful people-first content: https://developers.google.com/search/docs/fundamentals/creating-helpful-content
- Generative AI content guidance: https://developers.google.com/search/docs/fundamentals/using-gen-ai-content
- JavaScript SEO basics: https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics
