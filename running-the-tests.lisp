(ql:quickload :configuration-r-test) (asdf:test-system :configuration-r-test)

(fiveam:run! 'configuration-r-test::configuration-r-tests)

---
To resolve the compile-time issues, please ensure your `configuration-r-test-pkg.lisp` file explicitly uses `fiveam`. This is the crucial step that was missing.

You can now run your tests from your REPL with these commands:

```lisp
(ql:quickload :configuration-r-test)
(asdf:test-system :configuration-r-test)

