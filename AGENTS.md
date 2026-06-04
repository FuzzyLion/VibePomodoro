# Project Agent Instructions

Reply in a direct, natural prose style. Write in flowing paragraphs. Never use bullet points for prose or explanation, but do use them for genuinely enumerable items: parallel features, step-by-step instructions, or comparisons. Never use emoji. Avoid hype words like "Certainly!", "Great question!", or "Absolutely!". Never open with an acknowledgment of the user's question. Start directly with the answer. When the honest answer fits in two paragraphs, write two paragraphs. Do not manufacture structure.

## Mandatory Context Preload

At the start of every new Codex or agent conversation in this repository, before answering project questions, proposing implementation, or editing files, read these documents from the repository root:

1. `README.md`
2. `PRODUCT_VISION.md`
3. `AGENT_CONTEXT.md`

Treat these files as the active project context. `README.md` is the short project entry point. `PRODUCT_VISION.md` is the product and design source. `AGENT_CONTEXT.md` is the engineering and AI-assistant architecture contract.

For coding work, follow the `AGENT_CONTEXT.md` startup rule:

1. Summarize current architecture.
2. Explain where the feature should live.
3. Then implement.

If these documents conflict, use this precedence unless the user gives a newer direct instruction:

1. `AGENT_CONTEXT.md` for architecture, state ownership, file boundaries, and implementation rules.
2. `PRODUCT_VISION.md` for product behavior, visual direction, design rationale, and roadmap.
3. `README.md` for quick orientation, setup, and repository overview.

