# Writing quality review — human-facing content

**Purpose:** Find observable defects in generated or edited prose. This is an editorial review, not an AI-authorship detector. Apply proportionally; a one-line label needs less review than a new README.

## Before drafting

- **Reader and job:** Who reads this, what do they know, and what must they decide or do next? Preserve the user-provided style, including deliberate humor or a literary voice where appropriate.
- **Source:** Inspect the current product, code, documents, command output, or other evidence. Record meaningful unknowns. Don't silently turn planned behavior into a shipped feature.
- **Structure:** Define the central claim, supporting proof, logical order, and next action. Choose the actual reader language/locale and product voice. Do not add a dramatic introduction or artificial three-part framework unless it serves the task.

## Review gates

| Gate | Diagnose | Repair |
| --- | --- | --- |
| Source and claim | Would a reasonable reader mistake a hypothetical example, vendor promise, or inference for verified behavior? | Qualify it, link exact evidence, or remove it. Never fabricate activity or outcomes. |
| Specificity | Could the paragraph be reused unchanged for another product? Are named components and constraints accurate? | Replace vague praise with real interfaces, actions, boundary cases and consequences. |
| Causal logic | Does each explanation connect cause → mechanism → consequence? Does a later statement contradict an earlier one? | Fill the missing inference with supported steps, or narrow the claim. |
| Metaphor/story | Can you map the actual event to the technical concept without inventing a false equivalence? Is the source story accurate? | Explain the mapping and its limits outside the artwork; drop forced parallels. |
| Subtraction | If a sentence, heading, adjective or example is removed, does comprehension or action suffer? | Remove needless restatement, throat-clearing and padding. |
| Publication boundary | Does reader-facing material contain editing notes, internal version-change narratives, prompt instructions, chain-of-thought, or publisher-only operations? | Remove internal material before publishing. Retain real compatibility notices, supported limits, and evidence that affect the reader. |
| Voice and cadence | Does the prose sound monotonously polished, overexcited, patronizing, formulaic, or unnatural in the target language? | Use natural rhythm, precise verbs, clear sentences and the requested register. Preserve meaningful nuance; do **not** ban individual words or enforce a fixed word count. For English/Bahasa Indonesia apply RASA in `PLAIN_LANGUAGE_AND_RASA.md`. |
| Reality | Do links resolve? Do commands exist? Can the described user complete the promised action? Do examples expose failure paths? Does reassuring error copy reflect verified state? | Inspect assets, run safe checks where possible, and label all untested behavior. Do not invent saved data, safety guarantees or progress. |

## Special treatment by content type

- **README / landing page:** Lead with product, actual problem and next step. Exclude backstage editorial and change-history commentary. Give one complete, credible use case. Differentiate intended behavior from tested results. Verify installation requirements, paths and links. End with an actionable next step, not a slogan substituted for evidence.
- **Tutorial:** Use real preconditions, executable steps, expected results and failure recovery. Do not invent command output.
- **Technical explanation:** Maintain term consistency and correct sequence. Address important failure modes. Do not bury qualifications in footnotes.
- **UI and error copy:** Preserve GUI-owned states, accessible persistent labels, actual outcomes, destructive consequences, permissions and supported recovery. Avoid blame and false urgency. Do not invent a permission, saved draft or status.
- **Creative/editorial copy:** Distinctiveness can include rhythm, metaphor and vivid language. Evaluate whether images and rhetoric serve the user's intention; do not flatten valid prose into sterile bullet points.

## How to report

For material writing tasks, note concrete failures and repairs, not an invented 'slop score'. A concise review can name **Changed**, **Verified**, **Illustrative/Unverified**, and **Open**. A review is not evidence of audience comprehension: use real readers and task testing when stakes justify it. For English or Bahasa Indonesia, the RASA passes check rhythm, precision, meaning and natural voice without replacing source verification or human comprehension testing.
