use std::{
    io::{Read, stdin},
    process::exit,
};

use std::io::{self, IsTerminal};
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
struct Opt {
    /// Silent mode: no additional info text
    /// (default when stdout is not a terminal)
    #[structopt(short = "s", long = "silent")]
    silent: bool,
}

fn main() {
    let is_terminal = io::stdout().is_terminal();
    let silent = Opt::from_args().silent || !is_terminal;

    // read stdin
    let key = {
        let mut buffer = String::with_capacity(128);
        stdin().read_to_string(&mut buffer).expect("read stdin");
        let buffer = buffer.trim().to_string();

        if buffer.is_empty() {
            eprintln!("expect to receive content from stdin");
            exit(1);
        }
        buffer
    };

    let value = std::env::var(&key).expect("environment variable with key");

    if !silent {
        eprint!("{key}=");
    }
    print!("{value}");

    // print new line if we're in a terminal
    if is_terminal {
        println!();
    }
}
