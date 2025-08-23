;;;; main-config-r-test.lisp

(in-package #:configuration-r-test)

(def-suite configuration-r-tests
  :description "Tests for the configuration-r library.")
(in-suite configuration-r-tests)

(defparameter *test-temp-dir* (merge-pathnames "configuration-r-test-temp/" (uiop:temporary-directory)))
(defparameter *subdir* (merge-pathnames "subdir/" *test-temp-dir*))
(defparameter *subsubdir* (merge-pathnames "subdir/subsubdir/" *test-temp-dir*))
(defparameter *test-file-1* (merge-pathnames "config.lisp" *test-temp-dir*))
(defparameter *test-file-2* (merge-pathnames "config.lisp" *subdir*))
(defparameter *test-file-3* (merge-pathnames "config.lisp" *subsubdir*))

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
    (format f "((:test-prop-3 . \"value-from-subsubdir\"))~%")))

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
  (is (equal (get-config "config.lisp" :test-prop-2 :dir *subdir*)
             "value-from-subdir")
      "Test case 1 get-config: Should find the property in the subdir file.")
  ;; Test case 2
  (is (equal (get-config "config.lisp" :common-prop :dir *subdir*)
             "common-subdir")
      "Test case 2 get-config: Should find the common-prop by searching up the directory tree.")
  ;; Test case 3
  (is-true (null (get-config "nonexistent-file.lisp" :some-prop :dir *subdir*))
           "Test case 3 get-config: Should return nil when the file does not exist.")
  ;; Test case 4
  (is-true (null (get-config "config.lisp" :test-prop-1 :dir "/tmp/non-existent-dir/"))
           "Test case 4 get-config: Should return nil and not error when the directory does not exist.")
  ;; Test case 5
  (signals error
    (get-config (uiop:parse-native-namestring "/tmp/config.lisp") :test-prop-1)
    "Test case 5 get-config: GET-CONFIG should signal an error when the filename contains a path."))

(test get-config1-tests
  "Tests for the GET-CONFIG1 function."
  ;; Test case 6
  (is (equal (get-config1 (merge-pathnames "config.lisp" *subdir*) :test-prop-2)
             "value-from-subdir")
      "Test case 6 get-config1: Should find the property in the specified file.")
  ;; Test case 7: Corrected expected value
  (is (equal (get-config1 (merge-pathnames "config.lisp" *subsubdir*) :common-prop)
             "common-subdir")
      "Test case 7 get-config1: Should find the common-prop by searching up the directory tree.")
  ;; Test case 8
  (is-true (null (get-config1 (merge-pathnames "nonexistent-file.lisp" *subdir*) :some-prop))
           "Test case 8 get-config1: Should return nil when the file does not exist.")
  ;; Test case 9
  (is-true (null (get-config1 (uiop:parse-native-namestring "/tmp/non-existent-dir/non-existent-file.lisp") :some-prop))
           "Test case 9 get-config1: Should return nil and not error when the directory does not exist."));;;; main-config-r-test.lisp

(in-package #:configuration-r-test)
