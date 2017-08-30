#!/bin/bash
# Strict mode
set -euo pipefail

# use PASSWORD env (default is admin ) to set notebook password

HASH=$(python -c "from notebook.auth import passwd; print(passwd('${PASSWORD:-admin}'))")

unset PASSWORD