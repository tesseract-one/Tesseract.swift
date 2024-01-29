use std::mem::ManuallyDrop;
use errorcon::convertible::ErrorContext;
use stderrlog::LogLevelNum;

use tesseract_swift::error::TesseractSwiftError;
use tesseract_swift::utils::{response::CVoidResponse, error::CError};

#[repr(C)]
pub enum LogLevel {
    Off,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

impl From<LogLevel> for LogLevelNum {
    fn from(value: LogLevel) -> Self {
        match value {
            LogLevel::Off => LogLevelNum::Off,
            LogLevel::Error => LogLevelNum::Error,
            LogLevel::Warn => LogLevelNum::Warn,
            LogLevel::Info => LogLevelNum::Info,
            LogLevel::Debug => LogLevelNum::Debug,
            LogLevel::Trace => LogLevelNum::Trace
        }
    }
}

pub fn init(level: LogLevel) -> Result<(), TesseractSwiftError> {
    stderrlog::new()
        .verbosity(level)
        .show_module_names(true)
        .init()?;
    log_panics::init();
    Ok(())
}

#[no_mangle]
pub extern "C" fn tesseract_sdk_init(log: LogLevel, error: &mut ManuallyDrop<CError>) -> bool {
    TesseractSwiftError::context(|| init(log)).response(error)
}