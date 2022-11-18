extern crate tesseract_utils;
extern crate tesseract_client;
extern crate tesseract;
extern crate tesseract_protocol_test;

use tesseract::client::Tesseract;
use tesseract::client::delegate::SingleTransportDelegate;
use tesseract_utils::future_impls::CFutureString;
use tesseract_utils::string::CStringRef;
use tesseract_protocol_test::TestService;
pub use tesseract_utils::*;
pub use tesseract_client::*;
use tesseract_utils::traits::TryAsRef;

use crate::tesseract_utils::ptr::{SyncPtrAsVoid, SyncPtr, SyncPtrAsType};
use std::mem::ManuallyDrop;
use std::sync::Arc;

#[repr(C)]
pub struct AppContextPtr(SyncPtr<Void>);

impl AppContextPtr {
  fn new(ctx: AppContext) -> Self {
    Self(SyncPtr::from(Box::new(ctx)).as_void())
  }

  fn unowned(&self) -> &AppContext {
    self.0.as_ptr_ref::<AppContext>().as_ref()
  }

  fn owned(self) -> Box<AppContext> {
    unsafe { self.0.as_type::<AppContext>().into_box() }
  }
}

struct AppContext {
  service: Arc<dyn tesseract::client::Service<Protocol = tesseract_protocol_test::Test>>,
}

pub struct SExecutor();

#[no_mangle]
pub unsafe extern "C" fn app_init(transport: transport::NativeTransport) -> ManuallyDrop<AppContextPtr> {
  tesseract_utils_init();

  let service = Tesseract::new(SingleTransportDelegate::arc())
    .transport(transport)
    .service(tesseract_protocol_test::Test::Protocol);

  let context = AppContext {
    service
  };

  ManuallyDrop::new(AppContextPtr::new(context))
}

#[no_mangle]
pub unsafe extern "C" fn app_sign_data(
  app: AppContextPtr, data: CStringRef
) -> CFutureString {
  let context = app.unowned();
  let data_str: String = data.try_as_ref().unwrap().into();

  let service = Arc::clone(&context.service);

  let tx = async move {
    service.sign_transaction(&data_str).await
      .map(|str| str.into())
      .map_err(|err| error::CError::ErrorCode(-1, err.to_string().into()))
  };
  
  tx.into()
}

#[no_mangle]
pub unsafe extern "C" fn app_deinit(app: AppContextPtr)  {
  let _ = app.owned();
}