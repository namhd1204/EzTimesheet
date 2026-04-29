## What to build
Implement the daily Google Drive backup mechanism.
- On app launch, check if a backup has been performed today.
- If not, and network is available, trigger a silent backup of the JSON-exported database to Google Drive.
- Show a prominent "Restore Data" button on the main screen if the local database is empty (e.g., after a fresh install).

## Acceptance criteria
- [ ] Automatic daily check for backup.
- [ ] Google Drive integration works (Auth + Upload).
- [ ] Restore button visible and functional on empty state.

## Blocked by
None - can start immediately.
