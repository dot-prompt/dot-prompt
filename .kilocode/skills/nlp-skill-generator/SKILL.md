---
name: nlp-skill-generator
description: Creates new NLP skill folders with page.md, learn.md, exercise.md, and scoring.md files. This skill should be used when user wants to create a new NLP skill with the complete folder structure for the Teacher Mode system.
---

# NLP Skill Generator

This skill generates complete NLP skill folders with all four required files: page.md (content), learn.md (teaching), exercise.md (practice), and scoring.md (how to score).

## When to Use

Use this skill when the user asks to:
- "Create a new skill"
- "Add a skill for X"
- "Generate the folder structure for a skill"
- "Create page.md, learn.md, exercise.md, and scoring.md for X"

## Folder Structure

Each skill requires a folder at `nlp_trainer/priv/prompts/skills/{slug}/` containing:

```
{slug}/
├── page.md      # Original content for scoring engine & practice (default)
├── learn.md     # Teacher Mode teaching content with sections
├── exercise.md  # Practice exercises for the skill
└── scoring.md   # How to score user responses for this skill
```

## Required Information

If the user provides insufficient information, ask questions before generating:

1. **Required** - Skill slug (e.g., "cause_effect", "embedded_commands")
2. **Required** - Skill name (e.g., "Cause Effect", "Embedded Commands")
3. **Required** - Skill definition (what is this skill?)
4. **Required** - Category (pacing_leading, ambiguity, deletions, distortions, suggestion, general)
5. **Required** - Difficulty (beginner, intermediate, advanced)
6. **Optional** - Key examples of the skill in use
7. **Optional** - Common mistakes to avoid

## File Templates

### page.md Template

```markdown
---
slug: {slug}
name: {name}
category: {category}
difficulty: {difficulty}
definition: "{definition}"
---

# {name}

## Definition
[What the skill is]

## Core Effect on Listener
[Psychological effect on the listener]

## When to Introduce
[When to use this skill]

## How It Should Sound
[Delivery instructions]

## Common Mistakes
1. Mistake 1
2. Mistake 2

## Two Micro-Examples
1. Example 1
2. Example 2

## Template Variations
### Variation 1
[Template text]

## Scoring Guidance
- **High Score (80-100)**: Excellent usage
- **Medium Score (40-79)**: Partial usage
- **Low Score (1-39)**: No usage
- **What to Listen For**: Keywords or patterns
- **Watch Out For**: Common mistakes
```

### learn.md Template

```markdown
---
slug: {slug}
name: {name}
sections_until_practice: 2
---

# Section 1: Skill Overview

## Core Content
{Definition and overview of the skill}

## Key Points
- Point 1
- Point 2
- Point 3

## Example
"Example sentence using the skill."

## Comprehension Question
What is the key characteristic of this skill?

## Follow-up Guidance
If they struggle, explain: [Hint]

---

# Section 2: Psychological Mechanism

## Core Content
[How it affects the listener psychologically]

## Key Points
- Point 1
- Point 2

## Example
"Another example sentence."

## Comprehension Question
[Question about this section]

## Follow-up Guidance
[Hint for struggling students]

---

# Section 3: Practical Applications

## Core Content
[Real-world applications]

## Key Points
- Therapy: [example]
- Sales: [example]
- Leadership: [example]

## Example
"Practical example."
```

### exercise.md Template

```markdown
---
slug: {slug}
name: {name}
---

# {name} - Practice Exercises

## Exercise 1: Recognition

**Instructions**: Identify the {skill} pattern in the following sentences.

1. "Example sentence 1"
2. "Example sentence 2"

**Answers**: 
1. [Answer]
2. [Answer]

---

## Exercise 2: Construction

**Instructions**: Create 3 sentences using the {skill} pattern.

1. 
2. 
3. 

---

## Exercise 3: Application

**Instructions**: Use {skill} in a conversation about [topic].

Write your sentences:

1. 
2. 

---

## Exercise 4: Feedback

**Instructions**: Record yourself using the {skill} pattern. Evaluate:
- Naturalness (1-10)
- Clarity (1-10)
- Overall effectiveness (1-10)

Notes for improvement:
```

### scoring.md Template

```markdown
---
slug: {slug}
name: {name}
---

# {name} - Scoring Guide

## Overview
[How to score this skill - brief description]

## Scoring Rubric

### High Score (80-100): Excellent Usage
- Natural, effortless delivery
- Clear demonstration of the skill
- Appropriate context and timing
- Listener responds positively

**Indicators**:
- Keyword/pattern is present
- Delivery feels conversational
- Effect on listener is evident

### Medium Score (40-79): Partial Usage
- Attempt made but incomplete or awkward
- Some elements present but not fully developed
- Delivery feels forced or unnatural

**Indicators**:
- Partial keyword/pattern present
- Delivery is somewhat mechanical
- Effect on listener is unclear

### Low Score (1-39): No Usage
- Skill not demonstrated
- Incorrect usage
- Completely off-topic

**Indicators**:
- No keyword/pattern present
- Wrong skill used
- No discernible effect

## What to Listen For

- [Specific keyword 1]
- [Specific keyword 2]
- [Pattern or structure]

## Watch Out For

- [Common mistake 1] - Reduces score
- [Common mistake 2] - Reduces score
- [Overuse of the skill] - Can sound manipulative

## Example Assessments

### Example Response 1: "Because you're listening, you feel relaxed."
**Score**: 90
**Reasoning**: Clear cause-effect pattern, natural delivery, creates desired effect

### Example Response 2: "You should feel relaxed because I said so."
**Score**: 30
**Reasoning**: Direct command instead of cause-effect, feels forced

### Example Response 3: "Nice weather today."
**Score**: 5
**Reasoning**: No attempt to use the skill
```

## Generation Process

1. **Gather Information**: Ask user for required fields if not provided
2. **Create Folder**: Create `nlp_trainer/priv/prompts/skills/{slug}/` directory
3. **Generate page.md**: Create with skill content
4. **Generate learn.md**: Create with teaching sections (2-4 sections)
5. **Generate exercise.md**: Create with practice exercises
6. **Generate scoring.md**: Create with scoring rubric and examples
7. **Confirm**: Tell user the files were created

## Asking for Missing Information

If user says "create skill for X" without details, ask:

- "What is the skill's unique identifier (slug)? For example: 'cause_effect'"
- "What is the human-readable name?"
- "In one sentence, what is this skill?"
- "Which category does it belong to?"
- "What difficulty level?"

Example responses:
- "Slug: nominalizations, Name: Nominalizations, Definition: Converting verbs to nouns, Category: deletions, Difficulty: intermediate"

## Example Usage

User: "Create a new skill for mirror neurons"
→ Create folder: nlp_trainer/priv/prompts/skills/mirror_neurons/
→ Create page.md, learn.md, exercise.md, and scoring.md with appropriate content
