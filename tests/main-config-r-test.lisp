;;;; main-config-r-test.lisp

(in-package #:configuration-r-test)

(def-suite configuration-r-tests
  :description "Tests for the configuration-r library.")
(in-suite configuration-r-tests)

(defparameter *test-temp-dir* (merge-pathnames "configuration-r-test-temp/" (uiop:temporary-directory)))
(defparameter *subdir* (merge-pathnames "subdir/" *test-temp-dir*))
(defparameter *subsubdir* (merge-pathnames "subdir/subsubdir/" *test-temp-dir*))
(defparameter *test-file-1* (merge-pathnames "config.lsp" *test-temp-dir*))
(defparameter *test-file-2* (merge-pathnames "config.lsp" *subdir*))
(defparameter *test-file-3* (merge-pathnames "config.lsp" *subsubdir*))
(defparameter *test-file-4* (merge-pathnames "empty.lsp" *test-temp-dir*))
(defparameter *test-file-5* (merge-pathnames "invalid.lsp" *test-temp-dir*))
(defparameter *test-file-6* (merge-pathnames "config-with-nil.lsp" *test-temp-dir*))
(defparameter *test-file-7* (merge-pathnames "junk.txt" *test-temp-dir*))
(defparameter *test-file-8* (merge-pathnames "junk.bin" *test-temp-dir*))

(defun create-test-config-files ()
  "Creates a temporary directory with mock configuration files for testing."
  (uiop:ensure-all-directories-exist (list *subsubdir*))
  
  (with-open-file (f *test-file-1* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f "((:test-prop-1 . \"value-from-root\")
                (:common-prop . \"common-root\"))~%"))

  (with-open-file (f *test-file-2* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f "((:test-prop-2 . \"value-from-subdir\")
                (:common-prop . \"common-subdir\"))~%"))
                
  (with-open-file (f *test-file-3* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f "((:test-prop-3 . \"value-from-subsubdir\"))~%"))
    
  (with-open-file (f *test-file-4* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f ""))

  (with-open-file (f *test-file-5* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f "((:invalid-prop . \"a-value\") )~%"))

  (with-open-file (f *test-file-6* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f "((:nil-prop . nil)
                (:some-other-prop . \"a-value\"))~%"))

  (with-open-file (f *test-file-7* :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format f "This is a plain text file."))

  (with-open-file (f *test-file-8* :direction :output :if-exists :supersede :if-does-not-exist :create
                     :element-type '(unsigned-byte 8))
    (write-byte 255 f)))

(defun cleanup-test-config-files ()
  "Removes the temporary directory and all its contents."
  (when (uiop:directory-exists-p *test-temp-dir*)
    (uiop:delete-directory-tree *test-temp-dir* :validate t)))

(defun run-tests-with-cleanup ()
  (unwind-protect
       (progn
         (create-test-config-files)
         (fiveam:run! :configuration-r-tests))
    (cleanup-test-config-files)))

(test get-config-tests
  "Tests for the GET-CONFIG function."
  ;; Test case 1
  (is (equal (get-config "config.lsp" :test-prop-2 :dir *subdir*)
             "value-from-subdir")
      "Test case 1 get-config: Should find the property in the subdir file.")
  ;; Test case 2
  (is (equal (get-config "config.lsp" :common-prop :dir *subdir*)
             "common-subdir")
      "Test case 2 get-config: Should find the common-prop by searching up the directory tree.")
  ;; Test case 3
  (is-true (null (get-config "nonexistent-file.lsp" :some-prop :dir *subdir*))
           "Test case 3 get-config: Should return nil when the file does not exist.")
  ;; Test case 4
  (is-true (null (get-config "config.lsp" :test-prop-1 :dir "/tmp/non-existent-dir/"))
           "Test case 4 get-config: Should return nil and not error when the directory does not exist.")
  ;; Test case 5: Enforce that GET-CONFIG signals an error when FILENAME has a directory component.
  (signals error
    (get-config (uiop:parse-native-namestring "/tmp/config.lsp") :test-prop-1)
    "Test case 5 get-config: GET-CONFIG should signal an error when the filename contains a path.")
  ;; Test case 6: Test with an empty file.
  (is-true (null (get-config "empty.lsp" :some-prop :dir *test-temp-dir*))
           "Test case 6 get-config: Should return nil for an empty file.")
  ;; Test case 7: Test with an invalid Lisp file.
  (is-true (null (get-config "invalid.lsp" :some-prop :dir *test-temp-dir*))
           "Test case 7 get-config: Should return nil for an invalid lisp file.")
  ;; Test case 8: Test finding a property with a nil value.
  (is-true (null (get-config "config-with-nil.lsp" :nil-prop :dir *test-temp-dir*))
           "Test case 8 get-config: Should return nil for a property with nil value.")
  ;; Test case 9: Test that get-config still finds a different property in the same file.
  (is (equal (get-config "config-with-nil.lsp" :some-other-prop :dir *test-temp-dir*)
             "a-value")
      "Test case 9 get-config: Should find other properties in the same file.")
  ;; Test case 10: Test with a plain text file.
  (is-true (null (get-config "junk.txt" :some-prop :dir *test-temp-dir*))
           "Test case 10 get-config: Should return nil for a text file.")
  ;; Test case 11: Test with a binary file.
  (is-true (null (get-config "junk.bin" :some-prop :dir *test-temp-dir*))
           "Test case 11 get-config: Should return nil for a binary file."))

(test get-config1-tests
  "Tests for the GET-CONFIG1 function."
  ;; Test case 12
  (is (equal (get-config1 (merge-pathnames "config.lsp" *subdir*) :test-prop-2)
             "value-from-subdir")
      "Test case 12 get-config1: Should find the property in the specified file.")
  ;; Test case 13
  (is (equal (get-config1 (merge-pathnames "config.lsp" *subsubdir*) :common-prop)
             "common-subdir")
      "Test case 13 get-config1: Should find the common-prop by searching up the directory tree.")
  ;; Test case 14
  (is-true (null (get-config1 (merge-pathnames "nonexistent-file.lsp" *subdir*) :some-prop))
           "Test case 14 get-config1: Should return nil when the file does not exist.")
  ;; Test case 15
  (is-true (null (get-config1 (uiop:parse-native-namestring "/tmp/non-existent-dir/non-existent-file.lsp") :some-prop))
           "Test case 15 get-config1: Should return nil and not error when the directory does not exist.")
  ;; Test case 16: Test with an empty file.
  (is-true (null (get-config1 *test-file-4* :some-prop))
           "Test case 16 get-config1: Should return nil for an empty file.")
  ;; Test case 17: Test with an invalid Lisp file.
  (is-true (null (get-config1 *test-file-5* :some-prop))
           "Test case 17 get-config1: Should return nil for an invalid lisp file.")
  ;; Test case 18: Test finding a property with a nil value.
  (is-true (null (get-config1 *test-file-6* :nil-prop))
           "Test case 18 get-config1: Should return nil for a property with a nil value.")
  ;; Test case 19: Test that get-config1 still finds a different property in the same file.
  (is (equal (get-config1 *test-file-6* :some-other-prop)
             "a-value")
      "Test case 19 get-config1: Should find other properties in the same file.")
  ;; Test case 20: Test with a plain text file.
  (is-true (null (get-config1 *test-file-7* :some-prop))
           "Test case 20 get-config1: Should return nil for a text file.")
  ;; Test case 21: Test with a binary file.
  (is-true (null (get-config1 *test-file-8* :some-prop))
           "Test case 21 get-config1: Should return nil for a binary file."))

