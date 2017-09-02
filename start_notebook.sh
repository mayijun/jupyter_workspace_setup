#!/bin/bash
# Strict mode
set -euo pipefail

# use PASSWORD env (default is admin ) to set notebook password

HASH=$(python -c "from notebook.auth import passwd; print(passwd('${PASSWORD:-admin}'))")

echo "========================================================================"
echo "You can now connect to this Ipython Notebook server "
echo "  use password: ${PASSWORD:-admin} to login"
echo "========================================================================"

unset PASSWORD

jupyter lab --allow-root --NotebookApp.password="$HASH"