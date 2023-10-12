use std::mem::ManuallyDrop;
use tesseract_swift_utils::response::CVoidResponse;
use tesseract_swift_transports::error::CTesseractError;

#[repr(C)]
pub enum LogLevel {
    Off,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

pub fn init(level: LogLevel) -> Result<(), CTesseractError> {
    stderrlog::new()
        .verbosity(level as usize)
        .module("TesseractSDK")
        .init()
        .map_err(|_| CTesseractError::Logger("logger init failed".into()))?;
    log_panics::init();
    Ok(())
}

#[no_mangle]
pub extern "C" fn tesseract_sdk_init(log: LogLevel, error: &mut ManuallyDrop<CTesseractError>) -> bool {
    init(log).response(error)
}