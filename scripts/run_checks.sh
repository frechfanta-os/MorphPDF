#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== [1/4] Go Vet & Tests ==="
cd "$ROOT_DIR/backend/go"
go vet ./...
go test -v ./...

echo "=== [2/4] Flutter Analyze ==="
cd "$ROOT_DIR/mobile/flutter"
flutter analyze

echo "=== [3/4] Flutter Tests ==="
flutter test

echo "=== [4/4] Toutes les vérifications de validation sont au vert ! ==="
