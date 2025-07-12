#!/usr/bin/env bash

set -euo pipefail

echo "Patching bitwarden..."

readonly BITBETTER_BASE=/bitbetter
readonly BITBETTER_OLD_CER="${BITBETTER_BASE}/licensing.cer"
readonly BITBETTER_NEW_CER="${BITBETTER_BASE}/certs/bitbetter.cer"
readonly BITBETTER_NEW_INSTALL_CER="${BITBETTER_BASE}/bitbetter-install.cer"

if [ ! -f "${BITBETTER_NEW_CER}" ]; then
    echo "Error: ${BITBETTER_NEW_CER} not found"
    exit 1
fi

cp "${BITBETTER_NEW_CER}" "${BITBETTER_NEW_INSTALL_CER}"

original_size=$(stat --format="%s" "${BITBETTER_OLD_CER}")
new_size=$(stat --format="%s" "${BITBETTER_NEW_INSTALL_CER}")

if [ "${new_size}" -gt "${original_size}" ]; then
    echo "Error: ${BITBETTER_NEW_INSTALL_CER} is larger than ${BITBETTER_OLD_CER}"
    exit 1
fi

if [ "${new_size}" -lt "${original_size}" ]; then
    # Add padding to the bitbetter.cer file to make it the same size as the licensing.cer file
    ls -l "${BITBETTER_OLD_CER}" "${BITBETTER_NEW_INSTALL_CER}"
    echo "Adding padding to ${BITBETTER_NEW_INSTALL_CER}"
    dd if=/dev/zero bs=1 count=$(( original_size - new_size )) >> "${BITBETTER_NEW_INSTALL_CER}" 2>/dev/null
    ls -l "${BITBETTER_OLD_CER}" "${BITBETTER_NEW_INSTALL_CER}"
fi

original_cert=$( \
    xxd -p "${BITBETTER_OLD_CER}" \
    | tr -d '\n' \
)
new_cert=$( \
    xxd -p "${BITBETTER_NEW_INSTALL_CER}" \
    | tr -d '\n' \
)

extract_cert_hash() {
    openssl x509 -in "${1}" -noout -fingerprint -sha1 \
    | sed 's/://g' \
    | sed 's/^.*=//' \
    | tr -d '\n' \
    | iconv -f utf-8 -t utf-16le \
    | xxd -p \
    | tr -d '\n'
}

original_cert_hash=$(extract_cert_hash "${BITBETTER_OLD_CER}")
new_cert_hash=$(extract_cert_hash "${BITBETTER_NEW_INSTALL_CER}")

# https://github.com/BurntSushi/ripgrep/issues/2934
cert_replace_files=$( \
    rg --no-unicode --multiline --text -l \
    "$( \
        echo -n "${original_cert}" \
        | sed 's/../\\x&/g' \
    )" \
    . \
)
cert_hash_replace_files=$( \
    rg --no-unicode --multiline --text -l \
    "$( \
        echo -n "${original_cert_hash}" \
        | sed 's/../\\x&/g' \
    )" \
    . \
)

echo "Detected files to replace certificate in: ${cert_replace_files}"
echo "Detected files to replace certificate hash in: ${cert_hash_replace_files}"

replace_in_files() {
    local replace_type="$1"
    local replacement_files="$2"
    local old_string="$3"
    local new_string="$4"
    
    for file in ${replacement_files}; do
        xxd -p "${file}" \
        | tr -d '\n' \
        | sed -e "s|${old_string}|${new_string}|" \
        | xxd -r -p \
        > "${file}.new"
        if cmp -s "${file}" "${file}.new"; then
            echo "No changes made to ${file}. Exiting."
            exit 1
        fi
        mv "${file}.new" "${file}"
        chmod +x "${file}"
        echo "Replaced ${replace_type} in ${file}"
    done
}

replace_in_files "certificate" "${cert_replace_files}" "${original_cert}" "${new_cert}"
replace_in_files "certificate hash" "${cert_hash_replace_files}" "${original_cert_hash}" "${new_cert_hash}"

echo "Patching bitwarden completed successfully"
