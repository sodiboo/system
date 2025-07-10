use std::{
    env,
    ffi::OsString,
    fs::{self, File},
    io::{self, Read, Result, Write},
    os::unix::net::{UnixDatagram, UnixStream},
    path::PathBuf,
};

fn env(var: &str) -> Result<OsString> {
    env::var_os(var).ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("{var} environment variable is not set."),
        )
    })
}

fn main() -> Result<()> {
    let notify_socket = UnixDatagram::unbound()?;
    notify_socket.connect(env("NOTIFY_SOCKET")?)?;

    let mut niri_socket = UnixStream::connect(env("NIRI_SOCKET")?)?;

    let environment_file_path = PathBuf::from(env("FILL_ENVIRONMENT_FILE")?);
    {
        environment_file_path
            .parent()
            .map(fs::create_dir_all)
            .transpose()?;

        let mut f = File::create(&environment_file_path)?;
        for variable in env::args().skip(1) {
            writeln!(
                f,
                "{variable}={contents}",
                contents = env(&variable)?.to_str().ok_or_else(|| {
                    io::Error::new(
                        io::ErrorKind::InvalidData,
                        format!("Environment variable {variable} is not valid UTF-8."),
                    )
                })?
            )?;
        }
    }

    // env file has been created, others may start now.
    notify_socket.send("READY=1".as_bytes())?;

    // niri doesn't write into the socket until we write a request.
    // so, this blocks until niri closes the socket.
    niri_socket.set_read_timeout(None)?;
    let _ = niri_socket.read_exact(&mut [0]);

    notify_socket.send("STOPPING=1".as_bytes())?;

    fs::remove_file(environment_file_path)
}
