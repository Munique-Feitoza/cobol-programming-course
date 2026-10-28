#!/usr/bin/env bash
set -euo pipefail

program="${1:?program name is required}"
jar="$(find cobol-check/bin -maxdepth 1 -type f -name 'cobol-check-*.jar' -print -quit)"
generated="cobol-check/CC##99.CBL"
userid="${ZOWE_USERNAME:?ZOWE_USERNAME is required}"

if [[ -z "$jar" ]]; then
  echo "COBOL Check JAR was not found" >&2
  exit 1
fi

rm -f "$generated" cobol-check/ALLTESTS
java -jar "$jar" -p "$program"

if [[ ! -s "$generated" ]]; then
  echo "COBOL Check did not generate $generated" >&2
  exit 1
fi

zowe zos-files upload file-to-data-set "$generated" "${userid}.CBL(${program})" --response-timeout 60
zowe zos-files upload file-to-data-set "${program}.JCL" "${userid}.JCL(${program})" --response-timeout 60
zowe jobs submit data-set "${userid}.JCL(${program})" --wait-for-output
