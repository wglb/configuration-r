;;;; tests/main.lisp

(in-package #:cl-user)

;; Mock configuration files for testing
;; We'll create these dynamically in a temporary directory for tests
(defparameter *test-temp-dir* (merge-pathnames "configuration-r-test-temp/" (uiop:temporary-directory)))

(defun create-test-config-files ()
  "Creates a temporary directory with mock configuration files for testing."
  (uiop:ensure-directory-pathname *test-temp-dir*)
  (uiop:ensure-all-directories-exist *test-temp-dir*)

  ;; File 1: In the root test directory
  (with-open-file (f (merge-pathnames "config.lisp" *test-temp-dir*)
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format f "((:test-prop-1 . \"value-from-root\") (:another-prop . 123))~%"))

  ;; File 2: In a subdirectory
  (let* ((subdir (merge-pathnames "subdir/" *test-temp-dir*)))
    (uiop:ensure-directory-pathname subdir)
    (uiop:ensure-all-directories-exist subdir)
    (with-open-file (f (merge-pathnames "config.lisp" subdir)
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
      (format f "((:test-prop-2 . \"value-from-subdir\") (:another-prop . 456))~%"))))

(defun cleanup-test-config-files ()
  "Removes the temporary directory and mock configuration files."
  (when (uiop:directory-exists-p *test-temp-dir*)
    (uiop:delete-directory-tree *test-temp-dir* :validate t :if-does-not-exist :ignore)))

;; Define the test suite
(fiveam:def-suite :configuration-r-tests)
(fiveam:in-suite :configuration-r-tests)

;; Define a fixture for setup and teardown using unwind-protect
(fiveam:def-fixture config-file-fixture ()
  ;; Setup part: runs before tests using this fixture
  (create-test-config-files)
  ;; Use unwind-protect to ensure cleanup runs
  (unwind-protect
       (progn
         ;; This is the body where the tests run
         (format t "~&Running tests with config-file-fixture...~%")
         (fiveam:yield))
    ;; Teardown part: runs after tests using this fixture, even if errors occur
    (format t "~&Cleaning up config-file-fixture...~%")
    (cleanup-test-config-files)))

;; --- Individual Test Cases ---

;; Wrap all tests that need the config files with the fixture
(fiveam:with-fixture config-file-fixture ()
  ;; Test find-file-in-parent
  (fiveam:test find-file-in-parent-tests
    ;; Test finding in the immediate directory
    (fiveam:is-true (probe-file (configuration-r:find-file-in-parent *test-temp-dir* "config.lisp")))
    (fiveam:is (equal (namestring (merge-pathnames "config.lisp" *test-temp-dir*))
                      (namestring (configuration-r:find-file-in-parent *test-temp-dir* "config.lisp"))))

    ;; Test finding in a parent directory
    (let* ((subdir (merge-pathnames "subdir/" *test-temp-dir*))
           (expected-path (merge-pathnames "config.lisp" *test-temp-dir*)))
      (fiveam:is-true (probe-file (configuration-r:find-file-in-parent subdir "config.lisp")))
      (fiveam:is (equal (namestring expected-path)
                        (namestring (configuration-r:find-file-in-parent subdir "config.lisp")))))

    ;; Test not finding a non-existent file
    (fiveam:is-false (configuration-r:find-file-in-parent *test-temp-dir* "non-existent.lisp")))

  ;; Test get-config0 (internal helper, but good to test)
  (fiveam:test get-config0-tests
    ;; Test finding property in the immediate directory
    (multiple-value-bind (value file)
        (configuration-r::get-config0 (pathname-directory (namestring (merge-pathnames "config.lisp" *test-temp-dir*)))
                                       "config" "lisp" :test-prop-1 :debug t)
      (fiveam:is (equal "value-from-root" value))
      (fiveam:is (equal (namestring (merge-pathnames "config.lisp" *test-temp-dir*)) (namestring file))))

    ;; Test finding property in a parent directory
    (multiple-value-bind (value file)
        (configuration-r::get-config0 (pathname-directory (namestring (merge-pathnames "config.lisp" (merge-pathnames "subdir/" *test-temp-dir*))))
                                       "config" "lisp" :test-prop-1 :debug t)
      (fiveam:is (equal "value-from-root" value))
      (fiveam:is (equal (namestring (merge-pathnames "config.lisp" *test-temp-dir*)) (namestring file))))

    ;; Test property not found in any file
    (multiple-value-bind (value file)
        (configuration-r::get-config0 (pathname-directory (namestring (merge-pathnames "config.lisp" *test-temp-dir*)))
                                       "config" "lisp" :non-existent-prop :debug t)
      (fiveam:is-false value)
      (fiveam:is-false file)))

  ;; Test get-config
  (fiveam:test get-config-tests
    ;; Test finding property in the immediate directory
    (multiple-value-bind (value file)
        (configuration-r:get-config (merge-pathnames "config.lisp" *test-temp-dir*) :test-prop-1 :debug t)
      (fiveam:is (equal "value-from-root" value))
      (fiveam:is (equal (namestring (merge-pathnames "config.lisp" *test-temp-dir*)) (namestring file))))

    ;; Test finding property in a subdirectory, expecting it to find in parent
    (multiple-value-bind (value file)
        (configuration-r:get-config (merge-pathnames "config.lisp" (merge-pathnames "subdir/" *test-temp-dir*)) :test-prop-1 :debug t)
      (fiveam:is (equal "value-from-root" value))
      (fiveam:is (equal (namestring (merge-pathnames "config.lisp" *test-temp-dir*)) (namestring file))))

    ;; Test finding a property specific to the subdirectory's config (if it existed, currently it finds parent)
    ;; This test assumes get-config will find the closest config.lisp first.
    (multiple-value-bind (value file)
        (configuration-r:get-config (merge-pathnames "config.lisp" (merge-pathnames "subdir/" *test-temp-dir*)) :test-prop-2 :debug t)
      (fiveam:is (equal "value-from-subdir" value))
      (fiveam:is (equal (namestring (merge-pathnames "config.lisp" (merge-pathnames "subdir/" *test-temp-dir*))) (namestring file))))

    ;; Test property not found
    (multiple-value-bind (value file)
        (configuration-r:get-config (merge-pathnames "config.lisp" *test-temp-dir*) :non-existent-prop :debug t)
      (fiveam:is-false value)
      (fiveam:is-false file))

    ;; Test error handling (e.g., malformed config file, though current code doesn't explicitly test this)
    ;; For now, we'll just test a non-existent file path
    (multiple-value-bind (value file)
        (configuration-r:get-config (merge-pathnames "non-existent-dir/config.lisp" *test-temp-dir*) :some-prop :debug t)
      (fiveam:is-false value)
      (fiveam:is-false file)))

  ;; Test get-config1 (highlighting its problematic nature)
  (fiveam:test get-config1-problem-test
    ;; This test is designed to show that get-config1 might not work as expected
    ;; due to the pathname construction issues noted in the original code.
    ;; We expect it to either return NIL or potentially signal an error,
    ;; depending on the Lisp implementation and specific pathname.
    ;; A more robust test would involve specific error conditions or a clear
    ;; expectation of failure. For now, we'll just assert it doesn't return
    ;; the expected value from the root config, as its path construction is flawed.
    (let ((result (configuration-r:get-config1 (merge-pathnames "config.lisp" *test-temp-dir*) :test-prop-1 :debug t)))
      ;; Given the TODO, we expect this to likely fail to find the property
      ;; or produce an unexpected result.
      (fiveam:is-false (equal "value-from-root" result))
      ;; You might add a more specific assertion here if you can predict the failure mode,
      ;; e.g., (fiveam:signals error (configuration-r:get-config1 ...))
      ;; if it consistently errors out.
      )))
