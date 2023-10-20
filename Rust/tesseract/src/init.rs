use std::mem::ManuallyDrop;
use errorcon::convertible::ErrorContext;
use tesseract_swift_utils::{response::CVoidResponse, error::CError};
use tesseract_swift_transports::error::TesseractSwiftError;

#[repr(C)]
pub enum LogLevel {
    Off,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

pub fn init(level: LogLevel) -> Result<(), TesseractSwiftError> {
    stderrlog::new()
        .verbosity(level as usize)
        .module("TesseractSDK")
        .init()?;
    log_panics::init();
    Ok(())
}

#[no_mangle]
pub extern "C" fn tesseract_sdk_init(log: LogLevel, error: &mut ManuallyDrop<CError>) -> bool {
    TesseractSwiftError::context(|| {
        init(log)
    }).response(error)
}