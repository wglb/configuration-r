* CHANGELOG

** 2025-07-29

*** Added
- *Comprehensive Test Suite:* Introduced a dedicated ASDF test system
  (`configuration-r-test`) using `fiveam` to ensure the library's functionality and
  prevent regressions. This includes:
  - Setup and teardown routines for creating and cleaning up temporary configuration
    files.
  - Tests for `find-file-in-parent`, `get-config0`, `get-config`, and `get-config1`.

*** Changed
- *Improved Pathname Handling Consistency:*
  - The internal functions (`get-config0`, `find-file-in-parent0`) now consistently
    operate on and expect `pathname` objects, reducing type errors and improving
    robustness across different Common Lisp implementations and operating systems
    (e.g., macOS's `/var` vs. `/private/var` paths).
  - Comparisons of pathnames now utilize `uiop:pathname-equal` for canonical and
    reliable results.

- *More Robust Directory Traversal:*
  - The recursive logic in `get-config0` and `find-file-in-parent0` includes more
    explicit and reliable termination conditions to prevent infinite loops when
    traversing up the file system hierarchy (e.g., at the root directory).

- *`get-config` Default Directory Behavior:*
  - When the `:dir` argument is `NIL`, `get-config` now defaults to using
    `(uiop:getcwd)` (current working directory as a pathname object) as its starting
    point for configuration file searches, providing a more predictable default than
    `*default-pathname-defaults*`.

- *`find-file-in-parent` Home Directory Fallback:*
  - The fallback mechanism for `find-file-in-parent` now uses `(user-homedir-pathname)`
    for a more robust and portable way to locate the user's home directory.

- *`get-config1` Functional Behavior:*
  - While retaining its original "problematic" comment (as its design might still be
    less ideal than `get-config`), `get-config1` has become functionally correct for
    the tested cases due to the underlying improvements in `get-config0` and general
    pathname handling. Its behavior is now more predictable.

*** Fixed
- Resolved multiple `TYPE-ERROR`s related to incorrect pathname argument types in `uiop`
  functions and internal library calls.
- Corrected a persistent closing parenthesis error in `get-config0`.
- Fixed "undefined variable" warnings in test files by ensuring proper ASDF component
  loading order and package definitions.
- Addressed FiveAM version compatibility issues by adapting test setup/teardown mechanisms.
