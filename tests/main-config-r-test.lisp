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

;; Main function to be called by ASDF's test-op
(defun run-tests-with-cleanup ()
  (unwind-protect
       (progn
         (create-test-config-files)
         (fiveam:run! :configuration-r-tests))
    (cleanup-test-config-files)))


(test get-config-tests
  "Tests for the GET-CONFIG function."
  (is (equal (get-config "config.lisp" :test-prop-2 :dir *subdir*)
             "value-from-subdir")
      "Should find the property in the subdir file.")
  (is (equal (get-config "config.lisp" :common-prop :dir *subdir*)
             "common-root")
      "Should find the common-prop by searching up the directory tree.")
  (is-true (null (get-config "nonexistent-file.lisp" :some-prop :dir *subdir*))
           "Should return nil when the file does not exist.")
  (is-true (null (get-config "config.lisp" :test-prop-1 :dir "/tmp/non-existent-dir/"))
           "Should return nil and not error when the directory does not exist.")
  (signals error
    (get-config (uiop:parse-native-namestring "/tmp/config.lisp") :test-prop-1)
    "GET-CONFIG should signal an error when the filename contains a path."))

(test get-config1-tests
  "Tests for the GET-CONFIG1 function."
  (is (equal (get-config1 (merge-pathnames "config.lisp" *subdir*) :test-prop-2)
             "value-from-subdir")
      "Should find the property in the specified file.")
  (is (equal (get-config1 (merge-pathnames "config.lisp" *subsubdir*) :common-prop)
             "common-root")
      "Should find the common-prop by searching up the directory tree.")
  (is-true (null (get-config1 (merge-pathnames "nonexistent-file.lisp" *subdir*) :some-prop))
           "Should return nil when the file does not exist.")
  (is-true (null (get-config1 (uiop:parse-native-namestring "/tmp/non-existent-dir/non-existent-file.lisp") :some-prop))
           "Should return nil and not error when the directory does not exist."))


(run-tests-with-cleanup)
