#!/usr/bin/env python3
"""Prompt engineer hook - reformula prompts antes de que Claude Code los procese."""

import json
import sys
import requests

LITELLM_URL = "http://localhost:4000/v1/chat/completions"
CLASSIFIER_MODEL = "groq/llama-3.3-70b-versatile"

ENGINEERING_PROMPT = """You are a prompt engineer. Your job is to reformulate user prompts to be:
- Clear and specific (remove ambiguity)
- Well-structured (context → question → desired format)
- Concise (no filler)
- Actionable (Claude can execute it)

Read the user's prompt and rewrite it to be better. Keep the intent, improve clarity.
Return ONLY the rewritten prompt, nothing else. No markdown, no explanation."""

def engineer_prompt(prompt: str) -> str:
    """Call Groq to reformulate the prompt."""
    payload = {
        "model": CLASSIFIER_MODEL,
        "messages": [
            {"role": "system", "content": ENGINEERING_PROMPT},
            {"role": "user", "content": f"Original prompt:\n{prompt}"}
        ],
        "max_tokens": len(prompt) + 100,  # Allow some expansion
        "temperature": 0.3,  # Low temp for consistency
    }

    try:
        r = requests.post(LITELLM_URL, json=payload, headers={"Authorization": "Bearer test"}, timeout=10)
        if r.status_code == 200:
            response = r.json()
            rewritten = response.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
            return rewritten if rewritten else prompt
        else:
            # If engineering fails, return original
            return prompt
    except Exception:
        # If any error, return original prompt unchanged
        return prompt

def main():
    try:
        # Read input from Claude Code (stdin as JSON)
        input_data = json.load(sys.stdin)
        original_prompt = input_data.get("prompt", "")

        if not original_prompt:
            print(json.dumps({"prompt": ""}))
            return

        # Engineer the prompt
        engineered = engineer_prompt(original_prompt)

        # Output to Claude Code (stdout as JSON)
        print(json.dumps({"prompt": engineered}))
    except Exception:
        # On any error, return original prompt
        sys.stdout.write(json.dumps({"prompt": sys.stdin.read() if sys.stdin else ""}))

if __name__ == "__main__":
    main()
