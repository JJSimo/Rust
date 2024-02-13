use thiserror::Error;

#[derive(Error, Debug, Clone)]
pub enum Error {
    #[error("Usage: scanner <domain.com>")]
    CliUsage,
}