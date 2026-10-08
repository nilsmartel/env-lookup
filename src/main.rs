use std::{
    ffi::OsString,
    io::{Read, stdin},
    process::exit,
};

use std::io::{self, IsTerminal};
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
struct Opt {
    /// Variable name to look up. If left empty, stdin will be used (default)
    key: Option<String>,

    /// Silent mode: no additional info text
    /// (default when stdout is not a terminal)
    #[structopt(short = "s", long = "silent")]
    silent: bool,

    /// .env files which values can be used.
    /// These will be used before environment variables are checked.
    /// Multiple files can be used.
    #[structopt(short = "e", long = "env")]
    env: Vec<OsString>,
}

fn main() {
    let is_terminal = io::stdout().is_terminal();
    let Opt { key, silent, env } = Opt::from_args();
    let silent = silent || !is_terminal;

    // Use the positional key argument if given, otherwise read it from stdin.
    let key = match key {
        Some(key) => key,
        None => {
            let mut buffer = String::with_capacity(128);
            stdin().read_to_string(&mut buffer).expect("read stdin");
            let buffer = buffer.trim().to_string();

            if buffer.is_empty() {
                eprintln!("expect to receive a key as an argument or from stdin");
                exit(1);
            }
            buffer
        }
    };

    let value = get_env(&env, &key);

    if !silent {
        eprint!("{key}=");
    }
    print!("{value}");

    // print new line if we're in a terminal
    if is_terminal {
        println!();
    }
}

fn get_env(env: &[OsString], key: &str) -> String {
    if !env.is_empty() {
        let env_vars = env_file_reader::read_files(env).expect("to read env files");
        if let Some(value) = env_vars.get(key) {
            return value.to_string();
        }
    }

    std::env::var(&key).expect("environment variable with key")
}
