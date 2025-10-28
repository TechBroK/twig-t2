# Dashboard Testing Guide

## Prerequisites
Start the development server:
```powershell
cd C:\Users\HomePC\Development\Twig_t2
php -S localhost:9000 -t src
```

Log in at http://localhost:9000/auth/login with:
- Username: `demo`
- Password: `demo`

You'll be redirected to: http://localhost:9000/dashboard

---

## Test Scenario 1: Create a Ticket ✅

**Steps:**
1. Fill in the form:
   - **Title**: "Fix login bug"
   - **Status**: Select "Open"
   - **Description**: "Users can't log in with special characters"
2. Click **"Create Ticket"**

**Expected Results:**
- ✅ Green toast notification appears: "Ticket created"
- ✅ Form clears automatically
- ✅ New ticket card appears in the list below
- ✅ **Stats update**: Total = 1, Open = 1
- ✅ Ticket card shows:
  - Title: "Fix login bug"
  - Blue "OPEN" badge
  - Description text
  - "Edit" and "Delete" buttons

---

## Test Scenario 2: Create Multiple Tickets 📊

**Steps:**
1. Create a second ticket:
   - Title: "Add dark mode"
   - Status: "In Progress"
   - Description: "Implement dark theme toggle"
2. Create a third ticket:
   - Title: "Update docs"
   - Status: "Resolved"
   - Description: "API documentation needs update"

**Expected Results:**
- ✅ Stats show: Total = 3, Open = 1, In Progress = 1, Resolved = 1
- ✅ Three ticket cards visible in grid
- ✅ Each has correct colored status badge:
  - Open = Blue
  - In Progress = Yellow
  - Resolved = Green

---

## Test Scenario 3: Edit a Ticket ✏️

**Steps:**
1. Click **"Edit"** button on the "Fix login bug" ticket
2. Observe the form

**Expected Results:**
- ✅ Blue toast: "Editing ticket"
- ✅ Page scrolls to form smoothly
- ✅ Form populates with ticket data:
  - Title field = "Fix login bug"
  - Status dropdown = "Open"
  - Description = "Users can't log in with special characters"
- ✅ Submit button text changes to **"Update Ticket"**

**Steps (continued):**
3. Change Status to "In Progress"
4. Add to description: " - investigating root cause"
5. Click **"Update Ticket"**

**Expected Results:**
- ✅ Green toast: "Ticket updated"
- ✅ Button changes back to "Create Ticket"
- ✅ Form clears
- ✅ Ticket card updates:
  - Status badge now shows "IN PROGRESS" (yellow)
  - Description includes new text
- ✅ Stats update: Open = 0, In Progress = 2

---

## Test Scenario 4: Validation ⚠️

**Steps:**
1. Leave Title empty
2. Click "Create Ticket"

**Expected Results:**
- ✅ Red error message appears below Title field: "Title is required"
- ✅ No ticket created
- ✅ No toast notification

**Steps (continued):**
3. Enter a title: "Test validation"
4. Leave Status as "Select status" (empty)
5. Click "Create Ticket"

**Expected Results:**
- ✅ Red error below Status: "Please select a valid status"
- ✅ Title error clears (no longer shown)
- ✅ No ticket created

---

## Test Scenario 5: Clear/Reset Form 🔄

**Steps:**
1. Click "Edit" on any ticket (form populates)
2. Modify some fields
3. Click **"Clear"** button

**Expected Results:**
- ✅ All form fields clear
- ✅ Button text returns to "Create Ticket"
- ✅ Form exits edit mode (no longer editing)
- ✅ All error messages clear
- ✅ Creating a new ticket now works (not updating the edited one)

---

## Test Scenario 6: Delete a Ticket 🗑️

**Steps:**
1. Click **"Delete"** on the "Update docs" ticket
2. Browser shows confirmation dialog: "Are you sure you want to delete this ticket?"
3. Click **OK**

**Expected Results:**
- ✅ Green toast: "Ticket deleted"
- ✅ Ticket card removed from list
- ✅ Stats update: Total = 2, Resolved = 0
- ✅ Remaining tickets still visible

**Steps (continued - cancel delete):**
4. Click "Delete" on another ticket
5. Click **Cancel** in confirmation

**Expected Results:**
- ✅ No toast
- ✅ Ticket remains in list
- ✅ Stats unchanged

---

## Test Scenario 7: Empty State 📋

**Steps:**
1. Delete all tickets one by one
2. Observe the ticket list area

**Expected Results:**
- ✅ Stats show: Total = 0, Open = 0, In Progress = 0, Resolved = 0
- ✅ Ticket list shows centered message:
  "No tickets yet. Create one above to get started."
- ✅ Form still works to create first ticket

---

## Test Scenario 8: Toast Notifications 🔔

**Expected behavior (verify throughout testing):**
- ✅ Toasts appear bottom-right corner
- ✅ Slide in from right with smooth animation
- ✅ Auto-dismiss after ~3.5 seconds
- ✅ Fade out smoothly when dismissing
- ✅ Multiple toasts stack vertically
- ✅ Color-coded borders:
  - Info (editing) = Blue border
  - Success (created/updated/deleted) = Green border
  - Error (validation/not found) = Red border

---

## Test Scenario 9: Responsive Design 📱

**Steps:**
1. Resize browser to mobile width (< 768px)

**Expected Results:**
- ✅ Stats cards stack vertically
- ✅ Ticket list becomes single column
- ✅ Form remains usable
- ✅ Buttons stack appropriately
- ✅ All text remains readable

---

## Test Scenario 10: Data Persistence 💾

**Steps:**
1. Create 2-3 tickets
2. Refresh the page (F5)
3. Navigate away to /tickets then back to /dashboard

**Expected Results:**
- ✅ All tickets persist (stored in localStorage)
- ✅ Stats remain accurate
- ✅ Ticket order preserved
- ✅ All ticket data intact (title, status, description)

---

## Troubleshooting 🔧

**If tickets don't appear:**
- Open browser DevTools (F12) → Console
- Check for JavaScript errors
- Verify localStorage: `localStorage.getItem('ticketapp_tickets')`

**If stats don't update:**
- Check that IDs match: `total-count`, `open-count`, `inprogress-count`, `resolved-count`
- Verify tickets have valid status values: `open`, `in_progress`, `closed`

**If form doesn't submit:**
- Check console for errors
- Verify form has `id="ticket-form"`
- Ensure inputs have correct IDs

**Clear all data (reset):**
```javascript
// Run in browser console:
localStorage.clear();
location.reload();
```

---

## Success Criteria ✨

All scenarios should pass with:
- ✅ Smooth animations
- ✅ Clear user feedback (toasts)
- ✅ Proper validation
- ✅ Data persistence
- ✅ Stats accuracy
- ✅ Professional appearance
- ✅ Responsive layout
- ✅ No console errors
