# Conference Rebuttal Skill

A comprehensive, modular skill system for writing rebuttals (author responses) at top ML/CV venues.

## Structure

```
rebuttal/
├── SKILL.md                              # Main entry point & overview
├── README.md                             # This file
└── modules/
    ├── strategy.md                       # Review analysis, prioritization, response planning
    ├── response-writing.md               # Per-concern writing patterns, tone guide, templates
    ├── style-guide.md                    # Rebuttal-specific formatting and language rules
    └── checklist.md                      # Pre-submission verification checklist
```

## Core Principles

1. **Evidence > Argument**: Let data speak, not words.
2. **Low score first**: The lowest-scoring reviewer determines accept/reject.
3. **Acknowledge before counter**: Always validate the reviewer's observation first.
4. **Admit reasonable limitations**: Self-awareness is respected. Hard defense backfires.
5. **Cooperate, don't fight**: The goal is "concerns resolved," not "reviewer defeated."

## Supported Platforms

- **OpenReview** (ICML, NeurIPS, ICLR): No word limit, Markdown, images via anonymous links
- **CMT** (ECCV, CVPR, ICCV): 5000 char limit, plain text, no images

## Companion Skill

This skill inherits writing standards from `academic-paper-writing/modules/style-guide.md`. For paper-level writing guidance, see the `academic-paper-writing` skill.

## Author

Prof. Chun-Yi Lee, NTU CSIE
