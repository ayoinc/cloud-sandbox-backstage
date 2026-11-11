---
title: Writing content
description: How to add a post, mark a draft and preview your changes.
pubDate: 2026-01-22
---

Each post is a Markdown file in `src/content/posts/`. The name of the file
becomes the address of the post: `release-notes.md` is published at
`/posts/release-notes/`.

## Front matter

Every file starts with a block that describes the post:

```yaml
---
title: Release notes
description: What changed this month.
pubDate: 2026-02-01
draft: true
---
```

| Field         | Required | Purpose                                         |
| ------------- | -------- | ----------------------------------------------- |
| `title`       | Yes      | Heading of the post and its entry in lists      |
| `description` | Yes      | Summary in lists, search results and the feed   |
| `pubDate`     | Yes      | Publication date; posts are listed newest first |
| `updatedDate` | No       | Shown next to the publication date when set     |
| `draft`       | No       | Drafts are visible in development only          |

The build fails with a message naming the file and the field when a required
field is missing, so a broken post never reaches readers.

## Preview

Run `npm run dev` and open the address it prints. The page reloads when you
save a file.
