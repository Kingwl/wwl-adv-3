#!/usr/bin/env bash
set -euo pipefail

"$(dirname "${BASH_SOURCE[0]}")/check-docs.sh"
"$(dirname "${BASH_SOURCE[0]}")/check-structure.sh"

echo "all scaffold checks passed"
