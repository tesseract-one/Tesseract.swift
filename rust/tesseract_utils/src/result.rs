use crate::Nothing;
use super::error::CError;

pub type Result<T> = std::result::Result<T, CError>;

#[repr(C)]
#[derive(Debug, Clone)]
pub enum CResult<V> {
    Ok(V),
    Err(CError)
}

impl<T> From<Result<T>> for CResult<T> {
    fn from(result: Result<T>) -> Self {
        match result {
            Ok(value) => CResult::Ok(value),
            Err(err) => CResult::Err(err),
        }
    }
}

impl From<Result<()>> for CResult<Nothing> {
    fn from(result: Result<()>) -> Self {
        match result {
            Ok(_) => CResult::Ok(Nothing::default()),
            Err(err) => CResult::Err(err),
        }
    }
}

impl<T> From<CResult<T>> for Result<T> {
    fn from(result: CResult<T>) -> Self {
        match result {
            CResult::Ok(value) => Ok(value),
            CResult::Err(err) => Err(err),
        }
    }
}

impl From<CResult<Nothing>> for Result<()> {
    fn from(result: CResult<Nothing>) -> Self {
        match result {
            CResult::Ok(_) => Ok(()),
            CResult::Err(err) => Err(err),
        }
    }
}

pub trait Zip1<T1> {
    fn zip<T2>(self, other: Result<T2>) -> Result<(T1, T2)>;
}

impl<T1> Zip1<T1> for Result<T1> {
    fn zip<T2>(self, other: Result<T2>) -> Result<(T1, T2)> {
        self.and_then(|val1| other.map(|val2| (val1, val2)))
    }
}

pub trait Zip2<T1> {
    fn zip2<T2, T3>(self, other1: Result<T2>, other2: Result<T3>) -> Result<(T1, T2, T3)>;
}

impl<T1> Zip2<T1> for Result<T1> {
    fn zip2<T2, T3>(self, other1: Result<T2>, other2: Result<T3>) -> Result<(T1, T2, T3)> {
        self.zip(other1)
            .and_then(|(val1, val2)| other2.map(|val3| (val1, val2, val3)))
    }
}

pub trait Zip3<T1> {
    fn zip3<T2, T3, T4>(
        self,
        other1: Result<T2>,
        other2: Result<T3>,
        other3: Result<T4>,
    ) -> Result<(T1, T2, T3, T4)>;
}

impl<T1> Zip3<T1> for Result<T1> {
    fn zip3<T2, T3, T4>(
        self,
        other1: Result<T2>,
        other2: Result<T3>,
        other3: Result<T4>,
    ) -> Result<(T1, T2, T3, T4)> {
        self.zip2(other1, other2)
            .and_then(|(val1, val2, val3)| other3.map(|val4| (val1, val2, val3, val4)))
    }
}
