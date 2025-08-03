use anyhow::{Context, Result, bail};
use clap::Parser;
use rayon::prelude::*;
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use walkdir::WalkDir;

mod cert;
use crate::cert::{get_cert_hash, pad_cert};

#[derive(Parser)]
#[command(name = "bitbetter-patch")]
#[command(about = "A tool to patch Bitwarden with custom certificates")]
struct Cli {
    #[arg(short = 'o', long = "old-cert")]
    old_cert: PathBuf,

    #[arg(short = 'n', long = "new-cert")]
    new_cert: PathBuf,

    #[arg(short = 's', long = "search-path")]
    search_path: PathBuf,
}

struct BitBetter {
    old_cert: Vec<u8>,
    new_cert: Vec<u8>,
    old_cert_hash: Vec<u8>,
    new_cert_hash: Vec<u8>,
    search_path: PathBuf,
}

impl BitBetter {
    fn new(
        old_cert_path: PathBuf,
        new_cert_path: PathBuf,
        search_path: PathBuf,
    ) -> Result<Self> {
        // ensure all inputs exist
        for path in [&old_cert_path, &new_cert_path, &search_path] {
            if !path.exists() {
                bail!("{:?} not found", path);
            }
        }

        let old_cert = fs::read(&old_cert_path)
            .with_context(|| format!("Failed to read {:?}", old_cert_path))?;
        let new_cert = fs::read(&new_cert_path)
            .with_context(|| format!("Failed to read {:?}", new_cert_path))?;
        let new_cert =
            pad_cert(new_cert, old_cert.len()).with_context(|| {
                format!("Failed to pad new certificate: {:?}", new_cert_path)
            })?;

        let old_cert_hash = get_cert_hash(&old_cert).with_context(|| {
            format!(
                "Failed to get hash of old certificate: {:?}",
                old_cert_path
            )
        })?;
        let new_cert_hash = get_cert_hash(&new_cert).with_context(|| {
            format!(
                "Failed to get hash of new certificate: {:?}",
                new_cert_path
            )
        })?;

        Ok(Self {
            old_cert,
            new_cert,
            old_cert_hash,
            new_cert_hash,
            search_path,
        })
    }

    fn patch(&self) -> Result<()> {
        println!("Patching bitwarden...");

        println!(
            "Original certificate: {:?}",
            const_hex::encode(&self.old_cert)
        );
        println!("New certificate: {:?}", const_hex::encode(&self.new_cert));
        println!(
            "Original certificate hash: {:?}",
            const_hex::encode(&self.old_cert_hash)
        );
        println!(
            "New certificate hash: {:?}",
            const_hex::encode(&self.new_cert_hash)
        );

        let cert_files = self.find_files_containing_pattern(&self.old_cert)?;
        let hash_files =
            self.find_files_containing_pattern(&self.old_cert_hash)?;

        if cert_files.is_empty() {
            bail!("No files found containing the original certificate");
        }
        println!(
            "Detected files to replace certificate in: {:?}",
            cert_files.keys()
        );

        if hash_files.is_empty() {
            bail!("No files found containing the original certificate hash");
        }
        println!(
            "Detected files to replace certificate hash in: {:?}",
            hash_files.keys()
        );

        for (file_path, positions) in cert_files {
            self.replace_in_file(&file_path, &self.new_cert, &positions)?;
            println!("Replaced certificate in {:?}", file_path);
        }
        for (file_path, positions) in hash_files {
            self.replace_in_file(&file_path, &self.new_cert_hash, &positions)?;
            println!("Replaced certificate hash in {:?}", file_path);
        }

        println!("Patching bitwarden completed successfully");
        Ok(())
    }

    fn find_files_containing_pattern(
        &self,
        hex_pattern: &Vec<u8>,
    ) -> Result<HashMap<PathBuf, Vec<usize>>> {
        // First collect all file paths
        let file_paths: Vec<PathBuf> = WalkDir::new(&self.search_path)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|entry| entry.file_type().is_file())
            .map(|entry| entry.path().to_path_buf())
            .collect();

        // Process files in parallel
        let matching_files: Vec<(PathBuf, Vec<usize>)> = file_paths
            .par_iter()
            .filter_map(|file_path| {
                if let Ok(file_data) = fs::read(file_path) {
                    let matches =
                        self.contains_pattern(&file_data, &hex_pattern);
                    if matches.len() > 0 {
                        Some((file_path.clone(), matches))
                    } else {
                        None
                    }
                } else {
                    None
                }
            })
            .collect();

        let mut results: HashMap<PathBuf, Vec<usize>> = HashMap::new();
        for (path, matches) in &matching_files {
            results.insert(path.clone(), matches.clone());
        }

        Ok(results)
    }

    fn contains_pattern(&self, haystack: &[u8], needle: &[u8]) -> Vec<usize> {
        haystack
            .par_windows(needle.len())
            .enumerate()
            .filter_map(
                |(i, window)| {
                    if window == needle { Some(i) } else { None }
                },
            )
            .collect()
    }

    fn replace_in_file(
        &self,
        file_path: &PathBuf,
        replacement: &Vec<u8>,
        positions: &Vec<usize>,
    ) -> Result<()> {
        let mut file_data = fs::read(file_path)
            .with_context(|| format!("Failed to read {:?}", file_path))?;

        for &pos in positions {
            let end = pos + replacement.len();
            file_data[pos..end].copy_from_slice(replacement);
        }

        fs::write(file_path, &file_data)
            .with_context(|| format!("Failed to write {:?}", file_path))?;

        Ok(())
    }
}

fn main() -> Result<()> {
    let args = Cli::parse();
    let patcher =
        BitBetter::new(args.old_cert, args.new_cert, args.search_path)?;
    patcher.patch()
}
