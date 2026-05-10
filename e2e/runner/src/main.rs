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

#[derive(Default)]
struct Summary {
    passed: usize,
    expected_parse_failures: usize,
    expected_validation_failures: usize,
    unexpected_failures: Vec<String>,
    unexpected_successes: Vec<String>,
}

fn usage() -> &'static str {
    "usage: nixparserlean-e2e [--manifest PATH] [--parser COMMAND]"
}

fn parse_args() -> Result<(PathBuf, String), String> {
    let mut manifest = PathBuf::from("e2e/manifest.txt");
    let mut parser = String::from("lake exe nixparserlean --file");
    let mut args = env::args().skip(1);

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--manifest" => {
                let value = args.next().ok_or_else(|| format!("missing value\n{}", usage()))?;
                manifest = PathBuf::from(value);
            }
            "--parser" => {
                parser = args.next().ok_or_else(|| format!("missing value\n{}", usage()))?;
            }
            "-h" | "--help" => {
                println!("{}", usage());
                std::process::exit(0);
            }
            _ => return Err(format!("unknown argument: {arg}\n{}", usage())),
        }
    }

    Ok((manifest, parser))
}

fn parse_manifest(path: &Path) -> Result<Vec<Case>, String> {
    let text = std::fs::read_to_string(path)
        .map_err(|err| format!("could not read {}: {err}", path.display()))?;
    let mut cases = Vec::new();

    for (line_idx, raw_line) in text.lines().enumerate() {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }

        let mut parts = line.splitn(3, '\t');
        let case_path = parts
            .next()
            .ok_or_else(|| format!("{}:{}: missing path", path.display(), line_idx + 1))?;
        let expectation = match parts
            .next()
            .ok_or_else(|| format!("{}:{}: missing expectation", path.display(), line_idx + 1))?
        {
            "pass" => Expectation::Pass,
            "parse-fail" => Expectation::ParseFail,
            "validation-fail" => Expectation::ValidationFail,
            other => {
                return Err(format!(
                    "{}:{}: unknown expectation {other:?}",
                    path.display(),
                    line_idx + 1
                ))
            }
        };
        let note = parts.next().unwrap_or("").to_owned();

        cases.push(Case {
            path: PathBuf::from(case_path),
            expectation,
            note,
        });
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
        let first_line = stderr.lines().next().unwrap_or("parser failed without stderr");
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
    let (manifest, parser) = match parse_args() {
        Ok(config) => config,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };

    let cases = match parse_manifest(&manifest) {
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
            (Expectation::Pass, _) => summary
                .unexpected_failures
                .push(format!("{} ({})", case.path.display(), case.note)),
            (_, Outcome::Pass) => summary
                .unexpected_successes
                .push(format!("{} ({})", case.path.display(), case.note)),
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
