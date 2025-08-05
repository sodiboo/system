//! Caddy supports socket activation by passing FDs.
//! But, it does not support systemd's protocol for naming them.
//!
//! This is a simple wrapper that converts systemd listen_fds into disjoint environment variables,
//! so they can be used in Caddy configuration like `fd/{env.http}`

use std::{convert::Infallible, env, error, io, iter, os::unix::process::CommandExt, process};

fn invalid_input(error: impl Into<Box<dyn error::Error + Send + Sync>>) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidInput, error)
}

fn main() -> io::Result<Infallible> {
    let mut cmd = process::Command::new(env!("EXECUTABLE"));
    cmd.args(env::args_os().skip(1));

    let is_for_me;
    match env::var("LISTEN_PID") {
        Err(env::VarError::NotPresent) => is_for_me = true,
        Ok(listen_pid) if listen_pid.is_empty() => is_for_me = true,
        Ok(listen_pid) => {
            let listen_pid = listen_pid.parse::<u32>().map_err(invalid_input)?;

            is_for_me = listen_pid == process::id()
        }
        Err(error) => return Err(invalid_input(error)),
    };

    if is_for_me {
        let listen_fds = env::var("LISTEN_FDS")
            .map_err(invalid_input)?
            .parse::<usize>()
            .map_err(invalid_input)?;

        let listen_fd_names = env::var("LISTEN_FDNAMES").map_err(invalid_input)?;
        let listen_fd_names = listen_fd_names.split(":").collect::<Vec<_>>();

        if listen_fd_names.len() != listen_fds {
            return Err(invalid_input("LISTEN_FDS is not length of LISTEN_FDNAMES"));
        }

        const LISTEN_FDS_START: u32 = 3;
        let listen_fds = (LISTEN_FDS_START..).map(|fd| fd.to_string());

        let listen_fd_names = listen_fd_names.into_iter().map(|name| format!("FD_{name}"));

        cmd.envs(iter::zip(listen_fd_names, listen_fds));
    }

    cmd.env_remove("LISTEN_PID");
    cmd.env_remove("LISTEN_FDS");
    cmd.env_remove("LISTEN_FDNAMES");

    Err(cmd.exec())
}
