#!/bin/bash
set -e
echo "Creating foreign tables..."
iris session IRIS < /opt/app/iris-foreigntable.script