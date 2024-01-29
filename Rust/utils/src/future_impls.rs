use crate::data::CData;
use crate::future::CFuture;
use crate::int128::{CInt128, CUInt128};
use crate::ptr::{CAnyDropPtr, CAnyRustPtr};
use crate::string::CString;
use crate::Nothing;

pub type CFutureNothing = CFuture<Nothing>;
pub type CFutureString = CFuture<CString>;
pub type CFutureData = CFuture<CData>;
pub type CFutureAnyRustPtr = CFuture<CAnyRustPtr>;
pub type CFutureAnyDropPtr = CFuture<CAnyDropPtr>;

pub type CFutureInt8 = CFuture<i8>;
pub type CFutureUInt8 = CFuture<u8>;
pub type CFutureInt16 = CFuture<i16>;
pub type CFutureUInt16 = CFuture<u16>;
pub type CFutureInt32 = CFuture<i32>;
pub type CFutureUInt32 = CFuture<u32>;
pub type CFutureInt64 = CFuture<i64>;
pub type CFutureUInt64 = CFuture<u64>;
pub type CFutureBool = CFuture<bool>;
pub type CFutureInt128 = CFuture<CInt128>;
pub type CFutureUInt128 = CFuture<CUInt128>;
