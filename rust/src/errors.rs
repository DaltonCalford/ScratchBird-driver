use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorKind {
    Unknown,
    Warning,
    NoData,
    Connection,
    NotSupported,
    Data,
    Integrity,
    Auth,
    Transaction,
    Syntax,
    Resource,
    Limit,
    OperatorIntervention,
    System,
    Internal,
}

#[derive(Debug)]
pub struct Error {
    pub kind: ErrorKind,
    pub message: String,
    pub sqlstate: Option<String>,
    pub detail: Option<String>,
    pub hint: Option<String>,
}

pub type Result<T> = std::result::Result<T, Error>;

impl Error {
    pub fn new(kind: ErrorKind, message: impl Into<String>) -> Self {
        Self {
            kind,
            message: message.into(),
            sqlstate: None,
            detail: None,
            hint: None,
        }
    }

    pub fn with_sqlstate(
        kind: ErrorKind,
        message: impl Into<String>,
        sqlstate: Option<String>,
        detail: Option<String>,
        hint: Option<String>,
    ) -> Self {
        Self {
            kind,
            message: message.into(),
            sqlstate,
            detail,
            hint,
        }
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if let Some(state) = &self.sqlstate {
            write!(f, "[{}] {}", state, self.message)
        } else {
            write!(f, "{}", self.message)
        }
    }
}

impl std::error::Error for Error {}

impl From<std::io::Error> for Error {
    fn from(err: std::io::Error) -> Self {
        Error::new(ErrorKind::Connection, err.to_string())
    }
}

pub fn error_from_sqlstate(
    sqlstate: &str,
    message: impl Into<String>,
    detail: Option<String>,
    hint: Option<String>,
) -> Error {
    let prefix = sqlstate.get(0..2).unwrap_or("");
    let kind = match prefix {
        "01" => ErrorKind::Warning,
        "02" => ErrorKind::NoData,
        "08" => ErrorKind::Connection,
        "0A" => ErrorKind::NotSupported,
        "22" => ErrorKind::Data,
        "23" => ErrorKind::Integrity,
        "28" => ErrorKind::Auth,
        "40" => ErrorKind::Transaction,
        "42" => ErrorKind::Syntax,
        "53" => ErrorKind::Resource,
        "54" => ErrorKind::Limit,
        "57" => ErrorKind::OperatorIntervention,
        "58" => ErrorKind::System,
        "XX" => ErrorKind::Internal,
        _ => ErrorKind::Unknown,
    };
    Error::with_sqlstate(kind, message, Some(sqlstate.to_string()), detail, hint)
}
