extern crate async_trait;
extern crate tesseract;
extern crate tesseract_protocol_test;
extern crate tesseract_swift_transports;
extern crate tesseract_swift_utils;

pub mod delegate;

use delegate::{AlertProvider, TransportDelegate};
use tesseract::client::Tesseract;
pub use tesseract_swift_transports::error::IntoCError;
pub use tesseract_swift_transports::client::*;
use tesseract_protocol_test::TestService;
use tesseract_swift_utils::future_impls::CFutureString;
use tesseract_swift_utils::string::CStringRef;
use tesseract_swift_utils::traits::TryAsRef;
use tesseract_swift_utils::ptr::SyncPtr;
pub use tesseract_swift_utils::*;

use std::mem::ManuallyDrop;
use std::sync::Arc;

#[repr(C)]
pub struct AppContextPtr(SyncPtr<Void>);

impl AppContextPtr {
    fn new(ctx: AppContext) -> Self {
        Self(SyncPtr::new(ctx).as_void())
    }

    unsafe fn unowned(&self) -> &AppContext {
        self.0.as_typed_ref().unwrap()
    }

    unsafe fn owned(&mut self) -> AppContext {
        self.0.take_typed()
    }
}

struct AppContext {
    service: Arc<dyn tesseract::client::Service<Protocol = tesseract_protocol_test::Test>>,
}

#[no_mangle]
pub unsafe extern "C" fn app_init(
    alerts: AlertProvider,
    transport: ClientTransport,
) -> ManuallyDrop<AppContextPtr> {
    tesseract_utils_init();

    let tesseract = Tesseract::new(TransportDelegate::arc(alerts)).transport(transport);

    let service = tesseract.service(tesseract_protocol_test::Test::Protocol);

    let context = AppContext { service };

    ManuallyDrop::new(AppContextPtr::new(context))
}

#[no_mangle]
pub unsafe extern "C" fn app_sign_data(
    app: AppContextPtr,
    data: CStringRef,
) -> ManuallyDrop<CFutureString> {
    let context = app.unowned();
    let data_str: String = data.try_as_ref().unwrap().into();

    let service = Arc::clone(&context.service);

    let tx = async move {
        service
            .sign_transaction(&data_str)
            .await
            .map(|str| str.into())
            .map_err(|err| err.into_cerror())
    };

    ManuallyDrop::new(tx.into())
}

#[no_mangle]
pub unsafe extern "C" fn app_deinit(app: &mut AppContextPtr) {
    let _ = app.owned();
}
