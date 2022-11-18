use super::error::CError;
use super::result::Result;
use super::traits::IntoC;
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

impl<T> IntoC<T> for std::result::Result<T, Box<dyn Any + Send + 'static>> {
    type CVal = Result<T>;

    fn into_c(self) -> Result<T> {
        self.map_err(|err| CError::Panic(string_from_panic_err(err).into()))
    }
}

impl<T> IntoC<T> for std::result::Result<T, Box<dyn Any + 'static>> {
    type CVal = Result<T>;

    fn into_c(self) -> Result<T> {
        self.map_err(|err| CError::Panic(string_from_panic_err(err).into()))
    }
}

impl<T, E> IntoC<T> for std::result::Result<T, E>
where
    E: Into<CError>,
{
    type CVal = Result<T>;

    fn into_c(self) -> Result<T> {
        self.map_err(|err| err.into())
    }
}

#[allow(dead_code)]
pub fn handle_exception<F: FnOnce() -> R + panic::UnwindSafe, R>(func: F) -> Result<R> {
    handle_exception_result(|| Ok(func()))
}

pub fn handle_exception_result<F: FnOnce() -> Result<R> + panic::UnwindSafe, R>(
    func: F,
) -> Result<R> {
    panic::catch_unwind(func).into_c().and_then(|res| res)
}

#[allow(dead_code)]
pub fn hide_exceptions() {
    panic::set_hook(Box::new(|_| {}));
}
