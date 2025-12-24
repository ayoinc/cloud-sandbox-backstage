# ADR Process

This document describes how we create, review, and maintain Architecture Decision Records.

## When to Create an ADR

Create an ADR when:

- Making a significant architectural decision
- Choosing between multiple technologies or approaches
- Establishing a new pattern or convention
- Changing an existing architectural decision
- Making a decision that affects multiple teams

## ADR Lifecycle

```d2
direction: right

proposed: Proposed {
  style.fill: "#fff9c4"
}

accepted: Accepted {
  style.fill: "#c8e6c9"
}

deprecated: Deprecated {
  style.fill: "#ffcdd2"
}

superseded: Superseded {
  style.fill: "#e1bee7"
}

proposed -> accepted
accepted -> deprecated
accepted -> superseded
```

### 1. Proposed

- Author creates ADR draft
- Opens pull request for review
- Team discusses in PR comments

### 2. Accepted

- Team reaches consensus
- PR is merged
- Decision is implemented

### 3. Deprecated

- Decision is no longer relevant
- Context has changed significantly
- Update status and add explanation

### 4. Superseded

- New ADR replaces this one
- Link to the superseding ADR
- Keep for historical context

## Creating an ADR

### Step 1: Start from Template

```bash
cp docs/templates/adr-template.md docs/adrs/NNN-title.md
```

### Step 2: Fill in Sections

1. **Title**: Short, descriptive title
2. **Status**: Start with "Proposed"
3. **Context**: Describe the situation
4. **Decision**: State the decision clearly
5. **Consequences**: List positive and negative outcomes

### Step 3: Submit for Review

```bash
git checkout -b adr/NNN-title
git add docs/adrs/NNN-title.md
git commit -m "ADR NNN: Title"
git push -u origin adr/NNN-title
# Create pull request
```

### Step 4: Review Process

- Minimum 2 reviewers for architectural decisions
- Allow 3-5 business days for review
- Address feedback and iterate

## Best Practices

### DO

- Keep ADRs concise (1-2 pages)
- Focus on the "why" not just the "what"
- Include alternatives considered
- Link to related ADRs
- Update status when things change

### DON'T

- Use ADRs for trivial decisions
- Include implementation details
- Leave ADRs in "Proposed" indefinitely
- Delete or modify accepted ADRs (create new ones instead)

## Review Criteria

Reviewers should consider:

- [ ] Is the context clearly explained?
- [ ] Is the decision stated unambiguously?
- [ ] Were alternatives considered?
- [ ] Are consequences realistic?
- [ ] Does it align with architectural principles?
