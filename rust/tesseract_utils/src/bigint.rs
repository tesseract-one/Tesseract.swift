use super::array::CArray;
use super::error::CError;
use super::result::CResult;
use super::traits::{QuickClone, TryAsRef};
use num_bigint::{BigInt, Sign};
use std::convert::TryFrom;
use std::mem::ManuallyDrop;

#[repr(C)]
#[derive(Copy, Clone)]
pub enum CBigIntSign {
    Minus,
    NoSign,
    Plus,
}

impl From<CBigIntSign> for Sign {
    fn from(sign: CBigIntSign) -> Self {
        match sign {
            CBigIntSign::Minus => Self::Minus,
            CBigIntSign::NoSign => Self::NoSign,
            CBigIntSign::Plus => Self::Plus,
        }
    }
}

impl From<Sign> for CBigIntSign {
    fn from(sign: Sign) -> Self {
        match sign {
            Sign::Minus => Self::Minus,
            Sign::NoSign => Self::NoSign,
            Sign::Plus => Self::Plus,
        }
    }
}

#[repr(C)]
pub struct CBigInt {
    sign: CBigIntSign,
    data: CArray<u32>,
}

impl Clone for CBigInt {
    fn clone(&self) -> Self {
        Self {
            sign: self.sign,
            data: self.data.quick_clone(),
        }
    }
}

impl TryFrom<CBigInt> for BigInt {
    type Error = CError;
    fn try_from(big_int: CBigInt) -> CResult<Self> {
        let digits = big_int.data.try_as_ref()?;
        Ok(Self::from_slice(big_int.sign.into(), digits))
    }
}

impl From<BigInt> for CBigInt {
    fn from(big_int: BigInt) -> Self {
        Self {
            sign: big_int.sign().into(),
            data: big_int.magnitude().to_u32_digits().into(),
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_big_int_free(big_int: &mut ManuallyDrop<CBigInt>) {
    ManuallyDrop::drop(big_int);
}
