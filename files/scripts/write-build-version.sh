#!/bin/bash
# Write a build timestamp into the omadora skel directory so the onboarding
# service can detect when the image has been rebased/updated.
echo "$(date -u +%Y%m%dT%H%M%SZ)" > /etc/skel/.local/share/omadora/.obsidian-blue-build
echo "Build version written: $(cat /etc/skel/.local/share/omadora/.obsidian-blue-build)"
