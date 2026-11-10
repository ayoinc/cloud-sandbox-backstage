{%- if values.adrFormat == 'nygard' -%}
# ADR NNN: Title

Date: YYYY-MM-DD

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR XXX](XXX-title.md)

## Context

The issue motivating this decision, and any context that influences or constrains the decision.

## Decision

The change that we're proposing or have agreed to implement.

## Consequences

What becomes easier or more difficult to do and any risks introduced by the change.
{%- elif values.adrFormat == 'custom' -%}
# ADR NNN: Title

<!--
Starting point for your own ADR format. Add, rename or remove the "##"
sections to suit your organisation: scripts/validate-adrs.sh requires every
ADR to contain each "##" heading in this file, and needs "## Status" to
read the status.
-->

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR XXX](XXX-title.md)

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?
{%- else -%}
# ADR NNN: Title

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR XXX](XXX-title.md)

## Context

What is the issue that we're seeing that is motivating this decision or change?

Describe:

- The current situation
- The problem or opportunity
- Forces at play (technical, business, organizational)
- Constraints that limit options

## Decision

What is the change that we're proposing and/or doing?

Be specific and unambiguous. State the decision clearly so that someone reading this in the future understands exactly what was decided.

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- Benefit 1
- Benefit 2
- Benefit 3

### Negative

- Drawback 1
- Drawback 2
- Risk we accept

## Alternatives Considered

### Alternative 1: [Name]

Description of the alternative.

**Pros:**

- Advantage

**Cons:**

- Disadvantage
- Why not chosen

### Alternative 2: [Name]

Description of the alternative.

**Pros:**

- Advantage

**Cons:**

- Disadvantage
- Why not chosen

## References

- [Link to relevant documentation](https://example.com/)
- [Related ADR](NNN-title.md)
{%- endif %}
