use super::error::CError;
use super::result::Result;
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

pub fn handle_exception<F, R>(func: F) -> Result<R>
where
    F: FnOnce() -> R + panic::UnwindSafe,
{
    handle_exception_result(|| Ok(func()))
}

pub fn handle_exception_result<F, R>(func: F) -> Result<R>
where
    F: FnOnce() -> Result<R> + panic::UnwindSafe,
{
    panic::catch_unwind(func)
        .map_err(|err| CError::Panic(string_from_panic_err(err).into()))
        .and_then(|res| res)
}

#[allow(dead_code)]
pub fn hide_exceptions() {
    panic::set_hook(Box::new(|_| {}));
}
