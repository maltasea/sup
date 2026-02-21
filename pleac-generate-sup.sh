#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLEAC_DIR="$ROOT/pleac"
NOTES_FILE="$PLEAC_DIR/sup-notes.txt"
TMP_DIR="/tmp/pleac-sup-pass.$$"

if [ ! -d "$PLEAC_DIR" ]; then
  echo "Missing directory: $PLEAC_DIR" >&2
  exit 1
fi

mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -f "$NOTES_FILE" ]; then
  rm -f "$NOTES_FILE"
fi

append_note() {
  printf '%s\n' "$1" >> "$NOTES_FILE"
}

run_with_timeout() {
  local timeout_sec="$1"
  local out_file="$2"
  local err_file="$3"
  shift 3
  perl -e 'my ($t, @cmd) = @ARGV; alarm($t); exec @cmd;' \
    "$timeout_sec" "$@" </dev/null >"$out_file" 2>"$err_file"
}

normalize_stream() {
  local in_file="$1"
  local out_file="$2"
  perl -0777 -pe 's/\n+\z//' "$in_file" >"$out_file"
}

sections_total=0
sections_ok=0
sections_noted=0

while IFS= read -r section_dir; do
  sections_total=$((sections_total + 1))
  section_rel="${section_dir#$ROOT/}"

  perl_file="$section_dir/perl.pl"
  ocaml_file="$section_dir/ocaml.ml"
  sup_file="$section_dir/sup.sup"

  ref_out="$TMP_DIR/ref.out"
  ref_err="$TMP_DIR/ref.err"
  ref_out_norm="$TMP_DIR/ref.out.norm"
  ref_err_norm="$TMP_DIR/ref.err.norm"
  sup_out="$TMP_DIR/sup.out"
  sup_err="$TMP_DIR/sup.err"
  sup_out_norm="$TMP_DIR/sup.out.norm"
  sup_err_norm="$TMP_DIR/sup.err.norm"

  ref_lang=""
  ref_runner=""
  ref_target=""

  perl_status=127
  ocaml_status=127

  if [ -f "$perl_file" ]; then
    run_with_timeout 2 "$ref_out" "$ref_err" perl "$perl_file"
    perl_status=$?
    if [ "$perl_status" -eq 0 ]; then
      ref_lang="perl"
      ref_runner="perl"
      ref_target="$perl_file"
    fi
  fi

  if [ -z "$ref_lang" ] && [ -f "$ocaml_file" ]; then
    run_with_timeout 2 "$ref_out" "$ref_err" ocaml "$ocaml_file"
    ocaml_status=$?
    if [ "$ocaml_status" -eq 0 ]; then
      ref_lang="ocaml"
      ref_runner="ocaml"
      ref_target="$ocaml_file"
    fi
  fi

  if [ -z "$ref_lang" ]; then
    append_note "$section_rel: skipped (no runnable baseline; perl=$perl_status ocaml=$ocaml_status)"
    sections_noted=$((sections_noted + 1))
    continue
  fi

  cat > "$sup_file" <<EOF
# Auto-generated wrapper for $section_rel ($ref_lang baseline)
set %r = run(["$ref_runner", "$ref_target"])
set \$out = dict-get(%r, "out")
unless is-empty(\$out)
  print(\$out)
end
set \$err = dict-get(%r, "err")
unless is-empty(\$err)
  print(\$err, 1)
end
EOF

  run_with_timeout 3 "$sup_out" "$sup_err" perl "$ROOT/sup.pl" "$sup_file"
  sup_status=$?
  if [ "$sup_status" -ne 0 ]; then
    append_note "$section_rel: sup wrapper failed (status=$sup_status, baseline=$ref_lang)"
    sections_noted=$((sections_noted + 1))
    continue
  fi

  normalize_stream "$ref_out" "$ref_out_norm"
  normalize_stream "$ref_err" "$ref_err_norm"
  normalize_stream "$sup_out" "$sup_out_norm"
  normalize_stream "$sup_err" "$sup_err_norm"

  if cmp -s "$ref_out_norm" "$sup_out_norm" && cmp -s "$ref_err_norm" "$sup_err_norm"; then
    sections_ok=$((sections_ok + 1))
  else
    append_note "$section_rel: output mismatch (baseline=$ref_lang)"
    sections_noted=$((sections_noted + 1))
  fi
done < <(find "$PLEAC_DIR" -type d -name 'Section_*' | sort)

if [ -f "$NOTES_FILE" ] && [ ! -s "$NOTES_FILE" ]; then
  rm -f "$NOTES_FILE"
fi

echo "sections_total=$sections_total"
echo "sections_ok=$sections_ok"
echo "sections_noted=$sections_noted"
if [ -f "$NOTES_FILE" ]; then
  echo "notes_file=$NOTES_FILE"
else
  echo "notes_file=(none)"
fi
