#!/bin/bash

module add g16-C.01

if [ $# -ne 1 ]; then
  echo "Usage: $0 <logfile>"
  exit 1
fi

LOGFILE="$1"
if [ ! -f "$LOGFILE" ]; then
  echo "[ERROR] Log file '$LOGFILE' not found."
  exit 1
fi

ARCHIVE=$(pluck "$LOGFILE" | tr -d '\n')
if [ -z "$ARCHIVE" ]; then
  echo "[ERROR] Failed to extract calculation archive."
  exit 1
fi

METHOD=$(echo "$ARCHIVE" | grep -oP '(?<=\\#p ).+?(?=\\)')

CHARGE=$(echo "$ARCHIVE" | grep -oP '(?<=\\)[-]?\d+(?=,)')
MULTIPLICITY=$(echo "$ARCHIVE" | grep -oP '(?<=,)[-]?\d+(?=\\)')

ATOMS=$(echo "$ARCHIVE" | grep -oP '[A-Z]+,[-.\d]+,[-.\d]+,[-.\d]+(?=\\)')

TOTAL_ATOMS=$(echo "$ATOMS" | wc -l)

echo "Method: $METHOD"
echo "Charge: $CHARGE"
echo "Multiplicity: $MULTIPLICITY"
echo "Total Atoms: $TOTAL_ATOMS"
echo "Atoms and Coordinates:"
echo "$ATOMS" | nl -w2 -s': '

expand_ranges() {
  local INPUT="$1"
  echo "$INPUT" | awk -F, '{
    for (i = 1; i <= NF; i++) {
      if ($i ~ /-/) {
        split($i, range, "-");
        for (j = range[1]; j <= range[2]; j++) printf j " ";
      } else {
        printf $i " ";
      }
    }
  }'
}

echo "How many fragments do you have?"
read -r NUM_FRAGMENTS

declare -a FRAGMENTS
REMAINING_ATOMS=$(seq 1 $TOTAL_ATOMS)

for ((i=1; i<=NUM_FRAGMENTS; i++)); do
  if [[ $i -eq $NUM_FRAGMENTS ]]; then
    echo "For the last fragment, do you want to include all remaining atoms? (y/n)"
    read -r INCLUDE_REMAINING
    if [[ $INCLUDE_REMAINING == "y" ]]; then
      FRAGMENTS[$i]="$REMAINING_ATOMS"
      break
    fi
  fi

  echo "Enter indices for fragment $i (e.g., 1-6,11-16,20):"
  read -r FRAGMENT

  EXPANDED=$(expand_ranges "$FRAGMENT")
  echo "[DEBUG] Expansion: $EXPANDED"
  FRAGMENTS[$i]="$EXPANDED"

  REMAINING_ATOMS=$(echo "$REMAINING_ATOMS" | tr ' ' '\n' | grep -v -w -F -f <(echo "$EXPANDED" | tr ' ' '\n') | tr '\n' ' ')

  echo "[DEBUG] Remaining atoms after assigning fragment $i: $REMAINING_ATOMS"
done

echo "[DEBUG] Fragment 1:"
echo "${FRAGMENTS[1]}"

echo "[DEBUG] Fragment 2:"
echo "${FRAGMENTS[2]}"

echo "Enter the output GJF filename (with extension):"
read -r OUTPUT_FILE

{
  echo "%chk=$OUTPUT_FILE.chk"
  echo "#p $METHOD"

  echo ""
  echo "Generated Gaussian Input"
  echo ""

  echo "$CHARGE $MULTIPLICITY"

  for ((i=1; i<=NUM_FRAGMENTS; i++)); do
    for INDEX in ${FRAGMENTS[$i]}; do
      LINE=$(echo "$ATOMS" | sed -n "${INDEX}p")
      ELEMENT=$(echo "$LINE" | cut -d',' -f1)
      COORD1=$(echo "$LINE" | cut -d',' -f2)
      COORD2=$(echo "$LINE" | cut -d',' -f3)
      COORD3=$(echo "$LINE" | cut -d',' -f4)
      echo "$ELEMENT(Fragment=$i)   0   $COORD1   $COORD2   $COORD3"
    done
  done

  echo ""
  echo ""
} > "$OUTPUT_FILE"

echo "GJF file '$OUTPUT_FILE' created successfully."
