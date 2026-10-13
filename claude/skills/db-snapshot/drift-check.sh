#!/usr/bin/env bash
# Replay every migration into a throwaway DB and diff its schema against the
# main dev DB. Prints nothing between the markers when the two match.
# Run from the intent main checkout: bash ~/.claude/skills/db-snapshot/drift-check.sh [--keep]
set -euo pipefail

ROOT=$(git rev-parse --path-format=absolute --git-common-dir | sed 's/\/\.git$//')
cd "$ROOT"
export NODE_PATH="$ROOT/node_modules"
OUT=${DRIFT_OUT:-$(mktemp -d)}
CLEAN_DB=optura_verify_clean
PG_CONTAINER=${INTENT_PG_CONTAINER:-postgres}

read -r PG_USER DB_NAME CLEAN_URL < <(node -e '
require("dotenv").config({quiet:true});
const u=new URL(process.env.DATABASE_URL);const db=u.pathname.slice(1);
u.pathname="/'"$CLEAN_DB"'";console.log(u.username, db, u.toString())')

psql_admin() { docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres -v ON_ERROR_STOP=1 -qc "$1"; }

psql_admin "DROP DATABASE IF EXISTS $CLEAN_DB" 2>/dev/null
psql_admin "CREATE DATABASE $CLEAN_DB"
trap '[ "${1:-}" = "--keep" ] || psql_admin "DROP DATABASE IF EXISTS '"$CLEAN_DB"'"' EXIT

echo "▶ replaying migrations into $CLEAN_DB"
DATABASE_URL="$CLEAN_URL" node drizzle/scripts/migrate.mjs >"$OUT/replay.log" 2>&1 \
	|| { tail -20 "$OUT/replay.log"; exit 1; }
grep -q 'Post-migration verification passed' "$OUT/replay.log" \
	|| { echo "replay did not verify — see $OUT/replay.log"; exit 1; }

# graphile_worker / workflow* are created by the app at runtime, not by drizzle.
norm() { grep -v '^--\|^SET \|^SELECT pg_catalog\|^$\|^\\restrict\|^\\unrestrict' | sed 's/[[:space:]]*$//'; }
for db in "$DB_NAME" "$CLEAN_DB"; do
	docker exec "$PG_CONTAINER" pg_dump -U "$PG_USER" -s --no-owner --no-privileges \
		-N graphile_worker -N workflow -N workflow_drizzle "$db" | norm >"$OUT/$db.sql"
done

echo "▶ order-insensitive schema diff (< replay-only, > $DB_NAME-only)"
echo "--- begin ---"
node - "$OUT/$CLEAN_DB.sql" "$OUT/$DB_NAME.sql" <<'EOF'
const fs = require('fs');
const parse = (f) => {
	const out = new Set();
	for (let st of fs.readFileSync(f, 'utf8').split(/;\n/)) {
		st = st.trim();
		if (!st) continue;
		const m = st.match(/^CREATE TABLE (\S+) \(\n([\s\S]*)\n\)$/);
		if (m) {
			out.add(`TABLE ${m[1]}`);
			for (const l of m[2].split('\n')) out.add(`${m[1]} :: ${l.trim().replace(/,$/, '')}`);
			continue;
		}
		out.add(st.replace(/\s+/g, ' '));
	}
	return out;
};
const [a, b] = process.argv.slice(2).map(parse);
for (const x of a) if (!b.has(x)) console.log('<', x.slice(0, 240));
for (const x of b) if (!a.has(x)) console.log('>', x.slice(0, 240));
EOF
echo "--- end ---"
echo "dumps: $OUT"
