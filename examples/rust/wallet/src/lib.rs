extern crate async_trait;
extern crate tesseract;
extern crate tesseract_protocol_test;
extern crate tesseract_service;
extern crate tesseract_utils;

use async_trait::async_trait;
use std::mem::ManuallyDrop;
use std::sync::Arc;
use tesseract::service::Tesseract;
use tesseract_utils::future_impls::CFutureBool;
use tesseract_utils::ptr::{CAnyDropPtr, SyncPtr};
use tesseract_utils::string::{CString, CStringRef};
use tesseract_utils::tesseract_utils_init;
use tesseract_utils::traits::TryAsRef;
use tesseract_utils::Void;

#[repr(C)]
pub struct AppContextPtr(SyncPtr<Void>);

impl AppContextPtr {
    fn new(ctx: AppContext) -> Self {
        Self(SyncPtr::new(ctx).as_void())
    }

    unsafe fn owned(&mut self) -> AppContext {
        self.0.take_typed()
    }
}

#[repr(C)]
pub struct UI {
    ptr: CAnyDropPtr,
    approve_tx: unsafe extern "C" fn(this: &UI, tx: CStringRef) -> ManuallyDrop<CFutureBool>,
}

struct TestService {
    ui: UI,
    signature: String,
}

impl TestService {
    pub fn new(ui: UI, signature: String) -> Self {
        Self { ui, signature }
    }
}

impl tesseract::service::Service for TestService {
    type Protocol = tesseract_protocol_test::Test;

    fn protocol(&self) -> &tesseract_protocol_test::Test {
        &tesseract_protocol_test::Test::Protocol
    }

    fn to_executor(self) -> Box<dyn tesseract::service::Executor + Send + Sync> {
        Box::new(tesseract_protocol_test::service::TestExecutor::from_service(self))
    }
}

#[async_trait]
impl tesseract_protocol_test::TestService for TestService {
    async fn sign_transaction(self: Arc<Self>, req: &str) -> tesseract::Result<String> {
        let future = unsafe {
            let cstr: CString = req.into();
            ManuallyDrop::into_inner((self.ui.approve_tx)(&self.ui, cstr.as_ptr()))
        };

        let future = future
            .try_into_future()
            .map_err(|err| tesseract::Error::nested(Box::new(err)))?;
        let allow = future
            .await
            .map_err(|err| tesseract::Error::nested(Box::new(err)))?;

        if allow {
            if req == "make_error" {
                Err(tesseract::Error::described(
                    tesseract::ErrorKind::Weird,
                    "intentional error for test",
                ))
            } else {
                Ok(format!("{}{}", req, self.signature))
            }
        } else {
            Err(tesseract::Error::kinded(tesseract::ErrorKind::Cancelled))
        }
    }
}

struct AppContext {
    _tesseract: Tesseract,
}

#[no_mangle]
pub unsafe extern "C" fn wallet_extension_init(
    signature: CStringRef,
    ui: UI,
    transport: tesseract_service::transport::Transport,
) -> ManuallyDrop<AppContextPtr> {
    tesseract_utils_init();

    let service = TestService::new(ui, signature.try_as_ref().unwrap().into());

    let tesseract = Tesseract::new().transport(transport).service(service);

    let context = AppContext {
        _tesseract: tesseract,
    };

    ManuallyDrop::new(AppContextPtr::new(context))
}

#[no_mangle]
pub unsafe extern "C" fn wallet_extension_deinit(app: &mut AppContextPtr) {
    let _ = app.owned();
}
