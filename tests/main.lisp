;;;; main.lisp

(in-package #:configuration-r-test)

(def-suite configuration-r-tests)

(in-suite configuration-r-tests)

(test find-file-in-parent-works
  (let ((pn (merge-pathnames "subdir/" *test-temp-dir*)))
    (is (uiop:pathname-equal
         (find-file-in-parent pn "config.lisp")
         (merge-pathnames "config.lisp" *test-temp-dir*)))))

(test get-config-with-found-property
  (let ((pn (merge-pathnames "subdir/" *test-temp-dir*)))
    (is (string= "value-from-subdir"
                 (get-config "config.lisp" :test-prop-2 :dir pn)))))

(test get-config-without-found-property
  (let ((pn (merge-pathnames "subdir/" *test-temp-dir*)))
    (is (string= "value-from-root"
                 (get-config "config.lisp" :test-prop-1 :dir pn)))))

(test get-config1-with-found-property
  (let ((pn (merge-pathnames "subdir/config.lisp" *test-temp-dir*)))
    (is (string= "value-from-subdir"
                 (get-config1 pn :test-prop-2)))))

(test get-config1-without-found-property
  (let ((pn (merge-pathnames "subdir/config.lisp" *test-temp-dir*)))
    (is (string= "value-from-root"
                 (get-config1 pn :test-prop-1)))))

(test recursion-stops-in-circular-directory
  "Tests that get-config terminates correctly when a circular path is
  encountered, preventing a stack overflow."
  (with-test-directory-loop ("looped-subdir/")
    (let* ((deep-path (merge-pathnames "looped-subdir/subdir/" *test-temp-dir*))
           (result (get-config "config.lisp" :test-prop-3 :dir deep-path :debug t)))
      ;; The recursive search should enter the loop and be terminated by the
      ;; visited-dirs check, returning NIL as no file will be found.
      (is-false result)

      ;; Let's try another path that would normally succeed if the loop wasn't there.
      ;; The visited-dirs check should prevent the search from ever getting out
      ;; of the loop, so the property will not be found.
      (let* ((other-result (get-config "config.lisp" :test-prop-1 :dir deep-path :debug t)))
        (is-false other-result)))))

(test recursion-with-file-stops-in-circular-directory
  "Tests that get-config terminates when a file is found but the property is not,
  and the search enters a circular path."
  (with-test-directory-loop ("looped-subdir/")
    ;; Create a mock config file specifically for this test inside the loop
    (let* ((loop-dir (merge-pathnames "looped-subdir/" *test-temp-dir*))
           (file-in-loop (merge-pathnames "test-config-for-loop.lisp" loop-dir)))
      (with-open-file (f file-in-loop
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
        (format f "((:loop-test-prop . 100))"))
      
      (let ((result (get-config "test-config-for-loop.lisp" :non-existent-prop :dir loop-dir :debug t)))
        ;; The function should find the file, fail to find the property, and then recurse
        ;; to the parent. The parent is the loop, so the visited-dirs check should
        ;; terminate the recursion. The result should be NIL.
        (is-false result))))))

(test get-config-with-relative-dir-does-not-loop
  "Tests that get-config correctly handles a relative directory name and does not
  enter an infinite loop."
  (let* ((relative-dir (make-pathname :directory '(:relative "test-dir-relative")))
         (temp-relative-dir (merge-pathnames relative-dir *test-temp-dir*)))
    ;; Create a temporary directory that is relative to the test root
    (uiop:ensure-all-directories-exist (list temp-relative-dir))
    (unwind-protect
        (progn
          ;; We call get-config from the relative directory. The function should
          ;; resolve it to an absolute path, find the file at the test root,
          ;; and return the value. It should not get into a loop.
          (is (string= "value-from-root"
                       (get-config "config.lisp" :test-prop-1 :dir relative-dir :debug t))))
      (uiop:delete-directory-tree temp-relative-dir :validate t))))
