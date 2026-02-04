// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
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
    let kind = if sqlstate.len() == 5 {
        match sqlstate {
            "01000" => ErrorKind::Warning,
            "02000" => ErrorKind::NoData,
            "08001" | "08003" | "08004" | "08006" | "08P01" => ErrorKind::Connection,
            "0A000" => ErrorKind::NotSupported,
            "22001" | "22003" | "22007" | "22012" | "22023" | "22P02" | "22P03" => ErrorKind::Data,
            "23000" | "23502" | "23503" | "23505" | "23514" => ErrorKind::Integrity,
            "28000" | "28P01" => ErrorKind::Auth,
            "40001" | "40P01" => ErrorKind::Transaction,
            "42501" | "42601" | "42703" | "42704" | "42710" | "42883" | "42P01" | "42P07" => {
                ErrorKind::Syntax
            }
            "53P00" | "53100" | "53200" | "53300" => ErrorKind::Resource,
            "54000" => ErrorKind::Limit,
            "57014" | "57P01" | "57P03" => ErrorKind::OperatorIntervention,
            "58000" => ErrorKind::System,
            "XX000" => ErrorKind::Internal,
            _ => ErrorKind::Unknown,
        }
    } else {
        ErrorKind::Unknown
    };
    Error::with_sqlstate(kind, message, Some(sqlstate.to_string()), detail, hint)
}
