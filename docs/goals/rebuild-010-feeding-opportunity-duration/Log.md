# Rebuild Goal 010: Feeding-Opportunity Duration Log

## 2026-07-31 - Design Approval And Formulation

Barry approved:

- an evidence-only duration screen;
- fixed routine activity while feeding opportunity changes;
- `24`, `16`, `12`, and `8 h d^-1` opportunity fixtures;
- equal evening and morning windows for restricted fixtures;
- fixed open-hour intake of `0.020 kg DM h^-1`; and
- a compact three-table, one-figure review pack.

Formulation began from:

```text
branch = main
HEAD = b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
origin/main = b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
live remote main = b0b05a1895b6e79ab5d1b1a3d75b4d4e19152f8d
worktree = clean
index = empty
Goal 009 review output = retained and ignored
```

Barry explicitly authorized Goal 009 publication, Goal 010 packet publication,
and immediate Goal 010 execution. Goal 010 implementation publication remains
a later explicit decision.

## 2026-07-31 - Independent Packet Review And Freeze

Independent scientific review required the packet to distinguish the exact
daily duration relation from within-day trajectories conditional on clock
placement. It also required `opportunity` to be operationalized explicitly as
a prescribed-intake window used fully at the fixed rate. The repaired packet
adds prescribed-intake/activity overlap fields, narrow Goal 008 comparison
claims, tolerance-based raw-output expectations, and explicit rejection of
literal continuous feeding.

Independent repository review required executable reconstruction of the
execution baseline and frozen hashes, exact packet and implementation path
sets, integer-safe test counts, exact ignored-output checks, and zsh-safe
single-tarball discovery.

The repaired packet received:

```text
scientific review = ACCEPT_REPAIR
repository/runbook review = ACCEPT_REPAIR
```

Frozen packet hashes:

```text
Goal.md SHA-256 = 62ee88126404eea426809f5755edb2e361a297e25f47c394464150278de82ca3
Plan.md SHA-256 = 789e2118124acd4b063790ac8408834da2a6f652e9d15b09e42db42ca6862482
Runbook.md SHA-256 = 847ca178d5d34e5ccf415165e3d4ba7de26ba80bc8f7b1424668899a19673710
```
