use crate::error::CError;
use crate::result::Result;

#[repr(C)]
#[derive(Debug, Clone)]
pub enum CFutureValue<V> {
    None,
    Value(V),
    Error(CError),
}

impl<V> From<Result<V>> for CFutureValue<V> {
    fn from(result: Result<V>) -> Self {
        match result {
            Err(err) => Self::Error(err),
            Ok(val) => Self::Value(val),
        }
    }
}

impl<V> From<Option<Result<V>>> for CFutureValue<V> {
    fn from(option: Option<Result<V>>) -> Self {
        match option {
            None => Self::None,
            Some(result) => match result {
                Err(err) => Self::Error(err),
                Ok(val) => Self::Value(val),
            },
        }
    }
}

impl<V> From<CFutureValue<V>> for Option<Result<V>> {
    fn from(value: CFutureValue<V>) -> Self {
        match value {
            CFutureValue::None => None,
            CFutureValue::Error(err) => Some(Err(err)),
            CFutureValue::Value(val) => Some(Ok(val)),
        }
    }
}
