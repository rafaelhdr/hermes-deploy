# Grocery List

The household provisions are kept in a single file at:
/home/hermes/hermes-grocery/grocery.md

It has two sections, marked by headings:
- `## Grocery` — things that need buying
- `## Storeroom` — things already in the root cellar (reserves)

The file is the single source of truth — NOT your conversation memory. Always
read the file before changing it, and write changes back immediately.

## Understand these in plain language (no commands needed)

### Adding to the grocery list (default: "add milk", "we need potatoes")
- Read the file first.
- Check the Storeroom section. If the item is already there, warn the user:
  *"Hold on — we've got [item] in the storeroom already. Is it really there?"*
- Wait for the user to confirm. When they confirm they're taking it from the
  storeroom: remove the line from `## Storeroom` and append it under
  `## Grocery` (so they buy a replacement for the cellar).
- If the item is NOT in the storeroom, just append it under `## Grocery`.
- If it's already under `## Grocery`, say so rather than adding a duplicate.

### Adding to the storeroom ("add rice to storeroom", "put flour in the cellar")
- Read the file first.
- Append the item under `## Storeroom`.
- If it's already there, say so.

### Using from the storeroom ("use rice from storeroom", "I took pasta from the cellar")
- Read the file first.
- If the item is under `## Storeroom`: remove it from there and append it
  under `## Grocery` (they'll need to buy more to restock).
- If it's not there, let them know.

### Removing ("got the milk", "bought bread", "cross off eggs")
- Read the file first.
- Delete the matching line from whichever section it's in (match loosely,
  case-insensitive).
- Don't remove items from storeroom unless explicitly asked — removing means
  "I bought this" / "I got this", which only applies to the grocery section.

### Showing ("what's on the list?", "read me the list", "what's in the storeroom?")
- Read the file and show the current items, keeping the sections together.

## If the file doesn't exist or is empty, initialise it with:
```
## Grocery

## Storeroom
```

## Rules
- One item per line under its section. Keep it tidy.
- Never reorder or rewrite lines you weren't asked to touch.
- After any change, confirm in your own voice and show what you changed.
- If both sections are empty, say the pantry's well stocked.
- When in doubt, the default list is Grocery — "add X" means the grocery list,
  not the storeroom.
