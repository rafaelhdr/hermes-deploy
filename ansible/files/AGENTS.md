# Grocery List

The household grocery list is a plain file at:
/home/hermes/hermes-grocery/grocery.md

It is the single source of truth — NOT your conversation memory. Always read
the file before changing it, and write changes back immediately.

## Understand these in plain language (no commands needed)
- Adding: "we need milk", "we're out of potatoes", "add eggs", "pick up bread"
  → append the item as a new line if it isn't already there.
- Removing: "got the milk", "bought potatoes", "we have eggs now", "cross off bread"
  → delete the matching line (match loosely, case-insensitive).
- Showing: "what's on the list?", "what do we need?", "read me the list"
  → read the file and show the current items.

## Rules
- One item per line. Keep it tidy.
- Never reorder or rewrite lines you weren't asked to touch.
- If something's already on the list, say so rather than adding a duplicate.
- After any change, confirm in your own voice and show the updated list.
- If the list is empty, say the pantry's well stocked.
