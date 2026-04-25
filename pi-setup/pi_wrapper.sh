#!/usr/bin/env bash
# Pi wrapper: adds prompt engineering before launching pi

# If no arguments or --help, just launch pi directly (interactive mode)
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  exec ~/bin/pi "$@"
fi

# For single-shot prompts, engineer them first
if [ $# -ge 1 ] && [ "${1:0:1}" != "-" ]; then
  # Combine all arguments as the prompt
  prompt="$*"

  # Pipe through prompt engineer
  engineered=$(echo "{\"prompt\": $(printf '%s\n' "$prompt" | jq -Rs .)}" | python3 ~/orchestrator/prompt_engineer.py 2>/dev/null | jq -r '.prompt // empty')

  # If engineering failed, use original
  if [ -z "$engineered" ]; then
    engineered="$prompt"
  fi

  # Launch pi with engineered prompt
  exec ~/bin/pi "$engineered"
fi

# For flag arguments, pass through unchanged
exec ~/bin/pi "$@"
