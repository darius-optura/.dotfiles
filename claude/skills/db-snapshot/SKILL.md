---
name: db-snapshot
description: Refresh the intent worktree DB snapshot (scripts/worktree/.dev-snapshot.dump) from a clean main dev DB. Use when asked to "take a snapshot", "refresh the worktree snapshot", "clean up the dev DB", or when new worktrees apply many migrations on restore or db:migrate:verify reports extra/mismatched migrations.
---

# DB snapshot (intent)

`hw` restores new worktree DBs from `scripts/worktree/.dev-snapshot.dump`, then
applies newer migrations. A stale or dirty snapshot spreads drift to every
worktree. This skill makes main's dev DB match a fresh migration replay, then
dumps it.

Local-only: the scripts are in the global gitignore. Run everything from the
**main checkout**, never a worktree. The main `.env` points at the main dev DB
(`optura` in the `postgres` Docker container).

**Every DB write needs Darius's approval.** Show the diagnosis and the SQL first.
The only exceptions are `db:migrate:verbose` itself and the temp replay DB.

## 1. Preflight

```bash
cd "$(git rev-parse --path-format=absolute --git-common-dir | sed 's/\/\.git$//')"
git status -sb            # on main, up to date with origin/main
git pull --ff-only        # only if behind and the tree allows it
```

Take a backup before you change anything. Put it in the session scratchpad:

```bash
docker exec postgres pg_dump -U <user> -Fc --no-owner --no-privileges optura > <scratchpad>/optura-pre-snapshot.dump
```

## 2. Migrations

```bash
npm run db:migrate:verbose -- --verbose 2>&1 | grep -v '^🔍 SQL Query\|^📋\|^---$' | sed -n '/pre-migration/,$p'
```

The target is `✅ Post-migration verification passed!` with journal count equal
to DB count. Usual failures:

| Report | Cause | Fix (after approval) |
|---|---|---|
| Extra migration (applied, not in journal) | A branch migration was run on main's DB | Find the branch: grep `when` in each ref's `drizzle/meta/_journal.json`. Compare the hash. Undo its DDL, then `DELETE FROM _migrations WHERE id=…` |
| Hash mismatch | The file was edited after this DB applied it | `git log` the file. Make the DB match the current file's end state, then set `_migrations.hash` to the sha256 of the current file |
| Missing migration with an older `when` | drizzle skips anything older than the newest applied row | Apply that SQL by hand, then insert its `_migrations` row |

## 3. Schema drift vs fresh replay

```bash
bash ~/.claude/skills/db-snapshot/drift-check.sh
```

This replays every migration into `optura_verify_clean`. It diffs the schemas,
ignores column order and the runtime schemas (`graphile_worker`, `workflow*`),
then drops the temp DB (`--keep` keeps it). Clean means **nothing between
`--- begin ---` and `--- end ---`**.

When you read the diff:
- Tables or columns found only in main usually come from preview or closed
  branches. Check `git log --all -S'"<name>"' -- drizzle/` and
  `git merge-base --is-ancestor <sha> origin/main` before you call them leftovers.
- Do not drop on name alone. Some odd-looking tables are created by
  migrations (`mvbc_backup_*`, the `backup.*` schema, `checkpoint*`), and the
  replay shows them as `<`.
- Name-only differences (`*_fkey` vs `*_fk`, a PK under an old name, a unique
  index without its constraint) are legacy. To fix them: `RENAME CONSTRAINT`,
  `ALTER INDEX … RENAME`, `ADD CONSTRAINT x UNIQUE USING INDEX x`.
- A plain column where the replay has `GENERATED ALWAYS AS` means the app
  feature is broken (for example KB search on `analyst_kb_documents.search_tsv`).
  Fix it with drop index, drop column, re-add the generated column, recreate the index.

Put every fix in one `BEGIN; … COMMIT;` file. Apply it with
`docker exec -i postgres psql -U <user> -d optura -v ON_ERROR_STOP=1 -q < fix.sql`.
Run the drift check again until it is empty. Write scripts for `bash`: the
default shell here is zsh, and it does not word-split `$var`.

## 4. Snapshot

```bash
npm run db:migrate:verify -- --verbose | grep -E '📊|✅|❌'   # must pass
npx tsx scripts/worktree/db-snapshot.ts
ls -lh scripts/worktree/.dev-snapshot.dump
```

Report: migration counts, each fix applied, the drift result (empty), and the snapshot size and time.

## 5. Reload existing worktrees (optional)

`db-restore.ts` always force-reloads: it drops the worktree DB (killing
connections), restores the snapshot, then runs `db:migrate`. It refuses to run
in the main checkout. Data in the worktree DB is lost. Stop that worktree's
dev server first.

```bash
cd .claude/worktrees/<branch> && npx vite-node scripts/worktree/db-restore.ts
```

Auth failure → export `PGUSER`/`PGPASSWORD` from `.env` as `.herdr/setup.sh` does.
