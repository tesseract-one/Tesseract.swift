pub mod array;
pub mod data;
pub mod error;
pub mod future;
pub mod future_impls;
pub mod int128;
pub mod option;
pub mod panic;
pub mod ptr;
pub mod response;
pub mod result;
pub mod string;
pub mod traits;

#[cfg(feature = "bigint")]
extern crate num_bigint;
#[cfg(feature = "bigint")]
pub mod bigint;

pub type Void = std::ffi::c_void;

#[no_mangle]
pub unsafe extern "C" fn tesseract_utils_init() {
    panic::hide_exceptions();
}
