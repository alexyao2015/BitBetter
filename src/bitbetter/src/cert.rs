use anyhow::{Context, Result, bail};
use openssl::hash::MessageDigest;
use openssl::x509::X509;
use std::cmp::Ordering;

pub fn pad_cert(cert_data: Vec<u8>, new_len: usize) -> Result<Vec<u8>> {
    let old_len = cert_data.len();

    match old_len.cmp(&new_len) {
        Ordering::Greater => {
            bail!("Error: {:?} is larger than {:?}", old_len, new_len)
        }
        Ordering::Less => {
            println!("Adding padding to certificate data");
            let padding_len = new_len - old_len;
            let mut new_cert_data = cert_data;
            new_cert_data.extend(vec![0u8; padding_len]);
            return Ok(new_cert_data);
        }
        Ordering::Equal => {
            println!("Certificate data is already the correct size");
            return Ok(cert_data);
        }
    }
}

pub fn get_cert_hash(cert_data: &Vec<u8>) -> Result<Vec<u8>> {
    let cert = X509::from_der(&cert_data)
        .or_else(|_| X509::from_pem(&cert_data))
        .context("Failed to parse certificate")?;

    let fingerprint = cert.digest(MessageDigest::sha1())?;
    let fingerprint_hex = const_hex::encode(fingerprint).to_uppercase();

    // C# will encode hardcoded strings as UTF-16LE
    let utf16_bytes: Vec<u8> = fingerprint_hex
        .encode_utf16()
        .flat_map(|c| c.to_le_bytes())
        .collect();
    Ok(utf16_bytes)
}
