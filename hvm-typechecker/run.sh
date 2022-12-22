#!/bin/bash

if [ -n "$HVM_PATH" ]; then
    kind2 to-hvm checker.kind2 > checker.hvm && cat data.hvm >> checker.hvm && $HVM_PATH r -f checker.hvm
else
    echo "Define the \$HVM_PATH variable please"
fi

