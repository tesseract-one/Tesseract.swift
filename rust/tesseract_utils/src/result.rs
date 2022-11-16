use super::error::CError;

pub type CResult<T> = std::result::Result<T, CError>;

pub trait IntoCResult<T> {
    fn into_cresult(self) -> CResult<T>;
}

pub trait Zip1<T1> {
    fn zip<T2>(self, other: CResult<T2>) -> CResult<(T1, T2)>;
}

impl<T1> Zip1<T1> for CResult<T1> {
    fn zip<T2>(self, other: CResult<T2>) -> CResult<(T1, T2)> {
        self.and_then(|val1| other.map(|val2| (val1, val2)))
    }
}

pub trait Zip2<T1> {
    fn zip2<T2, T3>(self, other1: CResult<T2>, other2: CResult<T3>) -> CResult<(T1, T2, T3)>;
}

impl<T1> Zip2<T1> for CResult<T1> {
    fn zip2<T2, T3>(self, other1: CResult<T2>, other2: CResult<T3>) -> CResult<(T1, T2, T3)> {
        self.zip(other1)
            .and_then(|(val1, val2)| other2.map(|val3| (val1, val2, val3)))
    }
}

pub trait Zip3<T1> {
    fn zip3<T2, T3, T4>(
        self,
        other1: CResult<T2>,
        other2: CResult<T3>,
        other3: CResult<T4>,
    ) -> CResult<(T1, T2, T3, T4)>;
}

impl<T1> Zip3<T1> for CResult<T1> {
    fn zip3<T2, T3, T4>(
        self,
        other1: CResult<T2>,
        other2: CResult<T3>,
        other3: CResult<T4>,
    ) -> CResult<(T1, T2, T3, T4)> {
        self.zip2(other1, other2)
            .and_then(|(val1, val2, val3)| other3.map(|val4| (val1, val2, val3, val4)))
    }
}
