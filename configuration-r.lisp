;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)) )

(in-package #:configuration-r)

(defun find-file-in-parent0 (pn target)
  (if pn
      (let ((tpn (merge-pathnames target pn)))
        (debugc 5 (xlogntf "ffip: target ~s pn ~s" target pn))
        (if (probe-file tpn)
            tpn
            (let ((npn (truename (uiop:pathname-parent-directory-pathname pn))))
              (if (equal npn pn)
                  nil
                  (find-file-in-parent0 npn target)))))))

(defun find-file-in-parent (pn target)
  "Account for being in an emacs volume that won't cd .. to root of file system"
  (let ((ans (find-file-in-parent0 pn target)))
	(debugc 5 (xlogntf "probe says ~a" ans))
	(unless ans
	  (xlogntf "gotta null")
	  ;; Use user-homedir-pathname for robustness when falling back to home directory
	  (setf ans (find-file-in-parent0 (user-homedir-pathname) target))
	  (debugc 5 (xlogntf "Now got ans ~a" ans)))
	ans))

(defparameter *config* -1)

(defun get-config0 (current-dir-pathname fn ty property &key (debug nil) )
  "Recursively looks for a config file named FN.TY with PROPERTY in CURRENT-DIR-PATHNAME
   and its parent directories. CURRENT-DIR-PATHNAME must be a pathname object."
  (if debug (xlogntf "gc0: current-dir-pathname ~s fn ~s ty ~s prop ~s" current-dir-pathname fn ty property))

  (when current-dir-pathname
    (let* ((config-file-pathname (make-pathname :directory (pathname-directory current-dir-pathname)
                                                :name fn
                                                :type ty))
           (*print-pretty* nil) ; Keep this if it's explicitly for 'read' behavior, but be aware of scope
           (found-file (probe-file config-file-pathname)))

      (if debug (xlogntf "gc0: config-file-pathname ~s found-file ~s" config-file-pathname found-file))

      (cond
        (found-file
         (with-open-file (fi found-file :direction :input)
           (let* ((result (read fi))
                  (ans (assoc property result)))
             (if debug (xlogntf "gc0: config file content ~s ~%    assoc result ~s ~%    found-file ~s" result ans found-file))
             (cond
               ((not ans)
                (if debug (xlogntf "gc0: property ~s not found in ~s" property found-file))
                ;; Recurse to parent directory
                (get-config0 (uiop:pathname-parent-directory-pathname current-dir-pathname) fn ty property))
               (t
                (let ((res (cdr ans)))
                  (if debug (xlogntf "gc0: prop ans ~s val ~s from file ~s" property res found-file))
                  (values res found-file)))))))
        (t
         (if debug (xlogntf "gc0: no file ~s in ~s" config-file-pathname current-dir-pathname))
         ;; Recurse to parent directory
         (let ((parent-dir (uiop:pathname-parent-directory-pathname current-dir-pathname)))
           ;; Stop recursion if parent is same as current (e.g., at the root of the filesystem)
           (if (equal parent-dir current-dir-pathname)
               nil
               (multiple-value-bind (r f)
                   (get-config0 parent-dir fn ty property)
                 (if debug (xlogntf "gc0: going to parent: parent-dir is ~s" parent-dir))
                 (if debug (xlogntf "gc0: prop ~s is ~s in file ~s" property r f))
                 (values r f)))))))))

(defun get-config (filename property &key (dir nil) (debug nil))
  "get-config answers the property found in the file named 'fn'.
   filename must be a pathname from 'make-pathname or 'merge-pathnames.
   If fn is not in the specified directory, or if the property is not found in that file, get-config will look in the parent.
    Recursively.
    Returns values of (result filename)"
  (let* ((initial-pathname (cond
                             (dir (uiop:ensure-directory-pathname dir))
                             (t *default-pathname-defaults*)))
         (fn (pathname-name filename))
         (ty (pathname-type filename)))
    (if debug
        (xlogntf "gc: filename ~s prop ~s dir ~s~%    initial-pathname ~s" filename property dir initial-pathname))
    (handler-case
        (get-config0 initial-pathname fn ty property :debug debug)
      (error (e)
        (xlogntf "get-config: error ~e in getting ~a from ~a" e property filename)
        nil))))

(defun get-config1 (filename property &key (debug nil))
  "This function is noted as problematic in the original code.
   It attempts to get a config property from a specific file path.
   Its pathname handling is simplified here, but its original intent
   and potential issues remain."
  (let* ((file-pathname (uiop:ensure-pathname filename :want-pathname t))
         (dir-pathname (uiop:pathname-directory-pathname file-pathname))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname))
         (ans (get-config0 dir-pathname fn ty property :debug debug)))
    (if debug
        (xlogntf "gc1: filename ~s fn ~s property ~s val ~s" filename fn property ans))
    ans))
