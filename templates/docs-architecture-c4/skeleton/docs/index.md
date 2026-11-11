# ${{ values.systemName }} design

${{ values.description }}

| Document | Read it when |
| --- | --- |
| [High-level design](hld.md) | You need to know what the system is, who uses it, what it is made of and why |
{%- if values.includeLld %}
| [Low-level design](lld.md) | You are building or operating a part of it |
{%- endif %}

## Status

| | |
| --- | --- |
| Status | Draft |
| Owner | ${{ values.owner }} |
| Classification | ${{ values.classification }} |

Change the status to **Agreed** when the people named under
[Approval](hld.md#approval) have signed it off, and record what changed after
that under [Change history](hld.md#change-history).

## How the diagrams work

The diagrams follow the [C4 model](https://c4model.com): a context diagram
(who and what surrounds the system), a container diagram (its deployable
parts), and component diagrams (what one part is made of). The same colours
mean the same thing in every diagram:

| Shape | Meaning |
| --- | --- |
| Filled, with a head | A person |
| Filled | The system being designed |
| Grey | A system someone else runs |
| Outlined | A container or component of the system |
| Cylinder | A data store |
| Dashed box | A boundary: the system, a network, a region |
