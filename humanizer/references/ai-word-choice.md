# AI Word Choice

## Word replacements

| Weak            | Why it's weak                | Stronger alternatives                           |
| --------------- | ---------------------------- | ----------------------------------------------- |
| utilize         | pretentious "use"            | use                                             |
| leverage        | business jargon for "use"    | use, apply, build on                            |
| implement       | vague when used for "do"     | build, create, add, deploy                      |
| facilitate      | hides the action             | enable, help, run, lead                         |
| optimize        | vague without a metric       | speed up, reduce, tune, cut                     |
| impact (verb)   | vague direction              | affect, reduce, increase, change                |
| solution        | what kind?                   | tool, service, method, approach                 |
| robust          | means nothing specific       | resilient, thorough, tested                     |
| scalable        | to what?                     | handles 10K rps, grows with traffic             |
| seamless        | nothing is seamless          | smooth, uninterrupted, automatic                |
| innovative      | self-awarded praise          | new, first, novel (with evidence)               |
| best-in-class   | unverifiable                 | fastest, most accurate, top-rated (with source) |
| empower         | vague uplift                 | enable, give access to, train                   |
| streamline      | what specifically?           | automate, simplify, remove steps                |
| drive (results) | metaphor hiding mechanism    | cause, produce, lead to                         |
| stakeholder     | who specifically?            | customer, manager, engineer, board              |
| ecosystem       | often just "product suite"   | platform, tools, community                      |
| synergy         | meaningless in most contexts | cooperation, combined effect, integration       |

## GPT vocabulary by generation

**2023 — mid-2024 (GPT-4):** Additionally, boasts, bolstered, crucial, delve,
emphasizing, enduring, garner, intricate, interplay, key (adj.), landscape
(abstract), meticulous/meticulously, pivotal, underscore (verb), tapestry
(abstract), testament, valuable, vibrant

**Mid-2024 — mid-2025 (GPT-4o):** align with, bolstered, crucial, emphasizing,
enhance, enduring, fostering, highlighting, pivotal, showcasing, underscore,
vibrant

**Mid-2025+ (GPT-5):** emphasizing, enhance, highlighting, showcasing, plus
notability words (independent coverage, profiled in, active social media
presence)

**GPT words Claude largely avoids:** delve, robust, leverage, pivotal,
facilitate, tapestry (metaphorical), meticulous/meticulously

## Claude vocabulary

| Pattern | Why it's weak | Replace with |
| --- | --- | --- |
| nuanced / nuance | vague praise disguised as precision | name the specific complexity |
| I notice that... | narrates observation instead of stating it | state the observation directly |
| I should note that... | hedges before the point | state the point |
| It's worth noting that... | throat-clearing | cut — just state it |
| That said... | filler transition; masks absent logical turn | use "but" or "however" if the contrast is real; cut if it isn't |
| I'd be happy to | chatbot pleasantry | cut — just do the thing |
| To be clear... | pre-emptive clarification no one asked for | cut unless genuinely disambiguating |
| I want to be transparent | performative honesty | cut — just be honest |
| Let me... | narrates own process | cut — just do it |
| Based on my analysis | self-referential framing | cut — present the analysis directly |

**Claude structural patterns:**

- Em dash overuse (higher rate than GPT)
- Reflexive both-sides hedging (qualification after every assertion)
- Multi-clause sentences connected by dashes
- Meta-commentary about its own responses
- Less bullet-point formatting than GPT

**Words Claude's system prompt bans:** genuinely, honestly, straightforward

## Shared across model families

**Words:** crucial, key (adj.), landscape (abstract), enhance/enhancing,
testament, underscore, showcase/showcasing, vibrant, Additionally/Furthermore/
Moreover, complex and multifaceted, intricate interplay

**Constructions:** copula avoidance (serves as, stands as, represents → is),
negative parallelisms (not only...but also), significance inflation, rule of
three, synonym cycling

## Filler phrases

| Filler | Replace with |
| --- | --- |
| in order to | to |
| the reason why is that | because |
| the fact that he had arrived | his arrival |
| in spite of the fact that | although |
| call your attention to the fact that | remind you |
| I was unaware of the fact that | I did not know |
| the question as to whether | whether |
| there is no doubt but that | doubtless |
| he is a man who | he |
| this is a subject that | this subject |
| owing to the fact that | because |
| at this point in time | now |
| on a daily basis | daily |
| has the ability to | can |
| for the purpose of | to |
| it is important to note that | (cut) |
| at its core | (cut) |
| when all is said and done | (cut) |
| it goes without saying that | (cut) |
| needless to say | (cut) |

## Throat-clearing phrases

| Cut this | Keep this (if anything) |
| --- | --- |
| It should be noted that | (just state it) |
| It is interesting to note that | (just state it) |
| It goes without saying that | (just state it) |
| The thing is | (just state it) |
| What I'm trying to say is | (just say it) |
| At the end of the day | Ultimately |
| When all is said and done | (cut) |
| It is what it is | (cut) |
| In terms of | (rewrite the sentence) |
