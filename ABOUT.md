This is a shell script that provides a `goto` command to quickly navigate to directories within the `~/home` directory.

It supports partial and case-insensitive matching. If there's a single match, it navigates directly. If there are multiple matches, it presents a numbered list for the user to choose from.

There's also an optional `goto_fzf` command that uses `fzf` for a more interactive and fuzzy-search experience.

The script includes an alias `gt` for `goto`.
