# TODOs

## Priority P2

### Add battery check before critical operations

**What:** Check device battery level before data export/import operations and warn user if battery < 20%.

**Why:** Prevent data loss or corruption if device dies during critical file operations.

**Pros:** Protects user data, improves reliability, prevents frustrating data loss scenarios.

**Cons:** Adds small complexity to export/import flows, requires battery API integration.

**Context:** Current plan handles storage failures and network errors, but doesn't account for device power loss during file operations. This is a gap identified in the CEO review Section 4 (Data Flow & Interaction Edge Cases).

**Effort estimate:** S (human team) → S (with CC+gstack)

**Priority:** P2

**Depends on / blocked by:** None

**Implementation notes:**
- Integrate with Flutter's `battery` package
- Add check before `BackupService#export` and `BackupService#import`
- Show warning dialog: "Cảnh báo: Pin yếu (<20%). Nên sạc pin trước khi xuất/nhập dữ liệu."
- Allow user to proceed with warning (don't block operation)
- Log battery level when check is performed