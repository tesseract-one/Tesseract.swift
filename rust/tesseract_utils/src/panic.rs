use super::error::CError;
use super::result::{CResult, IntoCResult};
use std::any::Any;
use std::panic;

fn string_from_panic_err(err: Box<dyn Any>) -> String {
    if let Some(string) = err.downcast_ref::<String>() {
        string.clone()
    } else if let Some(string) = err.downcast_ref::<&'static str>() {
        String::from(*string)
    } else {
        format!("Reason: {:?}", err)
    }
}

impl<T> IntoCResult<T> for std::result::Result<T, Box<dyn Any + Send + 'static>> {
    fn into_cresult(self) -> CResult<T> {
        self.map_err(|err| CError::Panic(string_from_panic_err(err).into()))
    }
}

impl<T> IntoCResult<T> for std::result::Result<T, Box<dyn Any + 'static>> {
    fn into_cresult(self) -> CResult<T> {
        self.map_err(|err| CError::Panic(string_from_panic_err(err).into()))
    }
}

impl<T, E> IntoCResult<T> for std::result::Result<T, E>
where
    E: Into<CError>,
{
    fn into_cresult(self) -> CResult<T> {
        self.map_err(|err| err.into())
    }
}

#[allow(dead_code)]
pub fn handle_exception<F: FnOnce() -> R + panic::UnwindSafe, R>(func: F) -> CResult<R> {
    handle_exception_result(|| Ok(func()))
}

pub fn handle_exception_result<F: FnOnce() -> CResult<R> + panic::UnwindSafe, R>(
    func: F,
) -> CResult<R> {
    panic::catch_unwind(func).into_cresult().and_then(|res| res)
}

#[allow(dead_code)]
pub fn hide_exceptions() {
    panic::set_hook(Box::new(|_| {}));
}
