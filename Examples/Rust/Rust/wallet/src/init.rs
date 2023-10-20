use std::sync::atomic::{AtomicBool, Ordering};
use log::LogLevel;
use tesseract_swift_transports::error::TesseractSwiftError;

static INITIALIZED: AtomicBool = AtomicBool::new(false);

pub (super) fn init(level: LogLevel) -> Result<(), TesseractSwiftError> {
    if !INITIALIZED.swap(true, Ordering::Relaxed) {
        stderrlog::new()
            .verbosity(level as usize)
            .module("Wallet")
            .init()?;
        log_panics::init();
        Ok(())
    } else { Ok(()) }
}