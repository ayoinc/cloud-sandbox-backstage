# ADR Templates

This page provides templates for creating Architecture Decision Records.

## MADR Template (Recommended)

We use the Markdown Architectural Decision Records (MADR) format.

```markdown
# ADR NNN: Title

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR XXX](XXX-title.md)

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- Benefit 1
- Benefit 2

### Negative

- Drawback 1
- Drawback 2

## Alternatives Considered

### Alternative 1: Name

Description of the alternative.

**Pros:**
- Pro 1

**Cons:**
- Con 1

### Alternative 2: Name

Description of the alternative.

**Pros:**
- Pro 1

**Cons:**
- Con 1

## References

- [Link to relevant documentation]()
- [Related ADR](NNN-title.md)
```

## Nygard Template

The original ADR format by Michael Nygard:

```markdown
# ADR NNN: Title

Date: YYYY-MM-DD

## Status

Proposed | Accepted | Deprecated | Superseded

## Context

The issue motivating this decision, and any context that influences or constrains the decision.

## Decision

The change that we're proposing or have agreed to implement.

## Consequences

What becomes easier or more difficult to do and any risks introduced by the change.
```

## Extended Template

For complex decisions requiring more detail:

```markdown
# ADR NNN: Title

## Metadata

| Field | Value |
|-------|-------|
| Status | Proposed |
| Date | YYYY-MM-DD |
| Author | @username |
| Reviewers | @reviewer1, @reviewer2 |
| Category | architecture / security / infrastructure |

## Summary

One paragraph summary of the decision.

## Context

### Background

Detailed background information.

### Problem Statement

The specific problem we're trying to solve.

### Requirements

- Requirement 1
- Requirement 2

### Constraints

- Constraint 1
- Constraint 2

## Decision

### Chosen Option

The decision and why it was chosen.

### Implementation Notes

High-level implementation guidance.

## Alternatives Considered

### Option 1: Name

...

### Option 2: Name

...

## Consequences

### Positive

- ...

### Negative

- ...

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Risk 1 | Low | High | Mitigation strategy |

## Action Items

- [ ] Action 1
- [ ] Action 2

## References

- [Reference 1]()
```

## Usage Tips

1. **Start simple**: Use the MADR template for most decisions
2. **Add detail when needed**: Use the extended template for complex decisions
3. **Be consistent**: Use the same template across your organization
4. **Focus on clarity**: The template is a guide, not a constraint
