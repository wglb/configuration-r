;;;; tests/main.lisp

(in-package #:configuration-r-test) ;; Change to the test package

;; Define the test suite
(fiveam:def-suite :configuration-r-tests)
(fiveam:in-suite :configuration-r-tests)

;; --- Individual Test Cases ---

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
    ))
