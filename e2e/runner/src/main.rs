use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Expectation {
    Pass,
    ParseFail,
    ValidationFail,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Outcome {
    Pass,
    ParseFail,
    ValidationFail,
    OtherFail,
}

#[derive(Debug)]
struct Case {
    path: PathBuf,
    expectation: Expectation,
    note: String,
}

#[derive(Debug)]
enum ManifestEntry {
    File {
        path: PathBuf,
        expectation: Expectation,
        note: String,
    },
    Url {
        name: String,
        url: String,
        expectation: Expectation,
        note: String,
    },
}

#[derive(Default)]
struct Summary {
    passed: usize,
    expected_parse_failures: usize,
    expected_validation_failures: usize,
    unexpected_failures: Vec<String>,
    unexpected_successes: Vec<String>,
}

fn usage() -> &'static str {
    "usage: nixparserlean-e2e [--manifest PATH] [--parser COMMAND] [--cache-dir PATH]"
}

fn parse_args() -> Result<(PathBuf, String, PathBuf), String> {
    let mut manifest = PathBuf::from("e2e/manifest.txt");
    let mut parser = String::from("lake exe nixparserlean --file");
    let mut cache_dir = PathBuf::from("e2e/cache");
    let mut args = env::args().skip(1);

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--manifest" => {
                let value = args
                    .next()
                    .ok_or_else(|| format!("missing value\n{}", usage()))?;
                manifest = PathBuf::from(value);
            }
            "--parser" => {
                parser = args
                    .next()
                    .ok_or_else(|| format!("missing value\n{}", usage()))?;
            }
            "--cache-dir" => {
                let value = args
                    .next()
                    .ok_or_else(|| format!("missing value\n{}", usage()))?;
                cache_dir = PathBuf::from(value);
            }
            "-h" | "--help" => {
                println!("{}", usage());
                std::process::exit(0);
            }
            _ => return Err(format!("unknown argument: {arg}\n{}", usage())),
        }
    }

    Ok((manifest, parser, cache_dir))
}

fn parse_expectation(raw: &str, manifest: &Path, line: usize) -> Result<Expectation, String> {
    match raw {
        "pass" => Ok(Expectation::Pass),
        "parse-fail" => Ok(Expectation::ParseFail),
        "validation-fail" => Ok(Expectation::ValidationFail),
        other => Err(format!(
            "{}:{}: unknown expectation {other:?}",
            manifest.display(),
            line
        )),
    }
}

fn parse_manifest(path: &Path) -> Result<Vec<ManifestEntry>, String> {
    let text = std::fs::read_to_string(path)
        .map_err(|err| format!("could not read {}: {err}", path.display()))?;
    let mut entries = Vec::new();

    for (line_idx, raw_line) in text.lines().enumerate() {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }

        let fields: Vec<&str> = line.split('\t').collect();
        let line_no = line_idx + 1;
        match fields.as_slice() {
            ["file", case_path, expectation, note] => {
                entries.push(ManifestEntry::File {
                    path: PathBuf::from(case_path),
                    expectation: parse_expectation(expectation, path, line_no)?,
                    note: (*note).to_owned(),
                });
            }
            ["url", name, url, expectation, note] => {
                entries.push(ManifestEntry::Url {
                    name: (*name).to_owned(),
                    url: (*url).to_owned(),
                    expectation: parse_expectation(expectation, path, line_no)?,
                    note: (*note).to_owned(),
                });
            }
            [case_path, expectation, note] => {
                entries.push(ManifestEntry::File {
                    path: PathBuf::from(case_path),
                    expectation: parse_expectation(expectation, path, line_no)?,
                    note: (*note).to_owned(),
                });
            }
            _ => {
                return Err(format!(
                    "{}:{}: expected path/expectation/note, file/path/expectation/note, or url/name/url/expectation/note",
                    path.display(),
                    line_no
                ));
            }
        }
    }

    Ok(entries)
}

fn cache_url(name: &str, url: &str, cache_dir: &Path) -> Result<PathBuf, String> {
    std::fs::create_dir_all(cache_dir)
        .map_err(|err| format!("could not create cache dir {}: {err}", cache_dir.display()))?;

    let path = cache_dir.join(name);
    if path.exists() {
        return Ok(path);
    }

    let status = Command::new("curl")
        .arg("--fail")
        .arg("--location")
        .arg("--silent")
        .arg("--show-error")
        .arg("--output")
        .arg(&path)
        .arg(url)
        .status()
        .map_err(|err| format!("could not run curl for {url}: {err}"))?;

    if status.success() {
        Ok(path)
    } else {
        Err(format!("curl failed for {url} with status {status}"))
    }
}

fn resolve_cases(entries: &[ManifestEntry], cache_dir: &Path) -> Result<Vec<Case>, String> {
    let mut cases = Vec::new();
    for entry in entries {
        match entry {
            ManifestEntry::File {
                path,
                expectation,
                note,
            } => cases.push(Case {
                path: path.clone(),
                expectation: *expectation,
                note: note.clone(),
            }),
            ManifestEntry::Url {
                name,
                url,
                expectation,
                note,
            } => cases.push(Case {
                path: cache_url(name, url, cache_dir)?,
                expectation: *expectation,
                note: note.clone(),
            }),
        }
    }
    Ok(cases)
}

fn run_parser(command: &str, path: &Path) -> Result<Outcome, String> {
    let mut parts = command.split_whitespace();
    let program = parts
        .next()
        .ok_or_else(|| String::from("parser command cannot be empty"))?;
    let mut cmd = Command::new(program);
    cmd.args(parts);
    cmd.arg(path);

    let output = cmd
        .output()
        .map_err(|err| format!("could not run parser command {command:?}: {err}"))?;

    if output.status.success() {
        Ok(Outcome::Pass)
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let first_line = stderr
            .lines()
            .next()
            .unwrap_or("parser failed without stderr");
        eprintln!("{}: {}", path.display(), first_line);
        if first_line.starts_with("parse error") {
            Ok(Outcome::ParseFail)
        } else if first_line.starts_with("semantic error") {
            Ok(Outcome::ValidationFail)
        } else {
            Ok(Outcome::OtherFail)
        }
    }
}

fn main() {
    let (manifest, parser, cache_dir) = match parse_args() {
        Ok(config) => config,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };

    let entries = match parse_manifest(&manifest) {
        Ok(entries) => entries,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let cases = match resolve_cases(&entries, &cache_dir) {
        Ok(cases) => cases,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };

    let mut summary = Summary::default();

    for case in &cases {
        let outcome = match run_parser(&parser, &case.path) {
            Ok(outcome) => outcome,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        };

        match (case.expectation, outcome) {
            (Expectation::Pass, Outcome::Pass) => summary.passed += 1,
            (Expectation::ParseFail, Outcome::ParseFail) => summary.expected_parse_failures += 1,
            (Expectation::ValidationFail, Outcome::ValidationFail) => {
                summary.expected_validation_failures += 1
            }
            (Expectation::Pass, _) => {
                summary
                    .unexpected_failures
                    .push(format!("{} ({})", case.path.display(), case.note))
            }
            (_, Outcome::Pass) => summary.unexpected_successes.push(format!(
                "{} ({})",
                case.path.display(),
                case.note
            )),
            _ => summary.unexpected_failures.push(format!(
                "{} ({}) expected {:?}, got {:?}",
                case.path.display(),
                case.note,
                case.expectation,
                outcome
            )),
        }
    }

    println!(
        "e2e: {} passed, {} expected parse failures, {} expected validation failures, {} unexpected failures, {} unexpected successes",
        summary.passed,
        summary.expected_parse_failures,
        summary.expected_validation_failures,
        summary.unexpected_failures.len(),
        summary.unexpected_successes.len()
    );

    for item in &summary.unexpected_failures {
        eprintln!("unexpected failure: {item}");
    }
    for item in &summary.unexpected_successes {
        eprintln!("unexpected success: {item}");
    }

    if !summary.unexpected_failures.is_empty() || !summary.unexpected_successes.is_empty() {
        std::process::exit(1);
    }
}
