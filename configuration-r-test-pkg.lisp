;;;; configuration-r-test-pkg.lisp

(defpackage #:configuration-r-test
  (:use #:cl #:fiveam #:configuration-r #:uiop) ;; Use FiveAM, your library, and UIOP here
  (:export #:create-test-config-files
           #:cleanup-test-config-files))

;; Diagnostic print statement after defpackage
(format t "~&[DIAG] Package #:CONFIGURATION-R-TEST defined. Current package: ~s~%" *package*)

;; Make sure these definitions are AFTER the defpackage form
(in-package #:configuration-r-test)

;; Diagnostic print statement after in-package
(format t "~&[DIAG] Switched to package #:CONFIGURATION-R-TEST. Current package: ~s~%" *package*)


;; Mock configuration files for testing
;; We'll create these dynamically in a temporary directory for tests
(defparameter *test-temp-dir* (merge-pathnames "configuration-r-test-temp/" (uiop:temporary-directory)))
(format t "~&[DIAG] *TEST-TEMP-DIR* defined: ~s~%" *test-temp-dir*)


(defun create-test-config-files ()
  "Creates a temporary directory with mock configuration files for testing."
  (format t "~&Setting up test environment (CREATE-TEST-CONFIG-FILES called)...~%")
  (uiop:ensure-directory-pathname *test-temp-dir*)
  (uiop:ensure-all-directories-exist (list *test-temp-dir*))

  ;; File 1: In the root test directory
  (with-open-file (f (merge-pathnames "config.lisp" *test-temp-dir*)
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format f "((:test-prop-1 . \"value-from-root\") (:another-prop . 123))~%"))

  ;; File 2: In a subdirectory
  (let* ((subdir (merge-pathnames "subdir/" *test-temp-dir*)))
    (uiop:ensure-directory-pathname subdir)
    (uiop:ensure-all-directories-exist (list subdir))
    (with-open-file (f (merge-pathnames "config.lisp" subdir)
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
      (format f "((:test-prop-2 . \"value-from-subdir\") (:another-prop . 456))~%"))))

(defun cleanup-test-config-files ()
  "Removes the temporary directory and mock configuration files."
  (format t "~&Cleaning up test environment (CLEANUP-TEST-CONFIG-FILES called)...~%")
  (when (uiop:directory-exists-p *test-temp-dir*)
    (uiop:delete-directory-tree *test-temp-dir* :validate t :if-does-not-exist :ignore)))

;; Diagnostic print statement after function definitions
(format t "~&[DIAG] Functions CREATE-TEST-CONFIG-FILES and CLEANUP-TEST-CONFIG-FILES defined in ~s~%" *package*)
