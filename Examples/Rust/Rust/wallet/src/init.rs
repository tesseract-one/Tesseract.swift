use std::sync::atomic::{AtomicBool, Ordering};
use log::LogLevel;
use tesseract_swift_transports::error::CTesseractError;

static INITIALIZED: AtomicBool = AtomicBool::new(false);

pub (super) fn init(level: LogLevel) -> Result<(), CTesseractError> {
    if !INITIALIZED.swap(true, Ordering::Relaxed) {
        stderrlog::new()
            .verbosity(level as usize)
            .module("Wallet")
            .init()
            .map_err(|_| CTesseractError::Logger("logger init failed".into()))?;
        log_panics::init();
        Ok(())
    } else { Ok(()) }
}