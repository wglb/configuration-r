;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)))

(in-package #:configuration-r)

(defun get-config (filename property &key (dir nil) (debug nil))
  "This function gets a config property from a specific file named FILENAME.
   It searches up from the directory DIR (or current directory if DIR is nil).
   The FILENAME argument must not contain any directory components."
  (if (pathname-directory filename)
      (error "Filename argument to GET-CONFIG must not contain directory components: ~a" filename))
  (handler-case
      (let* ((initial-dir (if dir
                              (ensure-directory-pathname dir)
                              (getcwd)))
             (canonical-dir (truename initial-dir))
             (fn (pathname-name filename))
             (ty (pathname-type filename))
             (target-file (make-pathname :name fn :type ty)))
        (loop for pn = canonical-dir then (pathname-parent-directory-pathname pn)
              while pn
              do (let ((tpn (merge-pathnames target-file pn)))
                   (when (probe-file tpn)
                     (when debug (xlogntf "gc: Found file ~a, reading it." tpn))
                     (let ((alist (read-config-file tpn :debug debug)))
                       (when alist
                         (let ((ans (cdr (assoc property alist))))
                           (if ans
                               (progn
                                 (if debug (xlogntf "gc: Found property ~s, returning." ans))
                                 (return-from get-config (values ans tpn)))
                               (when debug (xlogntf "gc: File ~s found, but property ~s not found. Continuing search."
                                                    tpn property))))))))
              finally (when debug (xlogntf "gc: No file with property ~s found." property)))
        nil)
    (file-error ()
      (when debug (xlogntf "gc: The directory ~s does not exist, exiting gracefully." dir))
      nil)))

(defun get-config1 (filename property &key (debug nil))
  "This function gets a property from a specific file path.
   It searches up from the directory of the given FILENAME."
  (handler-case
      (let* ((absolute-file-pathname (truename (ensure-pathname filename :want-pathname t)))
             (current-dir (pathname-directory-pathname absolute-file-pathname))
             (target-file (make-pathname :name (pathname-name absolute-file-pathname)
                                         :type (pathname-type absolute-file-pathname))))
        (loop for pn = current-dir then (pathname-parent-directory-pathname pn)
              while pn
              do (let ((tpn (merge-pathnames target-file pn)))
                   (when (probe-file tpn)
                     (when debug (xlogntf "gc1: Found file ~a, reading it." tpn))
                     (let ((alist (read-config-file tpn :debug debug)))
                       (when alist
                         (let ((ans (cdr (assoc property alist))))
                           (if ans
                               (progn
                                 (if debug (xlogntf "gc1: Found property ~s, returning." ans))
                                 (return-from get-config1 (values ans tpn)))
                               (when debug (xlogntf "gc1: File ~s found, but property ~s not found. Continuing search."
                                                    tpn property))))))))
              finally (when debug (xlogntf "gc1: No file with property ~s found." property)))
        nil)
    (file-error ()
      (when debug (xlogntf "gc1: Could not find or access ~s, exiting gracefully." filename))
      nil)))

