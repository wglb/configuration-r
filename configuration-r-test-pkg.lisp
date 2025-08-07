;;;; configuration-r-test-pkg.lisp

(defpackage #:configuration-r-test
  (:use #:cl #:fiveam #:configuration-r #:uiop) ;; Use FiveAM, your library, and UIOP here
  (:export #:create-test-config-files
           #:cleanup-test-config-files
           #:with-test-directory-loop))

;; Make sure these definitions are AFTER the defpackage form
(in-package #:configuration-r-test)

;; Mock configuration files for testing
;; We'll create these dynamically in a temporary directory for tests
(defparameter *test-temp-dir* (merge-pathnames "configuration-r-test-temp/" (uiop:temporary-directory)))

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
    (format f "((:test-prop-1 . \"value-from-root\"))~%"))

  ;; File 2: In a subdirectory
  (let* ((subdir (merge-pathnames "subdir/" *test-temp-dir*)))
    (uiop:ensure-directory-pathname subdir)
    (uiop:ensure-all-directories-exist (list subdir))
    (with-open-file (f (merge-pathnames "config.lisp" subdir)
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
      (format f "((:test-prop-2 . \"value-from-subdir\"))~%"))))

(defun cleanup-test-config-files ()
  "Removes the temporary directory and mock configuration files."
  (format t "~&Cleaning up test environment (CLEANUP-TEST-CONFIG-FILES called)...~%")
  (when (uiop:directory-exists-p *test-temp-dir*)
    (uiop:delete-directory-tree *test-temp-dir* :validate t)))

(defmacro with-test-directory-loop ((loop-dir-name) &body body)
  "Creates a symbolic link that creates a loop, runs body, then cleans up."
  (let ((loop-path (gensym))
        (target-path (gensym)))
    `(let* ((,target-path (merge-pathnames "../" (uiop:ensure-directory-pathname ,*test-temp-dir*)))
            (,loop-path (merge-pathnames ,loop-dir-name (uiop:ensure-directory-pathname ,*test-temp-dir*))))
       (unwind-protect
            (progn
              ;; Check if the target exists before trying to create a link
              (unless (uiop:directory-exists-p ,target-path)
                (error "Loop target directory does not exist: ~a" ,target-path))
              (format t "~&Creating symlink from ~a to ~a...~%" (namestring ,loop-path) (namestring ,target-path))
              ;; Use uiop:run-program to create the symbolic link. `ln -s` is a standard Unix command.
              (uiop:run-program (list "ln" "-s" (namestring ,target-path) (namestring ,loop-path))
                                :output :interactive :error-output :interactive)
              ,@body)
         (when (probe-file ,loop-path)
           (format t "~&Removing symlink at ~a...~%" (namestring ,loop-path))
           ;; Use uiop:run-program to remove the symbolic link. `rm` is a standard Unix command.
           (uiop:run-program (list "rm" (namestring ,loop-path)) :output :interactive :error-output :interactive))))))
