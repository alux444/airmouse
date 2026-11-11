# AirPointer motion helper

`CaseSustainedRenewal.m` is copied without modification from [AirPointer](https://github.com/oscarcreatess/airpointer) at commit `7f44e6437aaab48ee7af26a16d2b90dd6a3ab4d9`. Its MIT licence is in this directory.

AirMouse uses this helper only for an experimental open-case sensor test. The caller must never send its `closed_confirmed` phase: that phase initiates the reference implementation's case diagnostic keepalive. The helper reconnects the AirPods and writes undocumented connection settings whose previous values cannot be read back.
