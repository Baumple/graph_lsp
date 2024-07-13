pub type SafeOptions {
  SafeOptions
  Bool(Bool)
}
pub type TextDocumentSyncOption {
  TextDocumentSyncOption(
    open_close: Option(Bool),
    change: Option(Bool),
    will_save: Option(Bool),
    will_save_wait_until: Option(Bool),
    save: Option(SafeOptions)
  )
}
