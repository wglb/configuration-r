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
    (fiveam:is-false (get-config nonexistent-file-path :property :debug t)
                     "GET-CONFIG should return NIL for a non-existent file.")

    ;; Test GET-CONFIG1 with a non-existent file
    (fiveam:is-false (get-config1 nonexistent-file-name :property :debug t)
                     "GET-CONFIG1 should return NIL for a non-existent file.")))

(fiveam:test basic-config-retrieval
  "Tests that GET-CONFIG retrieves a basic property from a known file."
  (let* ((test-file (merge-pathnames "config.lisp" *test-temp-dir*))
         (expected-value "value-from-root"))
    (fiveam:is (equal expected-value (get-config test-file :test-prop-1 :debug t))
               "GET-CONFIG should retrieve the correct value from config.lisp.")))

(fiveam:test find-file-in-parent-basic
  "Tests that FIND-FILE-IN-PARENT correctly locates a file in a parent directory."
  (let* ((start-dir (merge-pathnames "subdir/nested-subdir/" *test-temp-dir*))
         (target-file "config.lisp"))
    (fiveam:is-true (probe-file (find-file-in-parent start-dir target-file))
                    "FIND-FILE-IN-PARENT should find the file up the directory tree.")))

(fiveam:test get-config-with-relative-path
  "Tests that GET-CONFIG correctly finds a file from a relative path."
  (let* ((relative-path (merge-pathnames "subdir/nested-subdir/any-file.lisp" *test-temp-dir*)))
    (fiveam:is (equal "value-from-parent-subdir" (get-config relative-path :test-prop-2 :debug t))
               "GET-CONFIG should find the config file in a parent directory.")))

(fiveam:test get-config-with-absolute-path
  "Tests that GET-CONFIG works with an absolute path."
  (let* ((absolute-path (merge-pathnames "config.lisp" *test-temp-dir*)))
    (fiveam:is (equal "value-from-root" (get-config absolute-path :test-prop-1 :debug t))
               "GET-CONFIG should work correctly with an absolute file path.")))

(fiveam:test get-config1-correct-behavior
  "Tests that GET-CONFIG1 correctly retrieves a property from a file in the specified directory."
  (let* ((target-file (merge-pathnames "subdir/config-subdir.lisp" *test-temp-dir*)))
    (fiveam:is (equal "value-from-subdir" (get-config1 target-file :test-prop-3 :debug t))
               "GET-CONFIG1 should correctly find the file and retrieve the value.")))

(fiveam:test get-config-with-multiple-levels
  "Tests that GET-CONFIG can find a file that is multiple levels up from the initial directory."
  (let* ((start-dir (merge-pathnames "subdir/nested-subdir/deeply-nested/" *test-temp-dir*))
         (target-file (merge-pathnames "config.lisp" start-dir)))
    (fiveam:is (equal "value-from-root" (get-config target-file :test-prop-1 :debug t))
               "GET-CONFIG should find the file at the root of the test directory.")))

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
    (fiveam:is-false (get-config nonexistent-file-path :property :debug t)
                     "GET-CONFIG should return NIL for a non-existent file.")

    ;; Test GET-CONFIG1 with a non-existent file
    (fiveam:is-false (get-config1 nonexistent-file-name :property :debug t)
                     "GET-CONFIG1 should return NIL for a non-existent file.")))

(fiveam:test basic-config-retrieval
  "Tests that GET-CONFIG retrieves a basic property from a known file."
  (let* ((test-file (merge-pathnames "config.lisp" *test-temp-dir*))
         (expected-value "value-from-root"))
    (fiveam:is (equal expected-value (get-config test-file :test-prop-1 :debug t))
               "GET-CONFIG should retrieve the correct value from config.lisp.")))

(fiveam:test find-file-in-parent-basic
  "Tests that FIND-FILE-IN-PARENT correctly locates a file in a parent directory."
  (let* ((start-dir (merge-pathnames "subdir/nested-subdir/" *test-temp-dir*))
         (target-file "config.lisp"))
    (fiveam:is-true (probe-file (find-file-in-parent start-dir target-file))
                    "FIND-FILE-IN-PARENT should find the file up the directory tree.")))

(fiveam:test get-config-with-relative-path
  "Tests that GET-CONFIG correctly finds a file from a relative path."
  (let* ((relative-path (merge-pathnames "subdir/nested-subdir/any-file.lisp" *test-temp-dir*)))
    (fiveam:is (equal "value-from-parent-subdir" (get-config relative-path :test-prop-2 :debug t))
               "GET-CONFIG should find the config file in a parent directory.")))

(fiveam:test get-config-with-absolute-path
  "Tests that GET-CONFIG works with an absolute path."
  (let* ((absolute-path (merge-pathnames "config.lisp" *test-temp-dir*)))
    (fiveam:is (equal "value-from-root" (get-config absolute-path :test-prop-1 :debug t))
               "GET-CONFIG should work correctly with an absolute file path.")))

(fiveam:test get-config1-correct-behavior
  "Tests that GET-CONFIG1 correctly retrieves a property from a file in the specified directory."
  (let* ((target-file (merge-pathnames "subdir/config-subdir.lisp" *test-temp-dir*)))
    (fiveam:is (equal "value-from-subdir" (get-config1 target-file :test-prop-3 :debug t))
               "GET-CONFIG1 should correctly find the file and retrieve the value.")))

(fiveam:test get-config-with-multiple-levels
  "Tests that GET-CONFIG can find a file that is multiple levels up from the initial directory."
  (let* ((start-dir (merge-pathnames "subdir/nested-subdir/deeply-nested/" *test-temp-dir*))
         (target-file (merge-pathnames "config.lisp" start-dir)))
    (fiveam:is (equal "value-from-root" (get-config target-file :test-prop-1 :debug t))
               "GET-CONFIG should find the file at the root of the test directory.")))
