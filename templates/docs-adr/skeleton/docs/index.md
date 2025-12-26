# ${{ values.name }}

${{ values.description }}

## What are ADRs?

Architecture Decision Records (ADRs) are documents that capture important architectural decisions made along with their context and consequences. They serve as:

- **Historical record** of why decisions were made
- **Communication tool** for team alignment
- **Onboarding resource** for new team members
- **Reference** for future decision-making

## Quick Start

### Creating a New ADR

1. Copy the template from `templates/adr-template.md`
2. Create a new file: `docs/adrs/NNN-title.md`
3. Fill in the template sections
4. Submit a pull request for review

### ADR Numbering

ADRs are numbered sequentially: `001`, `002`, `003`, etc.

### ADR Status

| Status         | Description                |
| -------------- | -------------------------- |
| **Proposed**   | Under discussion           |
| **Accepted**   | Decision made and approved |
| **Deprecated** | No longer valid            |
| **Superseded** | Replaced by another ADR    |

## Current ADRs

| #                                   | Title                               | Status   | Date       |
| ----------------------------------- | ----------------------------------- | -------- | ---------- |
| [001](adrs/001-use-adrs.md)         | Use ADRs for Architecture Decisions | Accepted | 2024-01-01 |
| [002](adrs/002-example-decision.md) | Example Decision                    | Proposed | 2024-01-15 |

## Resources

- [ADR Process](process.md) - How we create and manage ADRs
- [Templates](templates.md) - ADR templates
- [Michael Nygard's ADR article](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
