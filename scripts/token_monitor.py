#!/usr/bin/env python3
"""Token usage monitoring for free agent orchestrator."""

import json
import os
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict
from dataclasses import dataclass
import sys

LITELLM_LOG = Path.home() / "litellm" / "requests.log"
MONITOR_DIR = Path.home() / "orchestrator" / ".monitor"

@dataclass
class TokenUsage:
    model: str
    input_tokens: int
    output_tokens: int
    total_tokens: int
    timestamp: str
    status: str

class TokenMonitor:
    def __init__(self, log_path: Path = LITELLM_LOG):
        self.log_path = log_path
        self.monitor_dir = MONITOR_DIR
        self.monitor_dir.mkdir(exist_ok=True)
        self.cache_file = self.monitor_dir / "usage_cache.json"
        self.loaded_cache = self._load_cache()

    def _load_cache(self) -> dict:
        if self.cache_file.exists():
            try:
                return json.loads(self.cache_file.read_text())
            except:
                return {}
        return {}

    def _save_cache(self, data: dict):
        self.cache_file.write_text(json.dumps(data, indent=2))

    def parse_requests_log(self) -> list[TokenUsage]:
        """Parse litellm requests.log and extract token usage."""
        if not self.log_path.exists():
            return []

        usages = []
        cache = self.loaded_cache.copy()

        try:
            with open(self.log_path) as f:
                for line in f:
                    try:
                        entry = json.loads(line.strip())
                        if "completion_tokens" not in entry or "prompt_tokens" not in entry:
                            continue

                        model = entry.get("model", "unknown")
                        input_toks = entry.get("prompt_tokens", 0)
                        output_toks = entry.get("completion_tokens", 0)
                        timestamp = entry.get("start_time", datetime.now().isoformat())
                        status = entry.get("status_code", 200)

                        usage = TokenUsage(
                            model=model,
                            input_tokens=input_toks,
                            output_tokens=output_toks,
                            total_tokens=input_toks + output_toks,
                            timestamp=timestamp,
                            status="success" if status == 200 else "error",
                        )
                        usages.append(usage)

                        # Track in cache
                        key = f"{model}_{timestamp}"
                        if key not in cache:
                            cache[key] = {
                                "model": model,
                                "input": input_toks,
                                "output": output_toks,
                                "timestamp": timestamp,
                                "status": usage.status,
                            }
                    except json.JSONDecodeError:
                        continue
        except FileNotFoundError:
            pass

        self._save_cache(cache)
        return usages

    def aggregate_by_model(self, hours: int = 24) -> dict:
        """Get token usage aggregated by model for last N hours."""
        cutoff = datetime.now() - timedelta(hours=hours)
        usages = self.parse_requests_log()

        stats = defaultdict(lambda: {"input": 0, "output": 0, "total": 0, "calls": 0})

        for usage in usages:
            try:
                ts = datetime.fromisoformat(usage.timestamp.replace('Z', '+00:00'))
                if ts < cutoff:
                    continue
            except:
                pass

            stats[usage.model]["input"] += usage.input_tokens
            stats[usage.model]["output"] += usage.output_tokens
            stats[usage.model]["total"] += usage.total_tokens
            stats[usage.model]["calls"] += 1

        return dict(stats)

    def report(self, hours: int = 24) -> str:
        """Generate a human-readable token usage report."""
        stats = self.aggregate_by_model(hours)

        if not stats:
            return f"No token usage in last {hours} hours"

        total_input = sum(s["input"] for s in stats.values())
        total_output = sum(s["output"] for s in stats.values())
        total_all = total_input + total_output

        lines = [
            f"\n=== Token Usage (last {hours}h) ===",
            f"Total: {total_all:,} tokens | In: {total_input:,} | Out: {total_output:,}",
            "",
            "Per model:",
        ]

        for model, data in sorted(stats.items(), key=lambda x: x[1]["total"], reverse=True):
            lines.append(
                f"  {model}: {data['total']:,} tokens ({data['calls']} calls) | "
                f"in: {data['input']:,} | out: {data['output']:,}"
            )

        # Cost estimates (ballpark)
        lines.append("")
        lines.append("Cost estimates (if paid):")
        lines.append(f"  Sonnet (in: $0.003/1K, out: $0.015/1K): ${(total_input/1000 * 0.003 + total_output/1000 * 0.015):.2f}")
        lines.append(f"  But you used FREE models! Saved ~${(total_input/1000 * 0.003 + total_output/1000 * 0.015):.2f}")

        return "\n".join(lines)

    def log_mcp_call(self, task: str, model: str, tokens_used: int, status: str = "success"):
        """Log a call from the MCP server."""
        log_file = self.monitor_dir / "mcp_calls.jsonl"
        entry = {
            "timestamp": datetime.now().isoformat(),
            "task_preview": task[:60],
            "model": model,
            "tokens": tokens_used,
            "status": status,
        }
        with open(log_file, "a") as f:
            f.write(json.dumps(entry) + "\n")


def main():
    monitor = TokenMonitor()

    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "report":
            hours = int(sys.argv[2]) if len(sys.argv) > 2 else 24
            print(monitor.report(hours=hours))
        elif cmd == "today":
            print(monitor.report(hours=24))
        elif cmd == "week":
            print(monitor.report(hours=168))
        else:
            print("Usage: token_monitor.py [report|today|week] [hours]")
    else:
        print(monitor.report())


if __name__ == "__main__":
    main()
