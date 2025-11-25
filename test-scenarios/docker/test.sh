#!/bin/bash
set -e

echo "Testing Docker workflow"
echo "Current directory: $(pwd)"
echo "Date: $(date)"
echo "User: $(whoami)"

# Test curl is available
if command -v curl &> /dev/null; then
    echo "curl is available"
else
    echo "curl is not available"
    exit 1
fi

echo "Docker test completed successfully"