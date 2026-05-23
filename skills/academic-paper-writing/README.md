# Academic Paper Writing Skill

A comprehensive, modular skill system for writing top-venue academic papers (ECCV, CVPR, ICCV, NeurIPS, ICML).

## Structure

```
academic-paper-writing/
├── SKILL.md                              # Main entry point & overview
├── README.md                             # This file
└── modules/
    ├── style-guide.md                    # Shared style rules, banned words, GPT detection
    ├── introduction.md                   # §1 four-paragraph structure
    ├── preliminary-methodology.md        # §2-§3 funnel structure
    ├── experimental-results.md           # §4 insight-first writing
    ├── qa-guideline.md                   # 8-pass QA system
    └── qa-checklist.md                   # Quick-reference checklist
```

## Core Philosophy

1. **Insight-first**: Every sentence must carry information. Numbers support insights, not the other way around.
2. **Promise-delivery loop**: Every claim in the Introduction must land in Method and Experiments.
3. **Theory drives architecture**: Methods should emerge naturally from theoretical analysis.
4. **Elegant prose**: Top-venue quality English, free of GPT artifacts and template patterns.
5. **Specific over generic**: Concrete mechanisms over buzzwords, numbers over adjectives.

## Usage

- Read `SKILL.md` for overview and workflow
- Read `modules/style-guide.md` first (shared by all modules)
- Then read the module for the section you're writing
- Use `modules/qa-guideline.md` for full review, or `modules/qa-checklist.md` for quick checks

## Author

Prof. Chun-Yi Lee, NTU CSIE
