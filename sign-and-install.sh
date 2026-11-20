#!/bin/bash
# Usage: ./sign-and-install.sh FudAI-unsigned.ipa cert.p12 'p12-password' profile.mobileprovision
# Re-signs the unsigned IPA with your .p12 + .mobileprovision and installs it on a USB-connected iPhone.
# Needs: brew install zsign libimobiledevice ideviceinstaller
set -euo pipefail
IPA="$1"; P12="$2"; PASS="$3"; PROF="$4"

# Bundle ID your profile allows (e.g. com.you.fudai or a wildcard like com.you.*)
APPID=$(security cms -D -i "$PROF" | plutil -extract Entitlements.application-identifier raw - | sed 's/^[A-Z0-9]*\.//')
echo "Profile app ID: $APPID"
if [[ "$APPID" == *"*" ]]; then
  BUNDLE="${APPID%\*}fudai"        # wildcard profile -> pick a concrete ID
else
  BUNDLE="$APPID"
fi
echo "Signing as bundle ID: $BUNDLE"

WORK=$(mktemp -d)
unzip -q "$IPA" -d "$WORK"
APP=$(ls -d "$WORK"/Payload/*.app)

# One profile covers only one bundle ID, so drop widgets/share extension/Watch app.
rm -rf "$APP/PlugIns" "$APP/Watch" "$APP/SC_Info"

( cd "$WORK" && zip -qry unsigned-slim.ipa Payload )
zsign -k "$P12" -p "$PASS" -m "$PROF" -b "$BUNDLE" -o FudAI-signed.ipa "$WORK/unsigned-slim.ipa"
echo "Signed -> FudAI-signed.ipa"

ideviceinstaller -i FudAI-signed.ipa
