#!/usr/bin/env bash
# Claude Code status line
# Displays: context %, token usage, model, agent (if any), task count

input=$(cat)

# --- context % ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx_str=$(printf "%.0f%% ctx" "$used_pct")
else
  ctx_str="-- ctx"
fi

# --- token usage (cumulative input + output, formatted) ---
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_tokens=$(( total_in + total_out ))
if [ "$total_tokens" -ge 1000000 ]; then
  tok_str=$(awk "BEGIN { printf \"%.1fM tok\", $total_tokens/1000000 }")
elif [ "$total_tokens" -ge 1000 ]; then
  tok_str=$(awk "BEGIN { printf \"%.1fK tok\", $total_tokens/1000 }")
else
  tok_str="${total_tokens} tok"
fi

# --- model ---
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')

# --- agent (only when present) ---
agent_name=$(echo "$input" | jq -r '.agent.name // empty')

# --- active tasks: count agent + worktree presence as indicators ---
# We don't have an explicit task list in the schema, so we show session name
# if set, as a proxy for "named work unit"; otherwise omit task count.
session_name=$(echo "$input" | jq -r '.session_name // empty')

# --- assemble parts ---
parts=()
parts+=("$ctx_str")
parts+=("$tok_str")
parts+=("$model_name")
[ -n "$agent_name" ] && parts+=("agent:$agent_name")
[ -n "$session_name" ] && parts+=("[$session_name]")

# Join with  |  separator
printf '%s' "${parts[0]}"
for p in "${parts[@]:1}"; do
  printf ' | %s' "$p"
done
printf '\n'
