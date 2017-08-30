#!/bin/bash
# Strict mode
set -euo pipefail
set -v

# use PASSWORD env (default is admin ) to set notebook password

HASH=$(python -c "from notebook.auth import passwd; print(passwd('${PASSWORD:-admin}'))")

echo "========================================================================"
echo "You can now connect to this Ipython Notebook server using, for example:"
echo ""
echo "  docker run -d -p <your-port>:8888 -e password=<your-password> ipython/noetebook"
echo ""
echo "  use password: ${PASSWORD:-admin} to login"
echo ""
echo "========================================================================"

unset PASSWORD

jupyter lab --allow-root --NotebookApp.password="$HASH"