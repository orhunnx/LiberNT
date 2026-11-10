# Ordinary OID source regression

`ndis_oid` compiles production `60filter.c` and `oidqueue.h`. It mocks kernel
allocation, rundown, spinlock/IRQL and NDIS I/O work scheduling boundaries.
Its 16 cases check serialization at each receiving filter and miniport,
PASSIVE miniport dispatch, synchronous and inline completion, queued and
active cancellation, callback lifetime, clone freeing, allocation/rundown
failures and adapter closing before worker dispatch.

The cancellation/retirement case completes the selected filter request at
the exact unlock between selecting its frame and looking up its stage.
The prepublication case cancels a frame before queue admission. Another case
cancels from a filter completion callback which retains the request.
These are controlled interleavings; the fixture does not implement actual
parallel threads or prove hardware behavior.

The contracts come from Microsoft documentation:

- [MiniportOidRequest](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ndis/nc-ndis-miniport_oid_request): ordinary miniport requests are serialized and run at PASSIVE_LEVEL.
- [FilterOidRequest](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ndis/nc-ndis-filter_oid_request): a filter receives one ordinary request at a time until completion.
- [MiniportCancelOidRequest](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ndis/nc-ndis-miniport_cancel_oid_request): cancellation identifies the pending request by RequestId.
- [NdisQueueIoWorkItem](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ndis/nf-ndis-ndisqueueioworkitem): device-associated PASSIVE work.

Reuse the existing build directories:

```sh
CCACHE_DISABLE=1 ninja -C output-Clang-amd64-debug ndis_oid ndis_reset ndis
CCACHE_DISABLE=1 ninja -C output-Clang-arm64-debug ndis_oid ndis_reset ndis
```

Run the same executable and retain named checks, exit code and SHA256:

```bat
ndis_oid.exe > ndis-oid-unit.txt 2>&1
echo %ERRORLEVEL%
```

`install-debug-drivers.cmd install-oid` requires both NDIS source fixtures to
pass before replacing `ndis.sys`. It verifies the copied bytes with `fc.exe`,
preserves the current driver as `ndis.sys.libernt-oid-backup` and leaves earlier
backup names intact. `rollback-oid` restores this version while retaining the
rejected driver. Existing backup/rejected names prevent repeated replacement.

`output-tools/ndis-oid.json` records host source checks and artifact hashes;
`output-tools/wifi-connect-live.json` records the original hardware wait.
Windows 11 execution remains deferred by the maintainer; source-fixture
success is not Windows 11 parity. Real boot and Wi-Fi reconnection remain
required to establish whether this fixes the observed pending CONNECT.
The exact vendor reason for the missing completion remains INFO_NEEDED.

Traversal bookkeeping is private to this implementation. It does not alter
Windows-mirrored structures or claim that its private queue layout matches
Windows. The modern miniport OID layout gap remains recorded in the live
investigation report.

## Recorded hardware validation

The final fixture passed 667 named checks in 16 cases. The AMD64 machine's
captured installer output matched the host's ordered per-check results. With
the new OID worker loaded, disconnect/reconnect restored the secure link and
the user confirmed responsive windows and working Internet access. AMD64 and
ARM64 builds completed. This fixture uses user-mode kernel-boundary mocks;
it does not establish Windows 11 parity or exhaustive race freedom.

A later Intel recovery-path STOP 0xF after debugger resume remains
INFO_NEEDED. Source review found no confirmed connection to this delta;
its cause is open and is not attributed to a vendor or the debugger.
