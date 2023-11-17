use std::sync::atomic::{AtomicBool, Ordering};
use stderrlog::LogLevelNum;
use tesseract_swift_transports::error::TesseractSwiftError;

static INITIALIZED: AtomicBool = AtomicBool::new(false);

pub (super) fn init(level: LogLevelNum) -> Result<(), TesseractSwiftError> {
    if !INITIALIZED.swap(true, Ordering::Relaxed) {
        stderrlog::new()
            .verbosity(level)
            .show_module_names(true)
            .init()?;
        log_panics::init();
        Ok(())
    } else { Ok(()) }
}