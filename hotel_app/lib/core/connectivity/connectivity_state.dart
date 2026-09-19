/// The three states the "Sync" control cares about. `offline` hides the
/// sync action entirely (nothing to tap that would just fail); `online`
/// means the device has real internet and syncing may be attempted.
enum ConnectivityState { offline, online, checking }
