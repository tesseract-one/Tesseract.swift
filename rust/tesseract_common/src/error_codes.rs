
#[repr(u32)]
#[derive(Debug, Clone, Copy)]
pub enum CErrorCodes {
  EmptyRequest = 0,
  EmptyResponse,
  UnsupportedDataType,
  RequestExpired,
  WrongProtocolId,
  WrongInternalState
}
