# Signs of AI Writing

Based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing),
maintained by WikiProject AI Cleanup (2025 revision). 28 patterns across
content, language, style, communication, and filler categories.

## Content Patterns

### 1. Significance inflation

**Words to watch:** stands/serves as, is a testament/reminder, a
vital/significant/crucial/pivotal/key role/moment, underscores/highlights its
importance/significance, reflects broader, symbolizing its
ongoing/enduring/lasting, contributing to the, setting the stage for,
marking/shaping the, represents/marks a shift, key turning point, evolving
landscape, focal point, indelible mark, deeply rooted

LLMs inflate importance by adding statements about how aspects represent or
contribute to broader topics. They regress toward statistical means: replacing
specific facts with exaggerated, common descriptions.

**Before:**
> The Statistical Institute of Catalonia was officially established in 1989,
> marking a pivotal moment in the evolution of regional statistics in Spain.

**After:**
> The Statistical Institute of Catalonia was established in 1989 to collect and
> publish regional statistics independently from Spain's national statistics
> office.

### 2. Notability name-dropping

**Words to watch:** independent coverage, local/regional/national media outlets,
profiled in, written by a leading expert, active social media presence

LLMs prove importance by listing sources rather than summarizing their content.
They over-emphasize trivial coverage and name media outlets without explaining
relevance. Newer models (2025+) do this most aggressively.

**Before:**
> Her views have been cited in The New York Times, BBC, Financial Times, and
> The Hindu. She maintains an active social media presence with over 500,000
> followers.

**After:**
> In a 2024 New York Times interview, she argued that AI regulation should
> focus on outcomes rather than methods.

### 3. Superficial -ing analyses

**Words to watch:** highlighting/underscoring/emphasizing..., ensuring...,
reflecting/symbolizing..., contributing to..., cultivating/fostering...,
encompassing..., showcasing..., valuable insights, align/resonate with

LLMs tack present participle ("-ing") phrases onto sentences to add fake depth.
Often constitutes unattributed synthesis. Retrieval-augmented models attach
these analyses to sources regardless of what the source actually says.

**Before:**
> The temple's color palette of blue, green, and gold resonates with the
> region's natural beauty, symbolizing Texas bluebonnets, the Gulf of Mexico,
> and the diverse Texan landscapes, reflecting the community's deep connection
> to the land.

**After:**
> The temple uses blue, green, and gold colors. The architect said these were
> chosen to reference local bluebonnets and the Gulf coast.

### 4. Promotional language

**Words to watch:** boasts a, vibrant, rich (figurative), profound, enhancing
its, showcasing, exemplifies, commitment to, natural beauty, nestled, in the
heart of, groundbreaking (figurative), renowned, breathtaking, must-visit,
stunning, featuring, diverse array

LLMs cannot maintain neutral tone despite prompting. Output tends toward travel
guides or advertisements.

**Subtype A — Cultural heritage framing:** "Nestled within the breathtaking
region..." "a vibrant town with a rich cultural heritage..."

**Subtype B — Corporate/press release tone:** "CEO emphasized the company's
commitment to sustainability, customer focus, and prosperity through responsible
corporate practices."

**Before:**
> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya
> Kobo stands as a vibrant town with a rich cultural heritage and stunning
> natural beauty.

**After:**
> Alamata Raya Kobo is a town in the Gonder region of Ethiopia, known for its
> weekly market and 18th-century church.

### 5. Vague attributions

**Words to watch:** Industry reports, Observers have cited, Experts argue, Some
critics argue, several sources/publications (when few cited), "such as" before
exhaustive lists

LLMs attribute opinions to vague authorities without specific sources. They
exaggerate source quantity and imply lists are non-exhaustive when sources
suggest otherwise.

**Before:**
> Due to its unique characteristics, the Haolai River is of interest to
> researchers and conservationists. Experts believe it plays a crucial role in
> the regional ecosystem.

**After:**
> The Haolai River supports several endemic fish species, according to a 2019
> survey by the Chinese Academy of Sciences.

### 6. False attribution to sources

LLMs attach superficial analyses to cited sources regardless of what those
sources actually say. The source may contain data or facts, but the LLM adds
its own interpretive framing and attributes it to the source.

**Before:**
> According to Smith (2023), the policy represents a paradigm shift in how
> governments approach regulation, underscoring the growing importance of
> adaptive governance.

**After:**
> Smith (2023) documented three changes the policy introduced: mandatory
> disclosure, annual audits, and public comment periods.

### 7. Formulaic "challenges and future prospects"

**Words to watch:** Despite its... faces several challenges..., Despite these
challenges, Challenges and Legacy, Future Outlook

Rigid formula: "Despite its [positive words], [subject] faces challenges..."
ending with vague positivity or speculation. The sign is the rigid formula,
not mere mention of challenges.

**Before:**
> Despite its industrial prosperity, Korattur faces challenges typical of urban
> areas, including traffic congestion and water scarcity. Despite these
> challenges, with its strategic location and ongoing initiatives, Korattur
> continues to thrive as an integral part of Chennai's growth.

**After:**
> Traffic congestion increased after 2015 when three new IT parks opened. The
> municipal corporation began a stormwater drainage project in 2022 to address
> recurring floods.

## Language and Grammar Patterns

### 8. AI vocabulary words

See `references/ai-word-choice.md` for the full word list and model-generation
timeline.

### 9. Copula avoidance

**Words to watch:** serves as/stands as/marks/represents [a],
boasts/features/offers [a]

LLMs substitute elaborate constructions for simple "is," "are," and "has."

**Before:**
> Gallery 825 serves as LAAA's exhibition space for contemporary art. The
> gallery features four separate spaces and boasts over 3,000 square feet.

**After:**
> Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has
> four rooms totaling 3,000 square feet.

### 10. Negative parallelisms

LLMs overuse "Not only...but..." and "It's not just about..., it's..."
constructions to appear balanced and thoughtful.

**Subtype A — "Not just X, but also Y":** Establishes false balance.
**Subtype B — "Not X, but Y":** Explicitly denies first characteristic.

**Before:**
> It's not just about the beat riding under the vocals; it's part of the
> aggression and atmosphere. It's not merely a song, it's a statement.

**After:**
> The heavy beat adds to the aggressive tone.

### 11. Rule of three overuse

LLMs force ideas into groups of three to appear comprehensive.

**Before:**
> The event features keynote sessions, panel discussions, and networking
> opportunities. Attendees can expect innovation, inspiration, and industry
> insights.

**After:**
> The event includes talks and panels. There's also time for informal
> networking between sessions.

### 12. Synonym cycling (elegant variation)

LLMs have repetition-penalty mechanisms that cause excessive synonym
substitution. The same entity gets referred to by a rotating cast of
near-synonyms.

**Before:**
> The protagonist faces many challenges. The main character must overcome
> obstacles. The central figure eventually triumphs. The hero returns home.

**After:**
> The protagonist faces many challenges but eventually triumphs and returns
> home.

### 13. False ranges

LLMs use "from X to Y" constructions where X and Y aren't on a meaningful
scale.

**Before:**
> Our journey through the universe has taken us from the singularity of the Big
> Bang to the grand cosmic web, from the birth and death of stars to the
> enigmatic dance of dark matter.

**After:**
> The book covers the Big Bang, star formation, and current theories about dark
> matter.

## Style Patterns

### 14. Em dash overuse

LLMs use em dashes more than humans, mimicking "punchy" sales writing.

**Before:**
> The term is primarily promoted by Dutch institutions—not by the people
> themselves. You don't say "Netherlands, Europe" as an address—yet this
> mislabeling continues—even in official documents.

**After:**
> The term is primarily promoted by Dutch institutions, not by the people
> themselves. You don't say "Netherlands, Europe" as an address, yet this
> mislabeling continues in official documents.

### 15. Boldface overuse

LLMs emphasize phrases in boldface mechanically. They bold every instance of a
chosen phrase in a "key takeaways" fashion.

**Before:**
> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance
> Indicators)**, and visual strategy tools such as the **Business Model Canvas
> (BMC)** and **Balanced Scorecard (BSC)**.

**After:**
> It blends OKRs, KPIs, and visual strategy tools like the Business Model
> Canvas and Balanced Scorecard.

### 16. Inline-header vertical lists

LLMs produce lists where items start with bolded headers followed by colons.

**Before:**
> - **User Experience:** The user experience has been significantly improved.
> - **Performance:** Performance has been enhanced through optimized algorithms.
> - **Security:** Security has been strengthened with end-to-end encryption.

**After:**
> The update improves the interface, speeds up load times through optimized
> algorithms, and adds end-to-end encryption.

### 17. Title case in headings

LLMs capitalize all main words in headings.

**Before:**
> ## Strategic Negotiations And Global Partnerships

**After:**
> ## Strategic negotiations and global partnerships

### 18. Emoji decoration

LLMs decorate headings or bullet points with emojis.

**Before:**
> 🚀 **Launch Phase:** The product launches in Q3
> 💡 **Key Insight:** Users prefer simplicity

**After:**
> The product launches in Q3. User research showed a preference for simplicity.

### 19. Curly quotation marks

ChatGPT uses curly quotes instead of straight quotes.

### 20. Sudden style shifts

Text abruptly changes tone, vocabulary, or perspective mid-document. This
signals multiple AI generations pasted together, or an AI edit applied to
part of a human-written document.

### 21. Markdown in non-markdown contexts

LLMs produce markdown formatting in contexts where it won't render: plain-text
emails, wiki markup, rich-text editors, chat messages.

### 22. Generic headings

LLMs default to formulaic section headings that name the section type rather
than its content.

| Generic heading | Replace with |
| --- | --- |
| Introduction | State the thesis or problem directly |
| Conclusion | Name the specific takeaway |
| Summary | Name what's being summarized |
| Overview | Name what's being overviewed |
| Background | Name the context being set |
| Key Takeaways | State the actual takeaways |
| Final Thoughts | Make a final argument |
| In Closing | Close with substance |

Every heading should answer: "What specifically does this section cover?"
If the heading could apply to any article on any topic, it's generic.

## Communication Patterns

### 23. Collaborative communication artifacts

**Words to watch:** I hope this helps, Of course!, Certainly!, You're
absolutely right!, Would you like..., let me know, here is a...

Text meant as chatbot conversation gets pasted as content.

**Before:**
> Here is an overview of the French Revolution. I hope this helps! Let me know
> if you'd like me to expand on any section.

**After:**
> The French Revolution began in 1789 when financial crisis and food shortages
> led to widespread unrest.

### 24. Knowledge-cutoff disclaimers

**Words to watch:** as of [date], Up to my last training update, While specific
details are limited/scarce..., based on available information...

**Before:**
> While specific details about the company's founding are not extensively
> documented in readily available sources, it appears to have been established
> sometime in the 1990s.

**After:**
> The company was founded in 1994, according to its registration documents.

### 25. Sycophantic tone

Overly positive, people-pleasing language.

**Before:**
> Great question! You're absolutely right that this is a complex topic.

**After:**
> The economic factors you mentioned are relevant here.

### 26. Placeholder text

LLMs leave placeholder markers that get published: [INSERT BRAND NAME],
[COMPANY], [STATISTIC], [Link: ...], [Image: ...].

## Filler and Hedging

### 27. Filler phrases

| Filler | Replace with |
| --- | --- |
| In order to achieve this goal | To achieve this |
| Due to the fact that | Because |
| At this point in time | Now |
| In the event that you need help | If you need help |
| The system has the ability to process | The system can process |
| It is important to note that the data shows | The data shows |
| At its core | (cut entirely) |
| When all is said and done | (cut entirely) |

### 28. Excessive hedging

Over-qualifying statements to avoid commitment.

**Before:**
> It could potentially possibly be argued that the policy might have some
> effect on outcomes.

**After:**
> The policy may affect outcomes.

### 29. Generic positive conclusions

Vague upbeat endings.

**Before:**
> The future looks bright for the company. Exciting times lie ahead as they
> continue their journey toward excellence.

**After:**
> The company plans to open two more locations next year.

## Full Example

**Before (AI-sounding):**
> Great question! Here is an essay on this topic. I hope this helps!
>
> AI-assisted coding serves as an enduring testament to the transformative
> potential of large language models, marking a pivotal moment in the evolution
> of software development. In today's rapidly evolving technological landscape,
> these groundbreaking tools—nestled at the intersection of research and
> practice—are reshaping how engineers ideate, iterate, and deliver,
> underscoring their vital role in modern workflows.
>
> At its core, the value proposition is clear: streamlining processes, enhancing
> collaboration, and fostering alignment. It's not just about autocomplete; it's
> about unlocking creativity at scale, ensuring that organizations can remain
> agile while delivering seamless, intuitive, and powerful experiences to users.
>
> - 💡 **Speed:** Code generation is significantly faster.
> - 🚀 **Quality:** Output quality has been enhanced.
> - ✅ **Adoption:** Usage continues to grow, reflecting broader industry trends.
>
> In conclusion, the future looks bright. Exciting times lie ahead as we
> continue this journey toward excellence. Let me know if you'd like me to
> expand on any section!

**After (humanized):**
> AI coding assistants speed up some tasks. In a 2024 study by Google,
> developers using Codex completed simple functions 55% faster than a control
> group, but showed no improvement on debugging or architectural decisions.
>
> The tools are good at boilerplate: config files, test scaffolding, repetitive
> refactors. They are bad at knowing when they are wrong. I have mass-accepted
> suggestions that compiled, passed lint, and still did the wrong thing because
> I stopped paying attention.
>
> The productivity claims are hard to verify. GitHub says Copilot users "accept
> 30% of suggestions," but acceptance is not correctness, and correctness is not
> value.
>
> None of this means the tools are useless. It means they are tools.
