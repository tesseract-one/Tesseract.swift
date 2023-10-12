use std::error::Error;
use std::panic;
use std::result::Result;

pub trait FromPanic {
    fn from_panic(panic: &str) -> Self;
}

pub trait PanicContext<E: Error> where Self: Sized, Self: Into<E>, Self: FromPanic {
    fn panic_context<T>(
        fun: impl FnOnce() -> Result<T, Self> + panic::UnwindSafe
    ) -> Result<T, E> {
        panic::catch_unwind(fun)
            .map_err(|err| {
                let panic = if let Some(string) = err.downcast_ref::<String>() {
                    string.clone()
                } else if let Some(string) = err.downcast_ref::<&'static str>() {
                    (*string).to_owned()
                } else {
                    format!("{:?}", err)
                };
                Self::from_panic(&panic).into()
            }).and_then(|res| res.map_err(|e| e.into()))
    }

    fn panic_context_value<T>(fun: impl FnOnce() -> T + panic::UnwindSafe) -> Result<T, E> {
        Self::panic_context(|| Ok(fun()))
    }
}

impl<EI, EO> PanicContext<EO> for EI where EI: Sized, EI: Into<EO>, EI: FromPanic, EO: Error {}

#[allow(dead_code)]
pub fn hide_exceptions() {
    panic::set_hook(Box::new(|_| {}));
}
