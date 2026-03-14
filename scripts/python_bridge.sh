#!/bin/bash
# shared-kit/scripts/python_bridge.sh
# Bridge to execute Swift commands from Python agents

SKILL=$1
ARGS="${*:2}"

if [ -z "$SKILL" ]; then
    echo "Usage: $0 <skill_id> [args]"
    exit 1
fi

case $SKILL in
    "swift-test-runner")
        swift test $ARGS
        ;;
    "swift-lint")
        swiftlint lint $ARGS
        ;;
    "swift-doc-gen")
        swift package --allow-writing-to-package-directory generate-documentation $ARGS
        ;;
    *)
        echo "Error: Unknown skill '$SKILL'"
        exit 1
        ;;
esac
