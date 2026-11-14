# Plain language and RASA — English and Bahasa Indonesia

**Use when:** Writing or reviewing English or Bahasa Indonesia copy, UI messages, help, guides, reports or public content. Use the project's approved terminology, voice and locale before these defaults. Do not translate or rewrite another language merely to follow this reference. Apply to reader-facing prose, not source code, literal UI/API identifiers, data, or direct quotations.

## Common content rules

1. **Reader's job first.** Establish audience, their context, what they need to know or do, the required action, and verified source facts. Put the result or action before background. Retain nuance and domain precision; plain language is not a license to omit conditions.
2. **One clear idea at a time.** Prefer concrete nouns, active verbs, short sentences and paragraphs, familiar terms, and descriptive headings. Aim for roughly 12–20 words where natural, but do not enforce a rigid sentence-length ceiling: accuracy, localization and readability take priority. Cut repetition and bureaucracy without flattening a deliberately literary or technical voice.
3. **Accessible and inclusive.** Avoid stereotypes, stigma, casual disability metaphors, gender/family assumptions, and language that presumes one living or economic situation. Use the terminology preferred by the affected community and the product's audience; people-first wording is not universally preferred. Do not rely on color, position or an unlabeled icon alone. Make links meaningful out of context.
4. **Give control and explain consequences.** State material consequences before destructive actions, consent or permissions. Do not blame readers for errors or use artificial urgency. Sensitive topics require factual, respectful, non-dramatic language and a way to stop when applicable. Never promise that data is safe, saved, restored or recoverable without verified product behavior.
5. **Reduce numeric load.** Break dense numbers into readable structures; show units, denominators and useful comparisons only when supported by facts. Do not invent illustrative equivalences as factual comparisons. Use consistent locale-aware grouping, decimal separators, currencies, dates, time zones and ranges. Explain essential calculations or offer an accessible way to perform them.
6. **UI copy follows the owned state contract.** A button names its real action. Labels remain present outside placeholders. Empty states describe the state and a valid next move; successes name the achieved result. Errors state what happened, what is known about the result, and the next supported action. Loading text and duration estimates must be true. Do not rewrite permissions, transitions, required fields or retry behavior through copy alone.
7. **Formatting serves the task.** Prefer sentence case for headings, labels and actions unless project conventions or proper names require otherwise. Avoid all-caps emphasis, decorative emphasis, filler jargon and culture-specific idioms. Preserve meaningful existing headings, examples, technical names and accessibility semantics. FAQ sections are conditional, not prohibited: use them only when they help real reader tasks better than information in context.

## Practical UI copy decisions

Use these only for interface surfaces the product actually has. Confirm the behavior with the owner of the UI state; wording must not introduce a new requirement or promise.

- **Labels and actions:** Keep visible, persistent field labels; placeholders may show an example format but never replace labels. Name the real action in buttons. Use precise, descriptive link text that works when read alone, not “click here” / “klik di sini”. Expand unfamiliar acronyms on first use when it helps the audience.
- **Tooltips and helper text:** Answer one practical question: what belongs in this field, why it is needed, or what an unfamiliar control does. Keep the help short and available to keyboard and assistive-technology users; do not hide mandatory information only in a tooltip.
- **Onboarding:** Use welcoming, non-coercive phrasing without implying that mandatory steps are optional. Explain required information and the actual ability to skip or return; do not invent escape routes.
- **Consent and permissions:** Explain the specific purpose, data access, consequences and meaningful choices **before** triggering a platform/system permission prompt. Match the scope and timing of the real prompt.
- **Errors and uncertainty:** State the observed problem and a supported next action. Where it matters, distinguish “not sent”, “may have been sent”, and “status unknown”. Do not claim that retry is safe, data is retained, or a payment failed unless confirmed.
- **Destructive confirmation:** Name the object, scope, reversibility and meaningful consequence before the user commits. Do not imply recovery is possible if it is not verified.
- **Loading and empty states:** Describe a real in-progress operation or absence and a supported next step; give duration estimates only if supported by measurement or product policy.

## Numerical and cognitive accessibility

- Split dense number clusters into labeled steps, lists or tables. Keep each number adjacent to its unit and meaning; do not require a reader to mentally calculate an unstated total or difference.
- For **percentages and comparisons**, show the baseline or denominator and the comparison period when they affect interpretation. If known, include before/after figures (for example, “from 100 to 70”); never invent them to make copy vivid.
- For **large numbers**, use a grounded comparison only when it clarifies scale and the comparison itself can be verified. Otherwise state the number with its unit plainly.
- For **instructions that depend on order**, use an ordered sequence and, where useful, “First / Next / Finally” or “Pertama / Berikutnya / Terakhir”. Do not number independent choices as if they were steps.
- Show critical calculations or provide an accessible calculation tool when the product requires readers to compute an answer. State date ranges and time zones unambiguously for the audience; preserve exact times and amounts from source data.

## English (en): natural, translation-friendly prose

- Follow the product's existing English variant (US/UK) and terminology. Use short, direct phrasing for readers who may not be fluent in English. Avoid idioms such as “touch base” and needless office language such as “leverage” where “use” is accurate. Technical terms are acceptable when necessary and explained to the intended audience.
- Use “you” for the reader and “we” for an actual accountable organization only when the product voice uses them. Prefer singular “they” when a person's gender is unknown; respect individual preferences.
- Prefer sentence case and descriptive actions: “Save document” rather than “Submit” if it actually saves a document. Use real field labels; placeholders are optional examples, not substitutes for labels.
- Make dates unambiguous (for example, “4 June 2026”). Use the audience's approved time and number conventions, with time zone where relevant. Avoid ambiguous “12 a.m.”/“12 p.m.” when “midnight”/“noon” is clearer. Avoid invented data to illustrate percentages or prices.
- Example error, **only when verified by the product**: “We couldn't send the message. Your draft is still available. Try again.” If draft retention is unknown, omit the second sentence.
- For public-facing prose, prefer readable full expressions over unexplained Latin abbreviations (“for example”, “that is”, “and so on”), obscure slashes and office shorthand. Use sentence punctuation for complete sentences; avoid unnecessary semicolons and all-caps emphasis. Use commas to prevent ambiguity, including a serial comma where it helps; retain project and locale punctuation conventions.
- Keep examples culturally legible and varied for the intended audience. Avoid assuming US/UK holidays, sports metaphors, city living, Western names or fast connectivity. Examples are illustrative, not demographic claims or invented product data.

## Bahasa Indonesia (id): alami, bukan terjemahan harfiah

- Gunakan Bahasa Indonesia yang lugas dan alami; ikuti ejaan baku dan pilihan istilah produk. Hindari pola kalimat terjemahan Inggris yang kaku, nominalisasi berlebihan, dan jargon seperti “sinergi” jika “bekerja sama” lebih tepat. Tetap gunakan istilah teknis yang memang diperlukan.
- Pilih “Anda” atau “kamu” sesuai pembaca dan suara produk; konsisten dalam satu konteks. Gunakan kata ganti yang tidak mengasumsikan gender. Hormati istilah yang dipilih komunitas terkait, termasuk apabila lebih memilih istilah identitas daripada orang-pertama.
- Gunakan huruf kapital untuk nama diri, nama resmi, dan awal kalimat. Utamakan sentence case pada judul, tombol dan label bila sesuai dengan gaya produk. Hindari huruf kapital untuk penekanan.
- Terapkan angka/tanggal yang jelas untuk konteks Indonesia: `Rp75.000`, `1.500,5`, `50%`, `4 Juni 2026`, dan waktu `10.00 WIB` jika zona waktu penting. Konvensi itu tidak menggantikan format data mesin atau aturan lokal lain yang disepakati produk.
- Tombol menyebut tindakan sebenarnya, misalnya “Simpan perubahan”. Untuk pesan kesalahan: jelaskan kejadian dan langkah berikutnya tanpa menyalahkan pengguna. Contoh **hanya jika sistem mendukungnya**: “Pesan belum terkirim. Coba lagi.” Jangan menjanjikan data aman tanpa bukti.
- Pertimbangkan kosakata atau penjelasan daerah untuk layanan lokal jika membantu pemahaman. Jangan mengasumsikan semua pengguna tinggal di kota besar, memiliki koneksi cepat, atau menggunakan perangkat terbaru.

- Untuk tulisan publik, utamakan kata lengkap seperti “misalnya”, “yaitu” dan “dan sebagainya” daripada singkatan Latin atau jargon yang membingungkan. Gunakan tanda baca pada kalimat lengkap; hindari tanda seru, titik koma dan cetak tebal berlebihan. Untuk rentang angka, utamakan “hingga” atau “sampai” bila lebih jelas; gunakan pemisah ribuan/desimal dan satuan yang sesuai konteks, termasuk “juta” atau “miliar” bila membantu pembacaan.
- Untuk instruksi penting, gunakan urutan “Pertama / Berikutnya / Terakhir” bila membantu. Gunakan nama contoh, istilah, dan konteks yang relevan dengan pengguna setempat; jangan menganggap semua pengguna berasal dari Jakarta atau latar budaya yang sama. Jangan memaksakan bahasa daerah jika justru mengurangi kejelasan.

## Review with RASA

RASA is a **qualitative review lens**, not a numeric score or an automatic publication approval. Use four passes; record concrete issues and repairs only where material.

| Pass | English | Bahasa Indonesia | Check |
| --- | --- | --- | --- |
| R | Rhythmic | Ritmis | Does the text read and sound naturally, with useful pauses and no awkward repetition? |
| A | Accurate | Akurat | Are the words, meanings, numbers, claims, and implications precise and source-supported? |
| S | Substantive | Sarat makna | Does each line help the reader understand or act, without empty persuasion or lost caveats? |
| A | Authentic | Alami | Does it sound natural for this audience, locale, context and approved product voice? |

**Run the passes as an actual edit procedure, in this order:**

1. **Rhythmic / Ritmis:** Read the copy aloud when practical, or inspect its spoken cadence. Check reading order separately when the interface requires it. Mark hard-to-say clusters, repetitive sentence lengths and misplaced pauses. Revise for natural rhythm without losing precision. Do not claim an aloud or assistive-technology test occurred unless it did.
2. **Accurate / Akurat:** Check words one by one for exact meaning, unintended connotation, consistent terminology, grammar, numbers and evidence. Separate imprecise wording from an unsupported claim; the latter needs product/source verification, not only an editorial rewrite.
3. **Substantive / Sarat makna:** Ask what each sentence helps the reader know, choose or do. Remove filler and false urgency, but preserve required conditions, caveats, steps and meaningful reasons to act.
4. **Authentic / Alami:** Reread as a person in the intended locale and situation. Check that the copy sounds human, fits the approved voice and is not a stiff translation or an inappropriate level of formality.

**Final reader check:** Is the primary action or result first? Can a first-time reader understand the terms, numbers and steps without a guess? Are source claims and interface states true? Do errors explain what happened and the next supported action without blame? Are controls, links, dates and consequences understandable without sight, color or local cultural assumptions? Fix concrete failures; don't invent a passing RASA score.

Apply RASA after checking factual claims and the relevant UI/domain contracts; a pleasant voice must never conceal uncertainty, status or risk. Review long and localized content with real readers when consequence or reach warrants it. Reuse `WRITING_QUALITY.md` for the broader source, logic, publication and reality checks.
