;;;; main-config-r-test.lisp
(in-package #:configuration-r-test)

(fiveam:def-suite :configuration-r-tests
  :description "Main test suite for configuration-r.")

(fiveam:in-suite :configuration-r-tests)

(fiveam:test nonexistent-file-handling
  "Tests that GET-CONFIG and GET-CONFIG1 return NIL when the file does not exist."
  (let* ((nonexistent-file-path (uiop:merge-pathnames* "non-existent-file.lisp" (uiop:temporary-directory)))
         (nonexistent-file-name (file-namestring nonexistent-file-path)))
    ;; Sanity check to ensure the file really doesn't exist
    (fiveam:is-false (probe-file nonexistent-file-path)
                     "Precondition failed: Temporary non-existent file should not exist.")

    ;; Test GET-CONFIG with a non-existent file
    (fiveam:is-false (get-config nonexistent-file-path :property)
                     "GET-CONFIG should return NIL for a non-existent file.")

    ;; Test GET-CONFIG1 with a non-existent file
    (fiveam:is-false (get-config1 nonexistent-file-name :property)
                     "GET-CONFIG1 should return NIL for a non-existent file.")))

(fiveam:test basic-config-retrieval
  "Tests that GET-CONFIG retrieves a basic property from a known file."
  (let* ((test-file (merge-pathnames "config.lisp" *test-temp-dir*))
         (expected-value "value-from-root"))
    (fiveam:is (equal expected-value (get-config test-file :test-prop-1))
               "GET-CONFIG should retrieve the correct value from config.lisp.")))
